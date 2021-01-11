vb = nil

require"func"

function value_box(_text, _value, _min, _max, _steps, _notif, _tostring, _tonum)
 return vb:row {
   vb:text {
     text = _text.." "
   },
   vb:valuebox {
     min = _min,
     max = _max,
     tostring = _tostring,
     tonumber = _tonum,
     notifier = _notif,
     value = _value,
     steps = _steps
   }
 }
end

function checkbox(_text, _value, _notif)
 return vb:row {
   vb:text {
     text = _text.." "
   },
   vb:checkbox {
     value = _value,
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
  local UNIT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local colors = {}
  
  for note = 1,12 do
    local button = vb:button {
      id = "note_button_"..tostring(note-1),
      text = notes[note],
      width = UNIT*1.5,
      height = UNIT,
      color = OPTIONS.notes[note-1] and C_PRESSED or C_NOT_PRESSED,
      notifier = function() toggle_note(note - 1) end
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
   
   -- big buttons
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
     },
     vb:button {
       width = 4*UNIT,
       height = 3*UNIT,
       text = "Stop Process",
       notifier = stop
     },
     vb:button {
       width = 4*UNIT,
       height = 3*UNIT,
       text = "Configure Recording Settings",
       notifier = configure
     }
   },
   
   -- midi device selection
   midi_list(),
   
   -- notes selection
   note_matrix(),
   
   -- octave options
   value_box("Low Octave", OPTIONS.low, 0, 9, {1, 2}, function(x) OPTIONS.low = x end, tostring, math.floor),
   value_box("High Octave", OPTIONS.high, 0, 9, {1, 2}, function(x) OPTIONS.high = x end, tostring, math.floor),
   
   -- sample length
   value_box("Note hold time (seconds)", OPTIONS.length, 0.1, 60, {0.1, 5}, function(x) OPTIONS.length = x end, tostring, function(x) return x end),
   value_box("Note release time (seconds)", OPTIONS.release, 0.1, 60, {0.1, 5}, function (x) OPTIONS.release = x end, tostring, function (x) return x end),
   
   -- sample processing
   checkbox("Maximize Sample Volume", OPTIONS.maximize, function(x) OPTIONS.maximize = x end),
   value_box("Silence Trim Threshold", OPTIONS.threshold, 0.01, 1, {0.01, .1}, function(x) OPTIONS.threshold = x end, tostring, function(x) return x end)
 }

 select_midi_device(1)
 update_status("Waiting...")

 renoise.app():show_custom_dialog(
   title, content
 )

end