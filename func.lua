require"util"

-- global options box
OPTIONS = {
  low = 1,
  high = 6,
  length = 2,
  release = .2,
  notes = {[0]=true, false, false, false, true, false, false, false, true, false, false, false},
  name = "Recorded Hardware"
}

-- note button colors
C_PRESSED = {100, 100, 100}
C_NOT_PRESSED = {20, 20, 20}

-- midi signal constants
NOTE_ON = 0x90
NOTE_OFF = 0x80

-- state
MIDI_DEVICE = nil -- current midi device name
DEV = nil         -- current midi device object
RECORDING = false -- are we actively recording
NOTES = nil       -- list of notes to send to the midi device
NOTEI = nil       -- current index in note list

function update_status(status)
  renoise.app():show_status(status)
  print(status)
end

-- toggle a note to record on or off
function toggle_note(note)
  print("toggling note "..tostring(note))

  -- set data
  OPTIONS.notes[note] = not OPTIONS.notes[note]

  -- set visual
  vb.views["note_button_"..tostring(note)].color = 
    OPTIONS.notes[note] and C_PRESSED or C_NOT_PRESSED
end


-- get midi device name
function select_midi_device(dev)
  MIDI_DEVICE = renoise.Midi.available_output_devices()[dev]
  print("Selected device: "..MIDI_DEVICE)
end

-- get midi device object
function get_midi_dev()
  print("Getting device: "..MIDI_DEVICE)
  return renoise.Midi.create_output_device(MIDI_DEVICE)
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

-- convert a renoise note number to its name
function note_to_name(note)
  local octave = math.floor(note/12)
  local key = note % 12
  local keys = {[0]="C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  return keys[key] .. tostring(octave)
end

-- reset state to be ready to record
function reset_state()
  NOTEI = nil
  NOTES = nil
  DEV = nil
  TOCALL = nil
  KILL = false
  RECORDING = false

  if renoise.tool():has_timer(start_note) then
    renoise.tool():remove_timer(start_note)
  end

  if renoise.tool():has_timer(stop_note) then
    renoise.tool():remove_timer(stop_note)
  end
end

-- check for invalid options
function check()
 if OPTIONS.low > OPTIONS.high then
   renoise.app():show_prompt("Oops!", "Low octave must be <= high octave.", {"OK"})
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

  NOTES = gen_notes()
  NOTEI = 1
  DEV = get_midi_dev()

  local inst = renoise.song().selected_instrument

  -- clear samples
  while table.count(inst.samples) > 0 do
    inst:delete_sample_at(1)
  end

  -- insert blank samples
  for i=1,table.count(NOTES) do
    inst:insert_sample_at(i)
  end

  -- set up mappings
  for i=1,table.count(NOTES) do
    rprint(inst.sample_mappings)
    local mapping = inst.sample_mappings[1][i]
    mapping.base_note = NOTES[i]
    
    local low
    if i == 1 then
      low = 0
    else
      low = NOTES[i]
    end
    
    local high
    if i == table.count(NOTES) then
      high = 119
    else
      high = NOTES[i+1] - 1
    end
    mapping.note_range={low, high}
  end

  -- start on first sample
  renoise.song().selected_sample_index = 1

  -- go!
  prep_note()
end

-- apply finishing touches
function finish()
  update_status("Finishing...")
  local inst = renoise.song().selected_instrument

  -- name instrument
  inst.name = OPTIONS.name

  -- name samples
  for i=1,table.count(NOTES) do
    inst.samples[i].name = note_to_name(NOTES[i])
  end

  -- close recording window
  renoise.app().window.sample_record_dialog_is_visible = false

  -- close midi
  DEV:close()
end

-- kill switch
function stop()
  KILL = true
  if RECORDING then
    renoise.app().window.sample_record_dialog_is_visible = true
    renoise.song().transport:start_stop_sample_recording()
    RECORDING = false
    DEV:send({NOTE_OFF, NOTES[NOTEI] + 0xC, 0x7F}) -- release current note
    DEV:send({0xB0, 0x7B, 0x00}) -- send all notes off
  end
  renoise.app().window.sample_record_dialog_is_visible = false
  if DEV and DEV.is_open then
    DEV:close()
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
  print("Prepping note...")
  renoise.song().selected_sample_index = NOTEI
  renoise.app().window.sample_record_dialog_is_visible = true
  renoise.song().transport:start_stop_sample_recording()
  RECORDING = true
  call_in(start_note, 100)
end

-- play the note
function start_note()
  print("Starting note...")
  DEV:send({NOTE_OFF, NOTES[NOTEI] + 0xC, 0x7F}) -- just in case...
  DEV:send({NOTE_ON, NOTES[NOTEI] + 0xC, 0x7F})
  call_in(release_note, OPTIONS.length * 1000)
end

-- release the note
function release_note()
  print("Releasing note...")
  DEV:send({NOTE_OFF, NOTES[NOTEI] + 0xC, 0x7F})
  call_in(stop_note, OPTIONS.release * 1000)
end

-- stop recording, prep next note
function stop_note()
  print("Stopping note...")
  renoise.app().window.sample_record_dialog_is_visible = true
  renoise.song().transport:start_stop_sample_recording()
  RECORDING = false

  NOTEI = NOTEI + 1

  if NOTES[NOTEI] ~= nil then
    call_in(prep_note, 100)
  else
    call_in(finish, 100)
  end
end

-- boost each sample's volume an equal amount
function normalize()
  stop()
  update_status("Normalizing Sample Volumes... This may take some time...")
  -- maximize sample volumes
  local inst = renoise.song().selected_instrument

  local maxes = {}

  -- store max for each sample
  for i = 1,table.count(inst.samples) do
    local buf = inst.samples[i].sample_buffer
    -- find peak
    local chans = buf.number_of_channels
    local max = 0
    
    for c = 1,chans do
      for f = 1,buf.number_of_frames do
        max = math.max(math.abs(buf:sample_data(c, f)), max)
      end
    end
    
    table.insert(maxes, max)
  end

  -- determine highest max
  local maxmax = 0
  for k, m in pairs(maxes) do
    maxmax = math.max(m, maxmax)
  end

  -- apply to samples
  for i = 1,table.count(inst.samples) do
    local buf = inst.samples[i].sample_buffer
    local chans = buf.number_of_channels
    
    buf:prepare_sample_data_changes()
    for c = 1,chans do
      for f = 1,buf.number_of_frames do
        local dot = buf:sample_data(c, f)
        buf:set_sample_data(c, f, 1/maxmax * dot)
      end
    end
    buf:finalize_sample_data_changes()
  end
end

-- remove silence from the beginning of all samples
function trim()
  stop()
  update_status("Trimming Leading Silence From Samples... This may take some time...")

  -- trim silence
  local inst = renoise.song().selected_instrument

  for i = 1,table.count(inst.samples) do
    local buf = inst.samples[i].sample_buffer
    local chans = buf.number_of_channels
    
    -- find cutting point
    local point = buf.number_of_frames + 1
    for c = 1,chans do
      for f = 1,buf.number_of_frames do
        if math.abs(buf:sample_data(c, f)) >= 0.009 then
        point = math.min(f, point)
        break
        end
      end
    end
    
    print("Cutting at "..tostring(point))
    
    -- "cut"
    -- actually copying data closer to start and zeroing out the rest
    buf:prepare_sample_data_changes()
    for c = 1,chans do
      for f = 1,buf.number_of_frames do
        if f < buf.number_of_frames - point then
          buf:set_sample_data(c, f, buf:sample_data(c, f+point))
        else
          buf:set_sample_data(c, f, 0)
        end
      end
    end
    buf:finalize_sample_data_changes()
  end
end