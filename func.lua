function update_status(status)
 vb.views.status.text = "Status: "..status
 renoise.app():show_status(status)
 print(status)
end

MIDI_DEVICE = nil

function select_midi_device(dev)
 MIDI_DEVICE = renoise.Midi.available_output_devices()[dev]
 print("Selected device: "..MIDI_DEVICE)
end

function gen_notes()
 -- midi 0xc = c0
 -- renoise 0 = c0
 local ret = {}
 for n=12,12*5,4 do
   table.insert(ret, n)
 end
 return ret
end

NOTEI = nil
NOTES = nil
FIRST = nil
DEV = nil

function go()
 NOTES = gen_notes()
 NOTEI = 1
 FIRST = true
 DEV = get_midi_dev()
 
 if renoise.tool():has_timer(start_note) then
   renoise.tool():remove_timer(start_note)
 end
 if renoise.tool():has_timer(stop_note) then
   renoise.tool():remove_timer(stop_note)
 end
 
 local inst = renoise.song().selected_instrument
 
 -- clear samples
 while table.count(inst.samples) > 0 do
   inst:delete_sample_at(1)
 end
 
 -- insert blank samples
 for i=1,table.count(NOTES) do
   inst:insert_sample_at(1)
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
   
 renoise.song().selected_sample_index = 1
 
 start_note()
 update_status("Recording...")
end

function start_note()
 print("Starting note...")
 renoise.song().selected_sample_index = NOTEI
 renoise.app().window.sample_record_dialog_is_visible = true
 renoise.song().transport:start_stop_sample_recording()
 DEV:send({0x90, NOTES[NOTEI] + 0xC, 0x7F})
 renoise.tool():add_timer(stop_note, 2000)
end

function stop_note()
 print("Stopping note...")
 DEV:send({0x80, NOTES[NOTEI] + 0xC, 0x7F})
 renoise.app().window.sample_record_dialog_is_visible = true
 renoise.song().transport:start_stop_sample_recording()
 
 NOTEI = NOTEI + 1
 
 renoise.tool():remove_timer(stop_note)
 
 if NOTES[NOTEI] ~= nil then
   call_in(start_note, 500)
 end
end

TOCALL = nil

function call()
 print("call")
 renoise.tool():remove_timer(call)
 if TOCALL then
   TOCALL()
 end
 TOCALL = nil
end

function call_in(func, mill)
 print("call in")
 TOCALL = func
 renoise.tool():add_timer(call, mill)
end

function get_midi_dev()
 print("Getting device: "..MIDI_DEVICE)
 return renoise.Midi.create_output_device(MIDI_DEVICE)
end

function test_midi()
 update_status("Testing Midi...")
 print("Testing device: "..MIDI_DEVICE)
 
 local dev = get_midi_dev()
 
 local i = 1
 local notes = gen_notes()
 while notes[i] ~= nil do
   local note = notes[i]  
   dev:send({0x90, note, 0x7F})
   sleep(.25)
   dev:send({0x80, note, 0x7F})
   i = i + 1
 end
 
 -- clean up
 dev:close()
end