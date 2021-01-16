require"func"

vb = nil
DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
UNIT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

function textfield(_text, _value, _notif)
  return vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,

    vb:text {
      text = _text.." ",
      width = "20%"
    },
    vb:textfield {
      value = _value,
      notifier = _notif,
      width = "80%"
    }
  }
end

function value_box(_text, _value, _min, _max, _steps, _notif, _tostring, _tonum, _width)
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
      steps = _steps,
      width = _width or UNIT*4
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
  local row = vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,
    mode = "distribute",
    spacing = 1
  }
  local notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  
  for note = 1,12 do
    local button = vb:button {
      id = "note_button_"..tostring(note-1),
      text = notes[note],
      width = UNIT*1.5,
      height = UNIT*1.5,
      color = OPTIONS.notes[note-1] and C_PRESSED or C_NOT_PRESSED,
      notifier = function() toggle_note(note - 1) end
    }
    row:add_child(button)
  end
  return row
end

function midi_list()
  return vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_MARGIN,
    vb:text {
      width = "20%",
      text = "Midi Device"
    },
    vb:popup {
      width = "80%",
      value = 2,
      items = renoise.Midi.available_output_devices(),
      notifier = select_midi_device
    }
  }
end

function show_menu()
  vb = renoise.ViewBuilder()
  local title = "Create Instrument From Hardware"

  local content = vb:column {
    margin = DEFAULT_MARGIN*2,
    
    -- big buttons
    vb:horizontal_aligner {
      mode = "center",

      vb:button {
        width = "33%",
        height = 2*UNIT,
        text = "Start",
        notifier = go
      },
      vb:button {
        width = "33%",
        height = 2*UNIT,
        text = "Stop",
        notifier = stop
      },
      vb:button {
        width = "33%",
        height = 2*UNIT,
        text = "Recording Settings",
        notifier = configure
      }
    },
    
    -- midi device selection
    midi_list(),
    
    -- octave options
    vb:horizontal_aligner {
      mode = "center",
      spacing = DEFAULT_MARGIN,

      value_box("Low Octave", OPTIONS.low, 0, 9, {1, 2}, function(x) OPTIONS.low = x end, tostring, math.floor),
      value_box("High Octave", OPTIONS.high, 0, 9, {1, 2}, function(x) OPTIONS.high = x end, tostring, math.floor)
    },
    
    -- notes selection
    note_matrix(),
    
    -- sample length
    vb:horizontal_aligner {
      mode = "center",
      spacing = DEFAULT_MARGIN,

      value_box("Hold time", OPTIONS.length, 0.1, 60, {0.1, 1}, function(x) OPTIONS.length = x end, function(x) return tostring(x).." s." end, tonumber),
      value_box("Release time", OPTIONS.release, 0.1, 60, {0.1, 1}, function (x) OPTIONS.release = x end, function(x) return tostring(x).." s." end, tonumber)
    },
      
    -- sample processing
    vb:horizontal_aligner {
      spacing = UNIT,
      margin = DEFAULT_MARGIN,
      mode = "center",

      vb:button {
        text = "Normalize Sample Volumes",
        notifier = normalize
      },
      vb:button {
        text = "Trim Silences",
        notifier = trim
      }
    },
    
    -- name
    textfield("Inst. name", OPTIONS.name, function(x) OPTIONS.name = x end)
  }

  select_midi_device(1)

  renoise.app():show_custom_dialog(
    title, content
  )
end
