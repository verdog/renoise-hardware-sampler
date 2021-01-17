-- intensive processing and coroutine stuff

require"process_slicer"

function prep_processing(func)
  if SAMPLE_PROCESSING_PROCESS and SAMPLE_PROCESSING_PROCESS:running() then
    SAMPLE_PROCESSING_PROCESS:stop()
  end
  
  SAMPLE_PROCESSING_PROCESS = ProcessSlicer(func)
end

-- currently running coroutine
SAMPLE_PROCESSING_PROCESS = nil

WHEELI = 0
function coroutine_status(s, nowheel)
  local wheel = {[0]="/", "-", "\\", "|"}
  if s then
    if not nowheel then
      vb.views.processing_status_text.text = wheel[WHEELI].." "..s
    else
      vb.views.processing_status_text.text = s
    end
  else
    -- just update the wheel
    local oldtext = vb.views.processing_status_text.text
    vb.views.processing_status_text.text = wheel[WHEELI].." "..string.sub(oldtext, 3)
  end
  
  -- check that the window is still open
  if ((not WINDOW) or (not WINDOW.visible)) 
    and (SAMPLE_PROCESSING_PROCESS and SAMPLE_PROCESSING_PROCESS:running()) then
    
    if not OPTIONS.background then
      SAMPLE_PROCESSING_PROCESS:stop()
      update_status("Stopped processing: window closed.")
    else
      update_status("Processing continuing in background.")
    end
  end
  
  WHEELI = (WHEELI + 1) % table.getn(wheel)
end

-- boost each sample's volume an equal amount ---------------------------------
function normalize()
  prep_processing(normalize_coroutine)
  SAMPLE_PROCESSING_PROCESS:start()
end

function normalize_coroutine()
  stop()
  update_status("Normalizing Sample Volumes... This may take some time...")

  local ticki = 0
  local maxtick = OPTIONS.background and 1024 * 64 or 1024 * 2048
  
  local function tick()
    -- turn wheel
    ticki = (ticki + 1) % maxtick
    if ticki == maxtick - 1 then
      coroutine_status()
      coroutine.yield()
    end
  end
  
  -- maximize sample volumes
  local inst = renoise.song().selected_instrument
  local maxes = {}

  -- store max for each sample
  for i = 1,table.count(inst.samples) do
    coroutine_status("Finding peak in "..inst.samples[i].name)
    
    local buf = inst.samples[i].sample_buffer
    -- find peak
    local chans = buf.number_of_channels
    local max = 0
    
    for c = 1,chans do
      for f = 1,buf.number_of_frames do
        max = math.max(math.abs(buf:sample_data(c, f)), max)
        
        tick()
      end
    end
    
    table.insert(maxes, max)
    coroutine.yield()
  end

  -- determine highest max
  local maxmax = 0
  for k, m in pairs(maxes) do
    maxmax = math.max(m, maxmax)
  end

  -- apply to samples
  for i = 1,table.count(inst.samples) do
    coroutine_status("Normalizing "..inst.samples[i].name)
    
    local buf = inst.samples[i].sample_buffer
    local chans = buf.number_of_channels
    
    buf:prepare_sample_data_changes()
    for c = 1,chans do
      for f = 1,buf.number_of_frames do
        local dot = buf:sample_data(c, f)
        buf:set_sample_data(c, f, 1/maxmax * dot)
        
        tick()
      end
    end
    buf:finalize_sample_data_changes()
    
    coroutine.yield()
  end
  
  coroutine_status("Done!", true)
  update_status("Done normalizing volumes!")
end

-- remove silence from the beginning of all samples ----------------------------
function trim()
  prep_processing(trim_coroutine)
  SAMPLE_PROCESSING_PROCESS:start()
end

function trim_coroutine()
  stop()
  update_status("Trimming Leading Silence From Samples... This may take some time...")

  local ticki = 0
  local maxtick = OPTIONS.background and 1024 * 64 or 1024 * 2048
  
  local function tick()
    -- turn wheel
    ticki = (ticki + 1) % maxtick
    if ticki == maxtick - 1 then
      coroutine_status()
      coroutine.yield()
    end
  end

  -- trim silence
  local inst = renoise.song().selected_instrument

  for i = 1,table.count(inst.samples) do
    coroutine_status("Trimming "..inst.samples[i].name)
    
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
        
        tick()
      end
    end
    
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
        
        tick()
      end
    end
    buf:finalize_sample_data_changes()
    
    coroutine.yield()
  end
  
  coroutine_status("Done!", true)
  update_status("Done trimming silences!")
end

