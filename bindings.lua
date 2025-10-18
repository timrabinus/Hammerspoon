----
-- Keyboard bindings

require "utils"

bindKey(hyper, "v", "Type from paste buffer", function() 
    hs.eventtap.keyStrokes(get(hs.pasteboard.getContents(),""))  
  end, "Paste as typing")   

keyDownWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local keyCode = event:getKeyCode()
  if keyCode == hs.keycodes.map["f13"] then
-- this requires karabiner to map capslock to f13, otherwise it is not tapped as a keystroke
    if hs.hid.capslock.get() then
      show(" 􀆡 Screen Layout Off")
    else
      show(" 􀆡 Screen Layout On")
    end
    hs.hid.capslock.toggle()
  end
  return false
end):start()

function showContextMenu()
  print("showContextMenu")
  local mouseLoc = hs.mouse.absolutePosition()
  hs.eventtap.rightClick({x=mouseLoc.x,y=mouseLoc.y})
end


bindKey("ctrl", "space", "Show these assigned hotkeys", showContextMenu)

-- 
-- Windows-like Home and End keys
--

function onHome(mods, key)
  local _app = hs.window.focusedWindow():application()
  if _app:name() == "Citrix Viewer" then
    hs.eventtap.keyStroke(mods, "home")
    hs.eventtap.keyStroke(mods, "home")
  else
    hs.eventtap.keyStroke("cmd", "left")
  end
end

function onEnd()
  local _app = hs.window.focusedWindow():application()
  if _app:name() == "Citrix Viewer" then
    hs.eventtap.keyStroke(mods, "end")
    hs.eventtap.keyStroke(mods, "end")
  else
    hs.eventtap.keyStroke("cmd", "right")
  end
end

hs.hotkey.bind("", "home", onHome)
hs.hotkey.bind("", "end", onEnd)


print("** Loaded bindings **")