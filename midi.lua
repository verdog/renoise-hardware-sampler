-- midi signal constants
-- can be changed by select_midi_channel
NOTE_ON = 0x90
NOTE_OFF = 0x80
ALL_NOTE_OFF_1 = 0xB0
ALL_NOTE_OFF_2 = 0x7B


-- get midi device name
function select_midi_device(dev_index)
  print("dev index:"..dev_index)
  STATE.midi_device = renoise.Midi.available_output_devices()[dev_index]
  STATE.midi_device_index = dev_index
  prefs:write("midi_device_index", dev_index)
  
  print("Selected device: "..STATE.midi_device)
end

-- get midi device object
function get_midi_dev()
  print("Getting device: "..STATE.midi_device)
  return renoise.Midi.create_output_device(STATE.midi_device)
end

-- changes NOTE_ON and NOTE_OFF globals
function select_midi_channel(channel)
  print("Selected channel: "..channel)
  NOTE_ON = bit.bor(0x90, channel-1)
  NOTE_OFF = bit.bor(0x80, channel-1)
  ALL_NOTE_OFF_1 = bit.bor(0xB0, channel-1)
  ALL_NOTE_OFF_2 = bit.bor(0x7B, channel-1)
end

-- get midi device object
function get_midi_dev()
  print("Getting device: "..STATE.midi_device)
  return renoise.Midi.create_output_device(STATE.midi_device)
end

