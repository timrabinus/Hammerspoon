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
function bind(k, fnDn, rpt)
  leapKeys[k]= hs.hotkey.bind("", k, fnDn, fnUp, rpt and fnDn or nil):disable()
end

for i = 1,#keys do
  local k = keys[i]
  bind(k,function() echo(k) end)
end
bind(",", function() aktion(",") end,true)
bind(".", function() aktion(".") end,true)
bind("/", function() swap() end)

x = nil
x = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  print('tap!', hs.inspect(event))
  return false
end)
x:start() 

function disableLeapKeys()
  x:stop()
  -- for i,hk in pairs(leapKeys)
  --   hk:disable()
  -- end
end 

function enableLeapKeys()
  x:start()  
  -- for i,hk in pairs(leapKeys) do
  --   hk:enable()
  -- end
end

--

function echo(key)
  leapKeys[key]:disable()
  if not leaping then
    local app = hs.application.frontmostApplication():name()
    local enterMod, enterKey=  "cmd", "f"
    local a = hs.fnutils.find(appKeys, function(_a) return _a.name == app end)
    if a then
      print("Using app enter")
      enterMod, enterKey = a.enterMod, a.enterKey
    end
    hs.eventtap.keyStroke(enterMod,enterKey,delay)
    leaping = true
  end
  hs.eventtap.keyStroke("", key)
  leapKeys[key]:enable()
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

leapSpace = bindKey("", "space", "Leap key", onLeapDown, onLeapUp, onLeapRepeat)

print("loaded leap")