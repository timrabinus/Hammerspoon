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

-- ES_OnIcon    = 1
-- ES_OffIcon   = 2
-- ES_TimerIcons = {
--   [1]  = {"􀀺","􀀻"},
--   [2]  = {"􀀼","􀀽"},
--   [3]  = {"􀀾","􀀿"},
--   [4]  = {"􀁀","􀁁"},
--   [5]  = {"􀁂","􀁃"},
--   [6]  = {"􀁄","􀁅"},
--   [7]  = {"􀁆","􀁇"},
--   [8]  = {"􀁈","􀁉"},
--   [9]  = {"􀁊","􀁋"},
--   [10] = {"􀓵","􀔔"},
--   [15] = {"􀓺","􀔙"},
--   [20] = {"􀓿","􀔞"},
--   [25] = {"􀔄","􀔣"},
--   [30] = {"􀔉","􀔨"},
--   [35] = {"􀚝","􀚞"},
--   [40] = {"􀚧","􀚨"},
--   [45] = {"􀚱","􀚲"},
--   [50] = {"􀚻","􀚼"},
-- }
-- keys: timer, mins, startTime
ES_Timers = {}


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

-- # Timers

-- function removeTimer(timer)
--   timer:stop()
--   local index
--   for t,v in pairs(ES_Timers) do
--     if v.timer == timer then index = t end
--   end
--   if index then
--     table.remove(ES_Timers, index)
--   end
-- end


-- function timerEndAction(label, timerInfo)
--   if label == "OK" then 
--     removeTimer(timerInfo.timer)
--   else
--     log("Timer repeated")
--     timerInfo.timer:start()
--     timerInfo.repeatTime = os.time()
--     timerInfo.endTime    = timerInfo.repeatTime+timerInfo.mins*60
--     timerInfo.isEnded    = false
--     table.sort(ES_Timers, function(a,b) return a.endTime < b.endTime end)
--   end
-- end


-- function timerEditAction(label, timerInfo)
--   if label == "Stop" then 
--     removeTimer(timerInfo.timer)
--   end
-- end


-- function timerEnded(timerInfo)
--   timerInfo.timer:stop()
--   timerInfo.isEnded = true
--   hs.sound.getByName("Blow"):volume(1):play()
--   local frame = hs.screen.mainScreen():frame()
--   local x,y = frame.x+frame.w//2, frame.y+frame.h//3
--   -- x,y = 100,100
--   hs.dialog.alert(
--     x,y, 
--     function(label) timerEndAction(label, timerInfo) end, 
--     "Timer Finished", 
--     "Your "..timerInfo.mins.." minute timer completed", 
--     "OK", "Repeat",
--     "informational")
-- end


-- function showTimer(timerInfo)
--   local frame = hs.screen.mainScreen():frame()
--   local x,y = frame.x+frame.w//2, frame.y+frame.h//3
--   local repeatPrompt = ""
--   -- x,y = 100,100
--   if timerInfo.repeatTime then 
--     repeatPrompt = "\nRestarted at "..os.date(ES_TimeFormat,timerInfo.repeatTime)
--   end

--   hs.dialog.alert(
--     x,y, 
--     function(label) timerEditAction(label, timerInfo) end, 
--     timerInfo.mins.." Minute Timer", 
--     "Timer originally started at "..os.date(ES_TimeFormat,timerInfo.startTime)..repeatPrompt,
--     "OK", "Stop",
--     "informational")
-- end


-- function addTimer(mins)
--   local now=os.time()
--   local endTime=now+mins*60
--   log("Started "..mins.." minute timer at "..os.date(ES_TimeFormat,now)..". Will finish: "..os.date(ES_TimeFormat,endTime))
--   local timer, timerInfo
--   timerInfo = {mins=mins, startTime=now, endTime=endTime, isEnded=false }
--   timerInfo.timer = hs.timer.new(mins*60, function() timerEnded(timerInfo) end)
--   table.insert(ES_Timers, timerInfo)
--   table.sort(ES_Timers, function(a,b) return a.endTime < b.endTime end)
--   timerInfo.timer:start()
-- end


-- # Menu Handling

function getESMenu()
  local _menu = {}
  local minipad, pad = addMenuHeader(_menu)
  addScreenResolutionOptions(_menu, pad)
  addModeOptions(_menu, minipad, pad)
  -- addTimerOptions(_menu, minipad, pad)
  -- addActiveTimers(_menu, minipad)
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
    local subMenu = getScreenResolutionSubmenu(s, i)
    table.insert(_menu, { title = pad..asTitleCase(s:name()), menu=subMenu })
    i = i + #subMenu
  end
  
  table.insert(_menu, { title = "-" })
end


function getScreenResolutionSubmenu(screen, i)
  local currentMode = screen:currentMode()
  local modeDict = screen:availableModes()
  local subMenu = {}
  local modes, resolutions = {}, {}

  modes = getUniqueSortedModes(modeDict)
  resolutions = getFilteredResolutions(modes)

  for d,r in pairs(resolutions) do
    local shortcut = "" 
    if i <= 9 and r.scale == 2.0 then
      shortcut = ""..i
      i = i+1
    end
    table.insert(subMenu, { 
      title = r.title, 
      checked=(currentMode.w == r.w and currentMode.h == r.h),
      fn=function(mode,item) setResolution(screen:getUUID(), r.w, r.h, r.scale, r.freq, r.depth) end })
  end

  return subMenu
end

function getUniqueSortedModes(modeDict)
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

-- function addTimerOptions(_menu, minipad, pad)
--   local timerMenu = createTimerMenu(minipad)
--   local prompt = (#ES_Timers > 0 and "Timers:" or "Add Timer")
--   table.insert(_menu, { title = pad..prompt, shortcut="a", menu=timerMenu })
-- end

-- function createTimerMenu(pad)
--   local timerMenu = {}
--   local insertTimerMenu = function(mins, shortcut)
--     table.insert(timerMenu, { 
--       title    = ES_TimerIcons[mins][ES_OnIcon]..pad..mins.." Minute"..(mins > 1 and "s" or ""),
--       shortcut = shortcut,
--       fn       = function(_,_) addTimer(mins) end })
--     end

--   for t = 1,9 do insertTimerMenu(t, t.."") end
--   insertTimerMenu(10, "0") 
--   for t = 15,50,5 do insertTimerMenu(t, "") end

--   return timerMenu
-- end

-- function addActiveTimers(_menu, minipad)
--   if #ES_Timers > 0 then
--     table.insert(_menu, { title = "-" })
--     for t,v in pairs(ES_Timers) do
--       local title, disabled = "", true
--       if v.isEnded then
--         title = "􁙆"..minipad.."  "..v.mins.." minute timer finished at "..os.date(ES_TimeFormat,v.endTime)
--       else
--         title = "􀐱"..minipad.." "..os.date(ES_TimeFormat,v.endTime).." - "..v.mins.." minute timer started "..os.date(ES_TimeFormat,v.startTime)
--         disabled = false
--       end
--       table.insert(_menu, { title = title, fn=function(_,_) showTimer(v) end, disabled=disabled })
--     end
--   end
-- end

function addBrightnessControls(_menu, pad)
  table.insert(_menu, { title = pad.."Pop Brightness", shortcut="p", fn=popBrightness })
  table.insert(_menu, { title = pad.."Min Brightness", shortcut="m", fn=minBrightness })
  -- table.insert(_menu, { title = pad.."Decrease Brightness", shortcut="-", fn=decreaseBrightness })
  -- table.insert(_menu, { title = pad.."Increase Brightness", shortcut="=", fn=increaseBrightness })
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