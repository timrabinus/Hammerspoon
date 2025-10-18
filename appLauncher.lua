--
-- Utility to launch applications with fn keys
--

require "utils"

AL_LastApp    = nil
AL_appKeyHeld = false
AL_appKeyDown = false

-- SOUND_UP
-- SOUND_DOWN
-- MUTE
-- BRIGHTNESS_UP
-- BRIGHTNESS_DOWN
-- CONTRAST_UP
-- CONTRAST_DOWN
-- POWER
-- LAUNCH_PANEL
-- VIDMIRROR
-- PLAY
-- EJECT
-- NEXT
-- PREVIOUS
-- FAST
-- REWIND
-- ILLUMINATION_UP
-- ILLUMINATION_DOWN
-- ILLUMINATION_TOGGLE -- doesn't seem to work
-- CAPS_LOCK
-- HELP
-- NUM_LOCK

AL_Apps = {
  { key="f2",  launch='app', app="Safari",              altApp="Firefox",             fn="BRIGHTNESS_UP"},
  { key="f3",  launch='app', app="Mail",                altApp="Warp",                fn="LAUNCH_PANEL"},
  { key="f4",  launch='app', app="Messages",            altApp="Discord",             fn="HELP"},
  { key="f5",  launch='app', app="Calendar",            altApp="Contacts",            fn="ILLUMINATION_DOWN"},
  { key="f6",  launch='app', app="Music",               altApp="Photos",              fn="ILLUMINATION_UP"},
  { key="f7",  launch='app', app="Craft",               altApp="Photos",              fn="PREVIOUS"},
  { key="f8",  launch='app', app="ChatGPT",             altApp="Hammerspoon",         fn="PLAY"},
  { key="f9",  launch='app', app="Cursor",              altApp="Visual Studio Code",  fn="NEXT"},
  { key="f10", launch='fn',  app="",  fn="MUTE",        altApp="",                    fn2="ILLUMINATION_TOGGLE"},
  { key="f11", launch='fn',  app="",  fn="SOUND_DOWN",  altApp="",                    fn2="ILLUMINATION_DOWN"},
  { key="f12", launch='fn',  app="",  fn="SOUND_UP",    altApp="",                    fn2="ILLUMINATION_UP"},
}


function appKeyHeld()
  if AL_appKeyDown then
    AL_appKeyHeld = true
    local currentAppTitle = getCurrentAppTitle()
    if AL_LastApp ~= currentAppTitle then
      hs.sound.getByName("Tink"):volume(0.1):play()
      show("􀚂  Returning to "..AL_LastApp.."...")
    end
  end
end
AL_appKeyTimer = hs.timer.delayed.new(0.7, appKeyHeld)



function getCurrentAppTitle()
  local currentAppTitle = hs.application.frontmostApplication():title()
  -- for some reason Code is not the name used to launch
  if currentAppTitle == "Code" then currentAppTitle = "Visual Studio Code" end
  return currentAppTitle
end


function appKeyDown(config)
  -- print("appKeyDown "..config.key)
  if config.launch=='app' then
    AL_appKeyDown = true
    -- AL_appKeyTimer:start()
  
    local currentAppTitle = getCurrentAppTitle()
    local targetAppTitle = config.app
    if shiftDown() then
      targetAppTitle = config.altApp
    end
    -- log(currentAppTitle.." > "..targetAppTitle)
    if currentAppTitle == targetAppTitle then
      -- Multiple App Keys rotate through windows
      hs.eventtap.event.newKeyEvent({ "option" }, "tab", true):post()
      hs.eventtap.event.newKeyEvent({ "option" }, "tab", false):post()

    else
        hs.application.launchOrFocus(targetAppTitle)
    end
    AL_LastApp = getCurrentAppTitle()

  else -- config.launch == "fn"
    -- log(config.fn)
    hs.eventtap.event.newSystemKeyEvent(config.fn, true):post()
    hs.eventtap.event.newSystemKeyEvent(config.fn, false):post()
  end
end


function appKeyUp(config)
	AL_appKeyTimer:stop()
  -- print("appKeyUp "..config.key)
	if AL_appKeyHeld == true then
    local currentAppTitle = getCurrentAppTitle()
    if currentAppTitle == config.app and AL_LastApp then 
      hs.application.launchOrFocus(AL_LastApp) 
    end
		AL_appKeyHeld = false
	end
  AL_appKeyDown = false
end


function fnKeyDown(config)
  -- log(config.key)
  local currentApp = hs.application.frontmostApplication()
  hs.eventtap.event.newKeyEvent({}, config.key, true):post(currentApp)
  hs.eventtap.event.newKeyEvent({}, config.key, false):post(currentApp)
end


function systemKeyDown(config)
  local event = config.launch == "app" and config.fn or config.fn2
  log(event)
  hs.eventtap.event.newSystemKeyEvent(event, true):post()
  hs.eventtap.event.newSystemKeyEvent(event, false):post()
end


for _, config in ipairs(AL_Apps) do
  bindKey("", config.key, "Launch "..config.app, 
    function() appKeyDown(config) end,
    function() appKeyUp(config) end
  )
  bindKey("shift", config.key, "Launch "..config.altApp, 
    function() appKeyDown(config, true) end,
    function() appKeyUp(config) end
  )

  bindKey(hyper, config.key, "Key "..config.key, function() fnKeyDown(config) end)
  
  bindKey("ctrl", config.key, "System Key "..config.fn, function() systemKeyDown(config) end)
  bindKey("option", config.key, "System Key "..config.fn, function() systemKeyDown(config) end)
  bindKey("cmd", config.key, "System Key "..config.fn, function() systemKeyDown(config) end)
end


-- Submarine √
-- Ping
-- Purr 
-- Hero
-- Funk
-- Pop √
-- Bassomimimi
-- Sosumi  
-- Glass
-- Blow ?
-- Bottle √
-- Frog
-- Tink
-- Morse 

-- for _, sound in ipairs(hs.sound.systemSounds()) do
--   log(sound)
--   local s = ""
--   hs.sound.getByName(sound):volume(0.3):play()
--   for i = 1,100000 do
--     s = s.." "
--   end
-- end

print("** Loaded appLauncher **")

---

