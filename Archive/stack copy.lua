------
-- Marco

require "utils"

----

menuTitle = "􀢙"
macro = {}
recordHotKey = nil
stopHotKey = nil
keyWatchers = {}

function onRecordMacro()
  recording = true
  local _alert = show("Recording",300)
  setUpRecording()
  hs.timer.waitWhile(marcoRecording, function() 
    hs.alert.closeSpecific(_alert,.75)
    recording = false
  end)
end

function setUpRecording()
  menuToggler = hs.timer.doEvery(1,toggleMenuTitle)
  macro = {}
  marcoMenu:setMenu(getMarcoMenu())
  recordHotKey:disable()
  stopHotKey:enable()
  for key in pairs(hs.keycodes.map) do
    _watcher = hs.hotkey.bind("", key, nil, 
      function() recordPress(key) end, 
      function() recordRelease(key) end, 
      function() recordRepeat(key) end)
    table.insert(keyWatchers, _watcher)
  end
end

function recordPress(key)
  show(key)
  mods = ""
  table.insert(macro, {mods=mods, key=key})
end

function recordRelease(key)
  show(key)
end

function recordRepeat(key)
  show(key)
end

function marcoRecording()
  return recording
end

function onStopRecordingMacro()
  show("Stopped")
  recording = false
  menuToggler:stop()
  marcoMenu:setTitle("􀢙")
  marcoMenu:setMenu(getMarcoMenu())
  for i,w in ipairs(keyWatchers) do
    w:delete()
  end
  stopHotKey:disable()
  recordHotKey:enable()
end


function onExecMacro()
  if recording then
    onStopRecordingMacro()
  end

  local str = ""
  for i = 1,#macro do
    -- should: playback key
    str = str..macro[i].key
  end
  show(str)
end

function toggleMenuTitle()
	local flash1 = hs.styledtext.new("􀢚", { color = { red = 1, blue = 0, green = 0 }}	)
	local flash2 = hs.styledtext.new("􀢙", { color = { red = 1, blue = 0, green = 0 }}	)
  if menuTitle == flash1 then
    menuTitle = flash2
  else
    menuTitle = flash1
  end
  marcoMenu:setTitle(menuTitle)
end

function getMarcoMenu()
  local mtable = {}

  if recording then
    table.insert(mtable, { title = "Stop Recording", fn=onStopRecordingMacro, shortcut='r'})
  else
    table.insert(mtable, { title = "Record macro", fn=onRecordMacro, shortcut='r'})
  end
  table.insert(mtable, { title = "Exec Macro", fn=onExecMacro, disabled=(#macro==0), shortcut='e'})

  return mtable
end

-- recordHotKey = bindKey(hyper, "r", "Record macro", onRecordMacro)
-- stopHotKey = bindKey(hyper, "r", "Stop recording", onStopRecordingMacro):disable()
-- bindKey(hyper, "e", "Execute macro", onExecMacro)

marcoMenu = hs.menubar.new()
marcoMenu:setMenu(getMarcoMenu())
marcoMenu:setTitle(menuTitle)

print("** Loaded marco **")