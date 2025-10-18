----
-- Keyboard bindings for Leap

-- To do:
--    Catch application switches and turn off leap
--    Try watching keys directly
--    √ Different find keys for applications
--    Check out for what to do other than find
--    Make faster
--    √ Read up on Enso

--  Universal smart keys:
--    √ Select word under cursor   option <, shift option >  
--    Move para up/down   cmd+opt  -> cmd <, shift cmd >, cut, up, paste, return


require "utils"

spaceDown=false
leaping=false
action="none"
delay=1

appKeys = {
  { name="Mail", enterMod="cmd", enterKey="l", exitMod="", exitKey="return" },
  { name="Finder", enterMod="cmd", enterKey="l", exitMod="", exitKey="return" }
}

keys = {
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
  "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}

leapKeys={}
-- function bind(k, fnDn, rpt)
--   -- leap Keys[k]= hs.hotkey.bind("", k, fnDn, fnUp, rpt and fnDn or nil):disable()
-- end

-- for i = 1,#keys do
--   local k = keys[i]
--   bind(k,function() echo(k) end)
-- end
-- bind(",", function() aktion(",") end,true)
-- bind(".", function() aktion(".") end,true)
-- bind("/", function() swap() end)

keyDownWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local key = event:getCharacters(true)
  if key == " " then
    if spaceDown then
    -- repeat space if not leaping
      print("shift down repeat")
      return leaping

    else
      print("space down")
      spaceDown = true
      leaping = false
      return false       -- eat the character
    end

  else
    -- normal character
    print("normal "..key)
    return false

  end
end):start()

keyUpWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
  local key = event:getCharacters(true)
  if key == " " then
    -- space up, reset leaping
    print("space up")
    spaceDown = false
    leaping = false
    return false

  elseif spaceDown then
    -- leap
    if hs.fnutils.contains(keys, key) then
      print("leap "..key)
      leap(key)
      return false
    
    else
      return true
      -- aktion
      -- print("aktion "..key)
      -- return true
    end

  else
    -- normal key up
    return false
  end
end):start()

-- f
-- firstofalldoesthisevenwork?Answernospacesatall     this is this better?  
--  works for slow typing
-- doesnt work for faster typing, because the sloppiness 

-- thsis is ok this is ok is there a timer that we need to handle fast time typing what is the frasters the kj d 
-- jfjfjf f f f 
function leap(key)
  if not leaping then
    local app = hs.application.frontmostApplication():name()
    local enterMod, enterKey=  "cmd", "f"
    local a = hs.fnutils.find(appKeys, function(_a) return _a.name == app end)
    if a then
      print("Using app enter")
      enterMod, enterKey = a.enterMod, a.enterKey
    end

    keyDownWatcher:stop()
    keyUpWatcher:stop()
    hs.eventtap.keyStroke(enterMod,enterKey,delay)
    keyDownWatcher:start()
    keyUpWatcher:start()
    leaping = true
  end
end

function aktion(key)
  local anchor,extend = "right","left"
  if key == "." then anchor,extend = extend,anchor end
  if action == "none" or action == "end" then
    hs.eventtap.keyStroke("alt",anchor,delay)
    hs.eventtap.keyStroke("alt-shift",extend,delay)
    action = "word"
  elseif action == "word" then
    hs.eventtap.keyStroke("alt-shift",extend,delay)
  else
    action = "end"
  end
end

function swap(key)
  hs.eventtap.keyStroke("shift","left",20000)
  hs.eventtap.keyStroke("cmd","x",20000)
  hs.eventtap.keyStroke("","right",20000)
  hs.eventtap.keyStroke("cmd","v",20000)
  action = "end"
end

-- the quick broownnnnnn fox J voSr the elazyPMoo goUdo

--

function onLeapDown()
  leaping=false
  action="none"
  enableLeapKeys()
end
 
function onLeapUp()
  disableLeapKeys()
  if leaping then
    print("onLeapUp")
    local app = hs.application.frontmostApplication():name()
    local exitMod, exitKey=  "", "return"
    local a = hs.fnutils.find(appKeys, function(_a) return _a.name == app end)
    if a then
      print("Using app exit")
      exitMod, exitKey = a.exitMod, a.exitKey
    end
    hs.eventtap.key(exitMod,exitKey)
  elseif action ~= "none" then
    -- do nothing
  else
    leapSpace:disable()
    hs.eventtap.keyStroke("", "space")
    leapSpace:enable()
  end
end

function onLeapRepeat()
  -- leapSpace:disable()
  -- hs.eventtap.keyStroke("", "space")
  -- leapSpace:enable()
end

--
--
-- abcd 

-- leapSpace = bindKey("", "space", "Leap key", onLeapDown, onLeapUp, onLeapRepeat)

print("loaded leap")