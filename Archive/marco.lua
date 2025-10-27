------
-- Marco

require "utils"

----

menuTitle = "􀢙"
macro, oldMacro = {}, {}
recordHotKey = nil
stopHotKey = nil
keyWatchers = {}

function onRecordMacro()
  print("-- onRecordMacro")
  recording = true
  local _alert = show("Recording",300)
  setUpRecording()
  hs.timer.waitWhile(marcoRecording, function() 
    hs.alert.closeSpecific(_alert,.75)
    recording = false
  end)
end

function setUpRecording()
  print("-- setUpRecording")
  menuToggler = hs.timer.doEvery(1,toggleMenuTitle)
  oldMacro = macro
  macro = {}
  marcoMenu:setMenu(getMarcoMenu())
  recordHotKey:disable()
  stopHotKey:enable()
  local mods = {"","cmd","ctrl","alt","shift","cmd+shift","ctrl+shift","alt+shift"}
  for key in pairs(hs.keycodes.map) do
    for _,mod in pairs(mods) do
      _watcher = hs.hotkey.bind(mod, key, nil, function() recordPress(mod, key) end)
      keyWatchers[mod..key] = _watcher
    end
  end
end

function recordPress(mod, key)
  if key == "escape" then
    onEscapeRecordingMacro()
  else
    table.insert(macro, {mods=mod, key=key})
    show(key)
  end
end

function marcoRecording() 
  return recording
end

function onEscapeRecordingMacro()
  print("-- onEscapeRecordingMacro")
  show("Cancelled")
  stopRecording()
  macro = oldMacro
end

function onStopRecordingMacro()
  print("-- onStopRecordingMacro")
  show("Stopped Recording")
  stopRecording()
end

function stopRecording()
  recording = false
  menuToggler:stop()
  marcoMenu:setTitle("􀢙")
  marcoMenu:setMenu(getMarcoMenu())
  for k,watcher in pairs(keyWatchers) do
    watcher:delete()
  end
  keyWatchers = {}
  stopHotKey:disable()
  recordHotKey:enable()
end

function onExecMacro()
  print("-- onExecMacro")
  if recording then
    onStopRecordingMacro()
  end

  for i = 1,#macro do
    hs.eventtap.keyStroke(macro[i].mods, macro[i].key, 20*1000)
  end
end

function toggleMenuTitle()
  print("toggle")
  if menuTitle == "􀢙" then
    menuTitle = hs.styledtext.new("􀢙", { color = { red = 1, blue = 0, green = 0 }})
  else
    menuTitle = "􀢙"
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

recordHotKey = bindKey(hyper, "r", "Record macro", onRecordMacro)
stopHotKey = bindKey(hyper, "r", "Stop recording", onStopRecordingMacro):disable()
bindKey(hyper, "e", "Execute macro", onExecMacro)

marcoMenu = hs.menubar.new()
marcoMenu:setMenu(getMarcoMenu())
marcoMenu:setTitle(menuTitle)

print("** Loaded marco **")