require"func"
require"crunch"

vb = nil
WINDOW = nil
DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
UNIT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

function textfield(_text, _value, _notif)
  return
end

-- displays the total number of samples to be recorded and estimated job length
function update_record_time_txt()
  local notes = gen_notes()
  local total_samples = #notes * tonumber(OPTIONS.layers)
  local between_time_ms = tonumber(OPTIONS.between_time) / 1000
  local seconds = (tonumber(OPTIONS.length) + tonumber(OPTIONS.release) + between_time_ms) * total_samples
  local time = seconds

  --How to convert decimal seconds to time format
  --Convert seconds to hh:mm:ss

  --7147.3 seconds can be converted to hours by dividing 7147.3 seconds / 3600 seconds/hour ≈ 1.9854 hours
  --1.9854 hours can be broken down to 1 hour plus 0.9854 hours - 1 hour
  --0.9854 hours * 60 minutes/hour = 59.124 minutes - 59 minutes
  --0.124 minutes * 60 seconds/minute = 7.44 seconds - rounded = 7 seconds
  --01:59:07

  local hours = seconds / 3600
  local hour = math.floor(hours)
  local minutes = (hours - hour) * 60
  local minute = math.floor(minutes)
  local seconds = (minutes - minute) * 60
  local second = math.floor(seconds)
  local millisecond = math.floor((seconds - second) * 60)

  time = string.format("%d:%02d:%02d:%02d", hour, minute, second, millisecond)

  vb.views.record_time_txt.text = string.format("%d Samples: ~%s", total_samples, time)
end

function value_box(_text, _tip, _value, _min, _max, _steps, _notif, _tostring, _tonum, _width)
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
      width = _width or UNIT*4,
      tooltip = _tip
    }
  }
end

-- generic button matrix. Use this to create specific button matricies
function button_matrix(buttons, name, options, tooltip, callback)
  local row = vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,
    mode = "distribute",
    spacing = 1
  }

  -- callback is the is the callback the notifier should run
  local notifier = function(button, name, callback)
    -- do GUI work
    toggle_button(button, name)

    -- run callback
    if callback then
      print("Running callback for button matrix:", name)
      callback()
    end
  end

  for button = 0,#buttons do
    local button = vb:button {
      id = name.."_button_"..tostring(button),
      text = buttons[button],
      width = UNIT*1.5,
      height = UNIT*1.5,
      color = options[button] and C_PRESSED or C_NOT_PRESSED,
      notifier = function(x) notifier(button, name, callback) end,
      tooltip = tooltip
    }
    row:add_child(button)
  end

  return row
end

function note_matrix()
  local tooltip = "Select notes that will be sampled in each octave."

  local callback = function()
    update_record_time_txt()
  end

  return button_matrix(NOTES, "notes", OPTIONS.notes, tooltip, callback)
end

function tag_matrix()
  local tooltip = "Select tags to include in instrument name"

  local callback = function()
    update_instrument_name()
  end
  
  return button_matrix(TAGS, "tags", OPTIONS.tags, tooltip, callback)
end

function midi_list()
  return vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,
    spacing = 1,
    mode = "distribute",
    vb:text {
      width = "10%",
      text = "Device"
    },
    vb:popup {
      width = "50%",
      items = renoise.Midi.available_output_devices(),
      notifier = select_midi_device,
      tooltip = "MIDI device to send MIDI signals to."
    },
    vb:text {
      width = "15%",
      text = "Channel"
    },
    vb:popup {
      width = "15%",
      value = 1,
      items = {"1", "2", "3", "4", "5", "6", "7", "8",
        "9", "10", "11", "12", "13", "14", "15", "16"},
      notifier = select_midi_channel,
      tooltip = "Which MIDI channel to send signals over."
    }
  }
end

function show_menu()
  vb = renoise.ViewBuilder()
  local title = "Create Instrument From Hardware"

  local content = vb:column {
    margin = DEFAULT_MARGIN*2,
    width = UNIT*24,
    spacing = UNIT/2,
    
    -- instrument naming
    vb:column {
      style = "panel",
      margin = DEFAULT_MARGIN,
      width = "100%",

      vb:text {
        text = "Name",
        align = "center",
        width = "100%"
      },

      vb:space {
        height = UNIT/3
      },
      
      -- name
      vb:horizontal_aligner {
        margin = DEFAULT_MARGIN,
    
        vb:text {
          text = "Instrument name ",
          width = "25%"
        },
        vb:textfield {
          id = "instrument_name_textfield",
          value = OPTIONS.name,
          notifier = function() update_instrument_name() end,
          width = "50%",
          tooltip = "Instrument name to set when sampling is over."
        },
        vb:button {
          text = "Auto-Name",
          notifier = autoname,
          width = "25%",
          tooltip = "Generate a random instrument name"
        }
      },

      vb:horizontal_aligner {
        margin = DEFAULT_MARGIN,
        
        vb:text {
          text = "Hardware name ",
          width = "25%"
        },
        vb:textfield {
          id = "hardware_name_textfield",
          value = OPTIONS.hardware_name,
          notifier =  function() update_instrument_name() end,
          width = "50%",
          tooltip = "Append the hardware device's name to further identify."
        }
      },

      vb:horizontal_aligner {
        margin = DEFAULT_MARGIN,
        vb:text {
          text = "Tags:",
          width = "25%"
        }
      },
      
      -- produces the tag buttons
      tag_matrix()
    },

    -- midi options
    vb:column {
      style = "panel",
      margin = DEFAULT_MARGIN,
      
      vb:text {
        text = "MIDI and Note Options",
        align = "center",
        width = "100%"
      },
      vb:space {
        height = UNIT/3
      },
      
      -- midi device selection
      midi_list(),
      
      -- octave options
      vb:horizontal_aligner {
        mode = "center",
        spacing = DEFAULT_MARGIN,
  
        value_box("Low Octave", "The lowest octave from which to sample.", 
                  OPTIONS.low, 0, 9, {1, 2}, 
                  function(x) 
                    OPTIONS.low = x 
                    update_record_time_txt()
                  end, 
                  tostring, 
                  math.floor),
        value_box("High Octave", "The highest octave from which to sample.", 
                  OPTIONS.high, 0, 9, {1, 2}, 
                  function(x) 
                    OPTIONS.high = x 
                    update_record_time_txt()
                  end, 
                  tostring, 
                  math.floor),
        value_box("Vel. Layers", "How many different equally spaced velocities to sample for a given note.", 
                  OPTIONS.layers, 1, 32, {1, 2}, 
                  function(x) 
                    OPTIONS.layers = x 
                    update_record_time_txt()
                  end, 
                  tostring, 
                  math.floor)
      },
      
      -- notes selection
      note_matrix(),
      
      -- mapping style
      vb:horizontal_aligner {
        margin = DEFAULT_MARGIN,
        spacing = DEFAULT_MARGIN,
        
        vb:text {
          text = "Mapping style:"
        },
        vb:switch {
          width = "80%",
          items = {"Down", "Middle", "Up"},
          value = OPTIONS.mapping,
          notifier = function(x) OPTIONS.mapping = x end,
          tooltip = "How samples are mapped to keys.\n"..
          "\nDown: Sampled notes will be mapped to their root note and to notes between the root and the next lowest sample.\n"..
          "\nMiddle: Given a key, it will be mapped to the closest existing sample.\n"..
          "\nUp: Sampled notes will be mapped to their root note and to notes between the root and the next highest sample."
        }
      },
      
      -- sample length
      vb:horizontal_aligner {
        mode = "left",
        spacing = DEFAULT_MARGIN,
  
        value_box("Hold time", "How long the note on signal will be held.", 
                  OPTIONS.length, 0.1, 60, {0.1, 1}, 
                  function(x) 
                    OPTIONS.length = x 
                    update_record_time_txt()
                  end, 
                  function(x) 
                    return tostring(x).." s." 
                  end, 
                  tonumber),
        value_box("Release time", "How long the tool will wait for the note to release after note off.", 
                  OPTIONS.release, 0.1, 60, {0.1, 1}, 
                  function (x) 
                    OPTIONS.release = x 
                    update_record_time_txt()
                  end, 
                  function(x) 
                    return tostring(x).." s." 
                  end, 
                  tonumber),
        vb:text {
          id = "record_time_txt",
          text = "Record time:"
        }
      }
    },

    -- big buttons
    vb:horizontal_aligner {
      mode = "center",
      width = "100%",

      vb:button {
        width = "33%",
        height = 2*UNIT,
        text = "Start",
        notifier = go,
        tooltip = "Start the recording process."
      },
      vb:button {
        width = "33%",
        height = 2*UNIT,
        text = "Stop",
        notifier = stop,
        tooltip = "Stop the recording process."
      },
      vb:button {
        width = "33%",
        height = 2*UNIT,
        text = "Recording Settings",
        notifier = configure,
        tooltip = "Open the Renoise sample recording window. Tweak your input settings to your liking here."
      }
    },
    vb:horizontal_aligner {
      vb:row {
        spacing = UNIT/3,

        vb:checkbox {
          value = OPTIONS.post_record_normalize_and_trim,
          notifier = function(x) OPTIONS.post_record_normalize_and_trim = x end,
          tooltip = "If checked, all samples will be normalized and trimmed after recording has completed."
        },

        vb:text {
          text = "Normalize and Trim samples after recording"
        }
      },
    },

    vb:horizontal_aligner {
      vb:row {
        spacing = UNIT/3,

        vb:checkbox {
          value = OPTIONS.add_adsr,
          notifier = function(x) toggle_adsr(x) end,
          tooltip = "If checked, an ADSR effect will be added to the instrument. If Pad or String tags are selected, the envelope's release time will be slightly longer by default."
        },

        vb:text {
          text = "Insert ADSR"
        }
      },
    },
    

    -- sample processing
    vb:column {
      style = "panel",
      width = "100%",
      margin = DEFAULT_MARGIN,
    
      vb:text {
        text = "Post Processing",
        align = "center",
        width = "100%"
      },
      vb:space {
        height = UNIT/3
      },

      vb:horizontal_aligner {
        spacing = UNIT,
        margin = DEFAULT_MARGIN,

        vb:row {
          spacing = UNIT/3,
          
          vb:checkbox{
            value = OPTIONS.background,
            notifier = function(x) OPTIONS.background = x end,
            tooltip = "If checked, process the samples a little bit slower in order to make Renoise more usable while the processing is done."
          },

          vb:text {
            text = "Process in background"
          },
        }
      },
      
      vb:horizontal_aligner {
        spacing = UNIT,
        margin = DEFAULT_MARGIN,
        mode = "left",
        
        vb:button {
          text = "Normalize Sample Volumes",
          notifier = normalize,
          tooltip = "Raise the volume of each sample an equal amount. The amount will be the amount that the loudest sample can be raised before clipping."
        },
        vb:button {
          text = "Trim Silences",
          notifier = trim,
          tooltip = "Remove any silence at the beginning of all samples."
        }
      },

      vb:horizontal_aligner {
        spacing = UNIT,
        margin = DEFAULT_MARGIN,
        width = "100%",

        vb:row {
          spacing = UNIT,
          style = "group",
          width = "100%",

          vb:text {
            text = "Status:"
          },
          vb:text {
            text = "Waiting",
            width = "90%",
            id = "processing_status_text"
          }
        }
      },
    }
  }

  -- init views and fields
  select_midi_device(1)
  update_record_time_txt()

  WINDOW = renoise.app():show_custom_dialog(
    title, content
  )
end
