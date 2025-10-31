--
-- Display Utilities
--
--

ES_DisplayMode = "􀢹" -- display
ES_ReadingMode = "􀉚" -- book
ES_State       = (hs.caffeinate.get("displayIdle") and ES_ReadingMode or ES_DisplayMode)
ES_MenuLoc     = {}
ES_Menu        = hs.menubar.new()
ES_Menu : setTitle(ES_State)
ES_Brightness = hs.screen.primaryScreen(): getBrightness() or 0.5
ES_TimeFormat = "%I:%M:%S %p"

ES_UsePopupMenu = false


--
-- # Methods
--

function toggleSleep()
  if ES_State == ES_ReadingMode then
    ES_State = ES_DisplayMode
    show("Sleep Enabled")
  else 
    ES_State = ES_ReadingMode
    show("Sleep Disabled")
  end
  ES_Menu:setTitle(ES_State)
  hs.caffeinate.toggle("displayIdle")
end


function sleep()
  hs.caffeinate.systemSleep()
end


-- # Brightness

function changeBrightness(change)
  local screens = hs.screen.allScreens()
  for _, s in pairs(screens) do
    local b = s:getBrightness()
    if b == nil then
      print("Could not set brightness for "..s:name())
      b = ES_Brightness
    end
    b = limit(0.1, b+change, 1)
    s:setBrightness(b)
  end
  ES_Brightness = ES_Brightness+change
end


function decreaseBrightness(mods, item)
  changeBrightness(-0.2)
  reshowESMenu()
end


function increaseBrightness(mods, item)
  changeBrightness(0.2)
  reshowESMenu()
end


function popBrightness(mods, item)
  changeBrightness(1.0)
end


function minBrightness(mods, item)
  changeBrightness(-1.0)
end


function isDarkMode()
  local _, isDark = hs.osascript.javascript(
    'Application("System Events").appearancePreferences.darkMode()'
  )
  return isDark
end


function toggleDarkMode(mods, item)
  local success = hs.osascript.javascript(
    string.format(
      "Application('System Events').appearancePreferences.darkMode.set(%s)",
      ES_DarkMode
    )
  )
  if success then
    show("Setting "..(ES_DarkMode and "Dark" or "Light").." Mode...")
    ES_DarkMode = not ES_DarkMode
  end
end

-- # Resolution

function setResolution(uuid, w, h, scale, frequency, depth)
  local screen = hs.screen(uuid)
  if screen ~= nil then
    screen:setMode(w,h,scale,frequency,depth)
  end
end

-- # Menu Handling

function getESMenu()
  local _menu = {}
  local minipad, pad = addMenuHeader(_menu)
  addScreenResolutionOptions(_menu, pad)
  addModeOptions(_menu, minipad, pad)
  addBrightnessControls(_menu, pad)

  ES_UsePopupMenu = false
  return _menu
end


function reshowESMenu()
  if ES_MenuLoc then
    local myPopupMenu = hs.menubar.new():setMenu(getESMenu())
    myPopupMenu:popupMenu(ES_MenuLoc)  
  end
end


function addMenuHeader(_menu)
  local minipad, pad = "", ""
  if not ES_UsePopupMenu then return minipad, pad end
  minipad, pad = "  ", "      "

  local title = (ES_State == ES_DisplayMode and "Display Mode" or "Reading Mode")
  table.insert(_menu, { title = ES_State.."  "..title..":", disabled=true})
  table.insert(_menu, { title = "-" })
  return minipad, pad
end


function addScreenResolutionOptions(_menu, pad)
  -- table.insert(_menu, { title = "-" })
  
  local i = 1
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a,b) return a:name() < b:name() end)
  
  for _, s in pairs(screens) do
    local subMenu, topMenuItems = getScreenResolutionMenuItems(s, i)
    i = i + #topMenuItems
    table.insert(_menu, { title = pad..asTitleCase(s:name()), menu=subMenu })
    for m = 1, #topMenuItems do
      table.insert(_menu, topMenuItems[m])
    end
    table.insert(_menu, { title = "-" })
  end

end


function getScreenResolutionMenuItems(screen, i)
  local currentMode = screen:currentMode()
  local modeDict = screen:availableModes()
  local subMenu = {}
  local modes, resolutions = {}, {}
  local topMenuItems = {}

  modes = getFilteredResolutions(modeDict)
  modes = getUniqueResolutions(modes)
  resolutions = sortByResolution(modes)

  for d,r in pairs(resolutions) do
    local shortcut = "" 
    -- put double res on top menu also, indented
    if i <= 9 and r.scale == 2.0 then
      shortcut = ""..i
      table.insert(topMenuItems, {
        title = "      "..r.title, 
        shortcut=shortcut, 
        checked=(currentMode.w == r.w and currentMode.h == r.h),
        fn=function(mode,item) setResolution(screen:getUUID(), r.w, r.h, r.scale, r.freq, r.depth) end })
      i = i+1
    end
    -- put all on submenu
    table.insert(subMenu, { 
      title = r.title, 
      checked=(currentMode.w == r.w and currentMode.h == r.h),
      fn=function(mode,item) setResolution(screen:getUUID(), r.w, r.h, r.scale, r.freq, r.depth) end })
    end

  return subMenu, topMenuItems
end

function getUniqueResolutions(modeDict)
  local modes = {}
  for _,m in pairs(modeDict) do
    if m.w >= 1023 and m.h >= 900 
      and not match(modes, function(a) return m.w == a.w and m.h == a.h and m.scale == a.scale end) then
      table.insert(modes,m)
    end
  end
  return modes
end

function getFilteredResolutions(modes)
  local resolutions = {}
  for _,r in pairs(modes) do
    if r.scale ~= 1.0 or not any(modes, function(a) 
        return a.w == r.w and a.h == r.h and a.scale == 2.0
      end) then
      r.title = formatResolutionTitle(r)
      table.insert(resolutions,r)
    end
  end
  -- table.sort(resolutions, function(a,b)
  --   return a.w > b.w or (a.w == b.w and a.h > b.h)
  -- end)
  return resolutions
end

function sortByResolution(resolutions)
  table.sort(resolutions, function(a,b)
    return a.w > b.w or (a.w == b.w and a.h > b.h)
  end)
  return resolutions
end

function formatResolutionTitle(resolution)
  local title = resolution.w.." x "..resolution.h
  if resolution.scale == 2.0 then
    return ES_State.." "..title
  else
    return "      "..title
  end
end

function openDisplayPrefs()
  local url = 'x-apple.systempreferences:com.apple.displays.extension'
  local handler = 'com.apple.systempreferences'
  hs.urlevent.openURLWithBundle(url, handler)
end

function addModeOptions(_menu, minipad, pad)
  local mode = ""
  if ES_UsePopupMenu then 
    mode = (ES_State == ES_DisplayMode and ES_ReadingMode or ES_DisplayMode)..minipad
  end
  if ES_State == ES_DisplayMode then
    table.insert(_menu, { title = mode.."Set to Reading Mode", shortcut=" ", fn=toggleSleep })
  else
    table.insert(_menu, { title = mode.."Set to Display Mode", shortcut=" ", fn=toggleSleep })
  end
  local title = "Set Appearance to "..(ES_DarkMode and "Dark" or "Light")
  table.insert(_menu, { title = pad..title, shortcut="a", fn=toggleDarkMode })
  table.insert(_menu, { title = pad.."Sleep", shortcut="s", fn=sleep })
  table.insert(_menu, { title = "-" })  
end

function addBrightnessControls(_menu, pad)
  table.insert(_menu, { title = pad.."Pop Brightness", shortcut="p", fn=popBrightness })
  table.insert(_menu, { title = pad.."Min Brightness", shortcut="m", fn=minBrightness })
  table.insert(_menu, { title = "-" })
  table.insert(_menu, { title = pad.."Settings", shortcut=",", fn=openDisplayPrefs })

  return _menu
end


function showESMenu()
  ES_UsePopupMenu = true
  local myPopupMenu = hs.menubar.new():setMenu(getESMenu())
  local rect = hs.screen.mainScreen():frame()
  ES_MenuLoc = { x=rect.x+rect.w/2-125, y=rect.y+rect.h/3 }
  myPopupMenu:popupMenu(ES_MenuLoc)
end

-- 
-- # Main
-- 

ES_DarkMode = not isDarkMode()

if ES_Menu then
  ES_Menu
    :setTitle(ES_State)
    :setMenu(getESMenu)
end

bindKey("", "F1", "Screen Sleep", showESMenu)

print("** loaded espresso")