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

function update_instrument_name()
  local instrument = vb.views.instrument_name_textfield.text
  local hardware = vb.views.hardware_name_textfield.text
  local complete_name = hardware

  for i = 0,#TAGS do
    if OPTIONS.tags[i] then
      if complete_name == "" or complete_name == nil then
        complete_name = TAGS[i]
      else
        complete_name = complete_name.."_"..TAGS[i]
      end
    end
  end
  
  if complete_name == "" or complete_name == nil then
    complete_name = instrument
  else
    complete_name = complete_name.."-"..instrument
  end

  renoise.song().selected_instrument.name = complete_name
end

-- generate random instrument names
function autoname()
  -- the random words list
  local adjs = {"adorable","adventurous","aggressive","agreeable","alert","alive","amused","angry","annoyed","annoying","anxious","arrogant","ashamed","attractive","average","awful","bad","beautiful","better","bewildered","black","bloody","blue","blue-eyed","blushing","bored","brainy","brave","breakable","bright","busy","calm","careful","cautious","charming","cheerful","clean","clear","clever","cloudy","clumsy","colorful","combative","comfortable","concerned","condemned","confused","cooperative","courageous","crazy","creepy","crowded","cruel","curious","cute","dangerous","dark","dead","defeated","defiant","delightful","depressed","determined","different","difficult","disgusted","distinct","disturbed","dizzy","doubtful","drab","dull","eager","easy","elated","elegant","embarrassed","enchanting","encouraging","energetic","enthusiastic","envious","evil","excited","expensive","exuberant","fair","faithful","famous","fancy","fantastic","fierce","filthy","fine","foolish","fragile","frail","frantic","friendly","frightened","funny","gentle","gifted","glamorous","gleaming","glorious","good","gorgeous","graceful","grieving","grotesque","grumpy","handsome","happy","healthy","helpful","helpless","hilarious","homeless","homely","horrible","hungry","hurt","ill","important","impossible","inexpensive","innocent","inquisitive","itchy","jealous","jittery","jolly","joyous","kind","lazy","light","lively","lonely","long","lovely","lucky","magnificent","misty","modern","motionless","muddy","mushy","mysterious","nasty","naughty","nervous","nice","nutty","obedient","obnoxious","odd","old-fashioned","open","outrageous","outstanding","panicky","perfect","plain","pleasant","poised","poor","powerful","precious","prickly","proud","putrid","puzzled","quaint","real","relieved","repulsive","rich","scary","selfish","shiny","shy","silly","sleepy","smiling","smoggy","sore","sparkling","splendid","spotless","stormy","strange","stupid","successful","super","talented","tame","tasty","tender","tense","terrible","thankful","thoughtful","thoughtless","tired","tough","troubled","ugliest","ugly","uninterested","unsightly","unusual","upset","uptight","vast","victorious","vivacious","wandering","weary","wicked","wide-eyed","wild","witty","worried","worrisome","wrong","zany","zealous"}
  local nouns = {"actor","gold","painting","advertisement","grass","parrot","afternoon","greece","pencil","airport","guitar","piano","ambulance","hair","pillow","animal","hamburger","pizza","answer","helicopter","planet","apple","helmet","plastic","army","holiday","portugal","australia","honey","potato","balloon","horse","queen","banana","hospital","quill","battery","house","rain","beach","hydrogen","rainbow","beard","ice","raincoat","bed","insect","refrigerator","belgium","insurance","restaurant","boy","iron","river","branch","island","rocket","breakfast","jackal","room","brother","jelly","rose","camera","jewellery","russia","candle","jordan","sandwich","car","juice","school","caravan","kangaroo","scooter","carpet","king","shampoo","cartoon","kitchen","shoe","china","kite","soccer","church","knife","spoon","crayon","lamp","stone","crowd","lawyer","sugar","daughter","leather","sweden","death","library","teacher","denmark","lighter","telephone","diamond","lion","television","dinner","lizard","tent","disease","lock","thailand","doctor","london","tomato","dog","lunch","toothbrush","dream","machine","traffic","dress","magazine","train","easter","magician","truck","egg","manchester","uganda","eggplant","market","umbrella","egypt","match","van","elephant","microphone","vase","energy","monkey","vegetable","engine","morning","vulture","england","motorcycle","wall","evening","nail","whale","eye","napkin","window","family","needle","wire","finland","nest","xylophone","fish","nigeria","yacht","flag","night","yak","flower","notebook","zebra","football","ocean","zoo","forest","oil","garden","fountain","orange","gas","france","oxygen","girl","furniture","oyster","glass","garage","ghost"}
  
  -- get random adjectives and nouns
  local t = {
    adj  = upcase(adjs[math.random(#adjs)]),
    noun = upcase(nouns[math.random(#nouns)])
  }
  
  -- assemble the instrument name
  local name = string.gsub("$adj $noun", "%$(%w+)", t)

  -- update GUI
  vb.views.instrument_name_textfield.text = name

  update_instrument_name()
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

