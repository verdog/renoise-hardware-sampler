TOCALL = nil      -- function to call when the timer runs out
KILL = false      -- has the stop button been pushed

-- use a renoise timer to call a function in approx. mill milleseconds
function call_in(func, mill)
  TOCALL = func
  renoise.tool():add_timer(call, mill)
end

-- do the actual function call
function call()
  renoise.tool():remove_timer(call)
  if TOCALL and not KILL then
    TOCALL()
  end
end

function update_status(status)
  renoise.app():show_status(status)
  print(status)
end

-- convert a renoise note number to its name
function note_to_name(note)
  local octave = math.floor(note/12)
  local key = note % 12
  local keys = {[0]="C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  return keys[key] .. tostring(octave)
end

-- capitalize a word
function upcase(word)
  return string.gsub(" "..word, "%W%l", string.upper):sub(2)
end

function get_table_index_by_value(values, value)
  local index={}

  for k,v in pairs(values) do
     index[v]=k
  end

  return index[value]
end