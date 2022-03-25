Prefs = {}
  -- return a new Prefs instance
  -- kicks off all the Renoise preference tooling and 
  -- loads stored preferences into the global STATE
  function Prefs:new()
    
    self.options = renoise.Document.create("HWSamplerPreferences") {
      midi_device_index = 1
    }
    
    renoise.tool().preferences = self.options
    
    -- load options into state
    STATE.midi_device_index = self.options.midi_device_index.value
    
    return self
  end
  
  -- reads saved preferences. 
  -- default argument required and is used (and saved) if
  -- the prefernce doesn't exist
  function Prefs:read(pref, default)
    local value = nil
    
    if self.options[tostring(pref)] then
      value = self.options[tostring(pref)].value
    else
      self:write(pref, default)
      value = default
    end
      
    return value
  end
  
  -- writes or updates prefernces for later recall
  function Prefs:write(pref, value)
    -- if the setting exists, update it's value
    if self.options[tostring(pref)] then
      self.options[tostring(pref)].value = value
    -- if the settind doesn't exist yet, save it.
    else
      self.options[tostring(pref)] = value
    end
  end
