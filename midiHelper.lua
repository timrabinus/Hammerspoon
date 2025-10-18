require "utils"

--
-- MidiHelper displays a menu of known keyboards and synths and allows you to create connections
-- between them to forward midi commands
--

-- TODO:
--   / Test connection adding and removing
--   / Test midi forwarding for 1 synth and many
--   - Speed up callbacks
--   - Don't clear connections on Midi device change
--   - Test other keyboards (bluetooth and wireless)
--   - Test with KK DAW
--   - Test with Push and Live
--   - Save connection sets?
--   - Test midi control commandTypes
--   - Test with LogicPro and Ableton

print("-- loading midiHelper --")

MH_Title = "􀎏" -- pianokeys
MH_TitleDisabled = "􀟽" -- pianokeys.inverse
MH_Menu = hs.menubar.new()
MH_UsePopupMenu = false
-- MH_Ignore = {}
MH_Ignore = { "Network", "Bluetooth" }
MH_Commands = { "noteOn", "noteOff" }

MH_RecognizedControllerNames = { 
  "Ableton Push 2",
  "Akai LPK25 Wireless",
  "KOMPLETE KONTROL A49",
  "KOMPLETE KONTROL S88", 
  "microKEY2 Air",
  "9./+-Xkey  ",
}
MH_Controllers = {} -- Dict {name:device*}
MH_RecognizedSynthesizerNames = {
  "2600",
  "MODEL D",
  "K-2", 
}
MH_Synthesizers = {} -- Dict {name:device*}
MH_Connections = {}
  -- group {name:{device*}*}
  -- {
  --   "KOMPLETE KONTROL S88" : { K-2, 2600 },
  --   "KOMPLETE KONTROL A49" : { MODEL_D }
  -- }

--
-- Connection Management
--

function toggleConnection(controllerName, synthesizerName)
  if groupContains(MH_Connections, controllerName, synthesizerName) then
    removeConnection(controllerName, synthesizerName)
  else
    addConnection(controllerName, synthesizerName)
  end
end


function addConnection(controllerName, synthesizerName)
  log("  Added connection "..controllerName.." -> "..synthesizerName)

  -- Add callback if this is a new connection
  if not groupContainsKey(MH_Connections, controllerName) then
    local controller = MH_Controllers[controllerName]
    local synthesizer = MH_Synthesizers[synthesizerName]
    if controller ~= nil and synthesizer ~= nil then
      controller:callback(function(sender, deviceName, commandType, description, metadata)
          onMidiEvent(sender, commandType, metadata)
        end)
    else
      print("Could not create callback for connection from "..controllerName.." to "..synthesizerName)
      -- dump(controller, "controller")
      -- dump(synthesizer, "synthesizer")
    end
  end

  -- Add the synth to the controller's connections
  groupAdd(MH_Connections, controllerName, synthesizerName)
end


function removeConnection(controllerName, synthesizerName)
  log("  remove "..synthesizerName.." from "..controllerName)

  local connection = groupContainsKey(MH_Connections,controllerName)
  if connection ~= nil then
    groupRemoveValue(MH_Connections, controllerName, synthesizerName)
    if not groupContainsKey(MH_Connections, controllerName) then
      -- if we removed the last connection for the controller then remove the callback
      -- (most connections will be for a single synth so will usually do this)
      MH_Controllers[controllerName]:callback(nil)
    end
  end
  -- dump(MH_Connections)
end


function resetConnections()
  run(MH_Connections, function(controllerName, _) 
    MH_Controllers[controllerName]:callback(nil)
  end)
  MH_Connections = {}
end


--
-- Connection Processing
--

function onMidiEvent(
  source,       -- The hs.midi device sending the event.
  commandType,  -- Type of MIDI message as defined as a string. See hs.midi.commandTypes[] for a list of possibilities.
  metadata)     -- A table of data for the MIDI command (see below).

  if Debug then
    log("** onMidiEvent "..commandType)
    dump(metadata, "metadata")
  end

  local receivers = MH_Connections[source:name()]
  -- there is only one callback per controller, so send event to all connected synthesizers
  if receivers ~= nil and contains(MH_Commands, commandType) then
    for r = 1,#receivers do
      local synthesizer = MH_Synthesizers[receivers[r]]
      synthesizer:sendCommand(commandType, metadata)
      -- log("  sent to "..synthesizer:name())
    end
  else
    -- log("  not handled")
  end
end


--
-- Device Management
--

-- updateDevices - called when device added/removed
function updateDevices(devices, virtualDevices)
  -- log("*** updateDevices")
  -- log("")
  -- log(hs.inspect(devices),"devices")
  -- log(hs.inspect(virtualDevices), "virtualDevices")
  
  -- seems to be called twice with the set of devices; do nothing if nothing changed
  
  local oldControllers = MH_Controllers
  local oldSynthesizers = MH_Synthesizers
  -- local menuEnabled = false
  MH_Controllers = {}
  MH_Synthesizers = {}

  for d = 1,#devices do
    local deviceName = devices[d]
    -- log("  "..deviceName)
    local device = hs.midi.new(deviceName)
    if device and not contains(MH_Ignore, deviceName) then
          
      if contains(MH_RecognizedControllerNames, deviceName) then
        MH_Controllers[deviceName] = device
        if oldControllers[deviceName] == nil then
          log("Adding controller "..deviceName)
        else
          oldControllers[deviceName] = nil
        end
        
      elseif contains(MH_RecognizedSynthesizerNames, deviceName) then
        MH_Synthesizers[deviceName] = device
        if oldSynthesizers[deviceName] == nil then
          log("Adding synthesizer "..deviceName)
        else
          oldSynthesizers[deviceName] = nil
        end

      else
        log("New device: '"..deviceName.."' ")
      end
    end
  end
  for k,v in pairs(oldControllers) do
    log("Removing controller "..k)
  end
  for k,v in pairs(oldSynthesizers) do
    log("Removing synthesizer "..k)
  end

  -- Update connections
  -- TODO: remove connections for any controllers or synthesizers that dropped
  for controllerName, synthesizerNames in pairs(MH_Connections) do
    if contains(MH_RecognizedControllerNames, controllerName) then
      -- controller exists - remove any synths that don't exist.  
      for s = 1,#synthesizerNames do
        if not contains(MH_RecognizedSynthesizerNames, synthesizerNames[s]) then
          -- Will remove the callback if no synths for the controller
          removeConnection(controllerName, synthesizerName)
        end
      end
    else
      -- controller no longer exists - remove callback and connections
    end
  end

  MH_Menu:setTitle((isEmpty(MH_Controllers) and isEmpty(MH_Synthesizers)) and MH_TitleDisabled or MH_Title)
end


--
-- Menus
--

function getControllerSubMenu(controllerName)
  local menu = {}
  local devices_shown = false
  for name,device in pairs(MH_Synthesizers) do
    table.insert(menu, { 
      title = name, 
      checked=groupContains(MH_Connections, controllerName, name), 
      fn=function(mods,item) toggleConnection(controllerName, item.title) end, 
      disabled=not device:isOnline() })
      devices_shown = true
    end
    if not devices_shown then
      table.insert(menu, { title = "No connected synthesizers", disabled=true })
    end
    if devices_shown then
      table.insert(menu, { title = "-" })
    end
    table.insert(menu, { 
      title = "Show events", 
      checked=groupContains(MH_Connections, controllerName, "/dev/nul"), 
      fn=function(mods,item) toggleConnection(controllerName, "/dev/nul") end, 
    })
    return menu
  end
  
  
function _GetMHMenu()
  local menu = {}
  local pad = ""

  if MH_UsePopupMenu then
    table.insert(menu, { title = MH_Title.." Midi Helper:", disabled=true})
    table.insert(menu, { title = "-" })
    pad = "      "
  end

  local controllers_shown = false
  for name,device in pairs(MH_Controllers) do
    if isEmpty(MH_Synthesizers) then
      table.insert(menu, { title = pad..name, disabled=not device:isOnline() })
    else
      table.insert(menu, { 
        title = pad..name, 
        checked = groupContainsKey(MH_Connections, name),  -- TODO: should check synth is in devices too
        disabled = not device:isOnline(),
        menu = getControllerSubMenu(name) })
      end
      controllers_shown = true
    end
    if not controllers_shown then
      table.insert(menu, { title = pad.."No connected controllers", disabled=true })
    end
    
  table.insert(menu, { title = "-" })
  
  local synthesizers_shown = false
  for name,device in pairs(MH_Synthesizers) do
    -- if synth is in connection, and the controller is connected, check it
    local synthIsConnected = groupContainsValue(MH_Connections, name) and 
      not isEmpty(groupKeysForValue(MH_Connections, name))
    table.insert(menu, { 
      title = pad..name, 
      checked=synthIsConnected, 
      -- fn=function(mods,item) removeSynthesizerConnections(name) end, 
      disabled=not device:isOnline() })
      synthesizers_shown = true
  end
  if not synthesizers_shown then
    table.insert(menu, { title = pad.."No connected synthesizers", disabled=true })
  end
  
  table.insert(menu, { title = "-" })
  table.insert(menu, { 
    title = pad..(isEmpty(MH_Connections) and "No connections" or "Clear Connections"), 
    fn=function(mods,item) resetConnections() end, 
    disabled=isEmpty(MH_Connections),
    shortcut="c" })
    
    MH_Menu:setTitle((isEmpty(MH_Controllers) and isEmpty(MH_Synthesizers)) and MH_TitleDisabled or MH_Title)
    MH_UsePopupMenu = false
  return menu
end

--
-- Initialization
--

bindKey(hyper, "m", "Midi Helper", function()
  MH_UsePopupMenu = true
  local menu = hs.menubar.new():setMenu(_GetMHMenu)
  -- local win = hs.application.frontmostApplication():focusedWindow()
  -- if win then
  local rect = hs.screen.mainScreen():frame()
  menu:popupMenu({x=rect.x+rect.w/2-60,y=rect.y+rect.h/3})
end)

-- updateDevices(hs.midi.devices(), hs.midi.virtualSources())

if MH_Menu then
  MH_Menu
    :setTitle(MH_Title)
    :setMenu(_GetMHMenu)
end

hs.midi.deviceCallback(updateDevices)

print("** Loaded midiHelper **")

---

