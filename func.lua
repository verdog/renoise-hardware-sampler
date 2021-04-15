require"util"
require"midi"

-- global options box
OPTIONS = {
  low = 1,
  high = 6,
  length = 2,
  release = .2,
  tags = {[0]=false, false, false, false, false, false, false, false},
  notes = {[0]=true, false, false, false, true, false, false, true, false, false, false, false},
  name = "Recorded Hardware",
  hardware_name = "",
  background = false,
  post_record_normalize_and_trim = false,
  mapping = 2,
  layers = 1
}

TAGS = {[0]="Bass", "Drum", "FX", "Keys", "Lead", "Pad", "Strings",  "Vocal"}
NOTES = {[0]="C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

-- note/tag button colors
C_PRESSED = {100, 200, 100}
C_NOT_PRESSED = {20, 20, 20}

-- state
STATE = {
  midi_device = nil,    -- current midi device name
  dev = nil,            -- current midi device object
  recording = false,    -- are we actively recording
  notes = nil,          -- list of notes to send to the midi device
  notei = nil,          -- current index in note list
  layers = nil,         -- number of velocity layers for each note
  layeri = nil,         -- current layer
  total = nil           -- total amount of notes that will be sampled
}

-- reset state to be ready to record
function reset_state()
  STATE.notei = nil
  STATE.notes = nil
  STATE.dev = nil
  STATE.recording = false
  STATE.layers = nil
  STATE.layeri = nil
  STATE.total = nil
  
  TOCALL = nil -- from util.lua
  KILL = false -- from util.lua

  -- erase any timers
  if renoise.tool():has_timer(start_note) then
    renoise.tool():remove_timer(start_note)
  end

  if renoise.tool():has_timer(stop_note) then
    renoise.tool():remove_timer(stop_note)
  end
end

-- toggles the on/off state of a button
function toggle_button(button, ttype)
  print("toggling ", tostring(ttype), tostring(button))

  -- set data to 
  OPTIONS[ttype][button] = not OPTIONS[ttype][button]

  -- set visual
  vb.views[tostring(ttype).."_button_"..tostring(button)].color = 
    OPTIONS[ttype][button] and C_PRESSED or C_NOT_PRESSED
end

-- generate list of midi notes to send to the controller
function gen_notes()
  -- midi 0xc = c0
  -- renoise 0 = c0
  local ret = {}
  local step = 4
  for n=12*OPTIONS.low,12*(OPTIONS.high + 1)-1 do
    if OPTIONS.notes[n%12] then
      table.insert(ret, n)
    end
  end
  return ret
end

-- check for invalid options
function check()
  if OPTIONS.low > OPTIONS.high then
    renoise.app():show_prompt("Oops!", "Low octave must be <= high octave.", {"OK"})
    return false
  end
 
  local foundnote = false
  for i=0,11 do
    if OPTIONS.notes[i] == true then
      foundnote = true
      break
    end
  end
  if not foundnote then
    renoise.app():show_prompt("Oops!", "You must select at least one note.", {"OK"})
    return false
  end
 
  return true
end

-- start the recording process
function go()
  print("Starting...")
  reset_state()

  if not check() then
    stop()
    return false
  end

  STATE.notes = gen_notes()
  STATE.notei = 1
  STATE.dev = get_midi_dev()
  STATE.layers = OPTIONS.layers
  STATE.layeri = 1
  STATE.total = table.count(STATE.notes) * STATE.layers
  
  print("Going to create "..tostring(STATE.total).." samples.")

  -- get inst
  local inst = renoise.song().selected_instrument

  -- clear samples
  while table.count(inst.samples) > 0 do
    inst:delete_sample_at(1)
  end

  -- insert blank samples
  for i=1,STATE.total do
    inst:insert_sample_at(i)
  end

  -- start on first sample
  renoise.song().selected_sample_index = 1

  -- go!
  prep_note()
end

function get_mapping_dict()
  -- set up mappings
  local mapping_dict = {}
  
  for i=1,table.count(STATE.notes) do
    local low
    local high
    
    if OPTIONS.mapping == 1 then -- down
      if i == 1 then
        low = 0
      else
        low = STATE.notes[i-1] + 1
      end
      
      if i == table.count(STATE.notes) then
        high = 119
      else
        high = STATE.notes[i]
      end
    elseif OPTIONS.mapping == 2 then -- middle
      local function get_dists(note)
        local up = 1
        local down = 1
        
        -- up
        local i = (note + 1)%12
        while not OPTIONS.notes[i] do
          i = (i + 1)%12
          up = up + 1
        end
        
        -- down
        i = (note - 1)%12
        while not OPTIONS.notes[i] do
          i = (i - 1)%12
          down = down + 1
        end
        
        return {up = math.floor(up/2), down = math.floor((down-1)/2)}
      end
      
      local diffs = get_dists(STATE.notes[i])
      
      if i == 1 then
        diffs.down = STATE.notes[i]
      elseif i == table.count(STATE.notes) then
        diffs.up = 119 - STATE.notes[i]
      end
      
      low = STATE.notes[i] - diffs.down
      high = STATE.notes[i] + diffs.up
    elseif OPTIONS.mapping == 3 then -- up
      if i == 1 then
        low = 0
      else
        low = STATE.notes[i]
      end
      
      if i == table.count(STATE.notes) then
        high = 119
      else
        high = STATE.notes[i+1] - 1
      end
    end
    
    mapping_dict[STATE.notes[i]]={low, high}
  end
  
  return mapping_dict
end

function do_mapping(mapping_dict)
  local inst = renoise.song().selected_instrument
  
  for i=1,table.count(STATE.notes) do
    for l=1,STATE.layers do
      if mapping_dict[STATE.notes[i]] then
        local idx = (i-1)*STATE.layers + (l-1) + 1
        local mapping = inst.sample_mappings[1][idx]
        
        mapping.base_note = STATE.notes[i]
        mapping.note_range = mapping_dict[STATE.notes[i]]
        
        local lunit = 128/STATE.layers
        local lrange = {math.floor((l-1)*lunit), math.floor((l)*lunit - 1)}
        mapping.velocity_range = lrange
      end
    end
  end
end

-- apply finishing touches
function finish()
  update_status("Finishing...")
  local inst = renoise.song().selected_instrument

  local lunit = 128/STATE.layers

  -- name instrument
  update_instrument_name()

  -- name samples
  for i=1,table.count(STATE.notes) do
    for l=1,STATE.layers do
      local vel = math.floor((l)*lunit - 1)
      local idx = (i-1)*STATE.layers + (l-1) + 1
      inst.samples[idx].name = note_to_name(STATE.notes[i]).."_"..string.format("%X", vel)
    end
  end

  -- do mappings
  do_mapping(get_mapping_dict())

  -- close recording window
  renoise.app().window.sample_record_dialog_is_visible = false

  -- close midi
  STATE.dev:close()

  -- normalize samples if enabled
  if OPTIONS.post_record_normalize_and_trim then
    post_record_normalize_and_trim()
  end
end

-- normalize and trim the samples
function post_record_normalize_and_trim()
  -- ensure background processing is not enabled.
  -- if background processing is enabled a few bad things could happen:
  -- normalizing gets skipped or there's a race condition that goes un-noticed
  -- while the sound data is being treated. 
  local tmp_background = OPTIONS.background
  OPTIONS.background = false

  update_status("Normalizing samples...")
  normalize()

  update_status("Trimming samples...")
  trim()

  update_status("All samples normalized and trimmed.")

  -- put the background setting back to what it was
  OPTIONS.background = tmp_background
end

-- kill switch
function stop()
  KILL = true
  if STATE.recording then
    renoise.app().window.sample_record_dialog_is_visible = true
    renoise.song().transport:start_stop_sample_recording()
    STATE.recording = false
    STATE.dev:send({NOTE_OFF, STATE.notes[STATE.notei] + 0xC, 0x40}) -- release current note
    STATE.dev:send({ALL_NOTE_OFF_1 , ALL_NOTE_OFF_2, 0x00}) -- send all notes off
  end
  renoise.app().window.sample_record_dialog_is_visible = false
  if STATE.dev and STATE.dev.is_open then
    STATE.dev:close()
  end
  update_status("Stopped")
end

-- open the recording settings window
function configure()
  renoise.app().window.sample_record_dialog_is_visible = true
end

-- get ready to play a note
-- recording starts here
function prep_note()
  local idx = (STATE.notei-1)*STATE.layers + (STATE.layeri-1) + 1
  print("Prepping note "..tostring(idx).."...")
  renoise.song().selected_sample_index = idx
  renoise.app().window.sample_record_dialog_is_visible = true
  renoise.song().transport:start_stop_sample_recording()
  STATE.recording = true
  call_in(start_note, 50)
end

-- play the note
function start_note()
  print("Starting note...")
  STATE.dev:send({NOTE_OFF, STATE.notes[STATE.notei] + 0xC, 0x40}) -- just in case...
  
  local lunit = 128/STATE.layers
  local vel = math.floor((STATE.layeri)*lunit - 1)
  
  STATE.dev:send({NOTE_ON, STATE.notes[STATE.notei] + 0xC, vel})
  call_in(release_note, OPTIONS.length * 1000)
end

-- release the note
function release_note()
  print("Releasing note...")
  STATE.dev:send({NOTE_OFF, STATE.notes[STATE.notei] + 0xC, 0x40})
  call_in(stop_note, OPTIONS.release * 1000)
end

-- stop recording, prep next note
function stop_note()
  print("Stopping note...")
  renoise.app().window.sample_record_dialog_is_visible = true
  renoise.song().transport:start_stop_sample_recording()
  STATE.recording = false

  STATE.layeri = STATE.layeri + 1
  
  if STATE.layeri > STATE.layers then
    STATE.layeri = 1
    STATE.notei = STATE.notei + 1
  end

  if STATE.notes[STATE.notei] ~= nil then
    call_in(prep_note, 50)
  else
    call_in(finish, 50)
  end
end



