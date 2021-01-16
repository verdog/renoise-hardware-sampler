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
