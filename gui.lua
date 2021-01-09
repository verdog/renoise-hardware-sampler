vb = nil

require"func"

function value_field(_text, _min, _max, _notif)
 return vb:row {
   vb:text {
     text = _text.." "
   },
   vb:valuefield {
     min = _min,
     max = _max,
     -- todo: tostring/tonum
     notifier = _notif
   }
 }
end

function checkbox(_text, _notif)
 return vb:row {
   vb:text {
     text = _text.." "
   },
   vb:checkbox {
     value = false,
     notifier = _notif
   }
 }
end

function note_matrix()
  local title = vb:text {
    text = "Notes to sample in each octave:"
  }
  local row = vb:row{}
  local notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  local C_PRESSED = {100, 100, 100}
  local C_NOT_PRESSED = {20, 20, 20}
  local UNIT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local colors = {}
  
  for note = 1,12 do
    local button = vb:button {
      text = notes[note],
      width = UNIT*1.5,
      height = UNIT,
      color = C_NOT_PRESSED,
      notifier = nil
    }
    row:add_child(button)
  end
  return vb:column{title, row}
end

function midi_list()
  return vb:row {
    vb:text {
      text = "Midi Device: "
    },
    vb:popup {
      width = 100,
      value = 2,
      items = renoise.Midi.available_output_devices(),
      notifier = select_midi_device
    }
  }
end

function show_menu()
 vb = renoise.ViewBuilder()
 local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
 local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
 local UNIT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
 local title = "Create Instrument From Hardware"


 local content = vb:column {
   margin = DEFAULT_MARGIN,
   
   -- status text
   vb:text {
     id = "status",
     text = "Waiting..."
   },
   
   -- start/test
   vb:row {
     vb:button {
       width = 4*UNIT,
       height = 3*UNIT,
       text = "Start",
       notifier = go
     },
     vb:button {
       width = 4*UNIT,
       height = 3*UNIT,
       text = "Test Midi",
       notifier = test_midi
     }
   },
   
   -- midi device selection
   midi_list(),
   
   -- notes selection
   note_matrix(),
   
   -- octave options
   value_field("Low Octave", 0, 8),
   value_field("High Octave", 0, 8),
   
   -- sample length
   value_field("Sample Length (seconds)"),
   
   -- sample processing
   checkbox("Maximize Sample Volume"),
   checkbox("Remove Beginning Silence")
 }

 select_midi_device(1)
 update_status("Waiting...")

 renoise.app():show_custom_dialog(
   title, content
 )

end