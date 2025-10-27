require "hs.fnutils"

UP_ProfilingOffTitle = "􀟀" -- ruler
UP_ProfilingOnTitle = "􀟁" -- ruler.fill
UP_Title = UP_ProfilingOffTitle
UP_FileRoot = "~/UserProfiles/"
UP_File = nil
UP_FilePath = nil
UP_Menu = hs.menubar.new()
UP_UsePopupMenu = false
UP_ProfilerIsRunning = false
UP_Profiler = nil
UP_AppTime = {}  -- { app : { totalTime, windows : { windowTitle : {totalTime, startTime} } }
UP_Profile = {}  -- { time, app, win }
UP_ProfileStart = nil
UP_Slice = 5
UP_IgnoredApps = {"loginwindow", "ScreenSaverEngine"}

-- TO DOs
-- - Detailed logging?
-- - Skip login window-- - Export profile to CSV
-- - markers

function recordActiveAppAndWindow()
  -- Get the current active application and window
  local app = hs.application.frontmostApplication()
  local appName = app and app:name() or '?'

  if not contains(UP_IgnoredApps, appName) then
    local window = app:focusedWindow()
    local windowTitle = window and window:title() or '?'
    -- print(appName..' -> '..windowTitle)
    
    -- Log the app and window information
    if not UP_AppTime[appName] then
      UP_AppTime[appName] = {totalTime = 0, windows = {}}
    end

    if not UP_AppTime[appName].windows[windowTitle] then
      UP_AppTime[appName].windows[windowTitle] = { totalTime = 0, startTime = os.date("%H:%M:%S") }
    end

    UP_AppTime[appName].totalTime = UP_AppTime[appName].totalTime + UP_Slice
    UP_AppTime[appName].windows[windowTitle].totalTime = UP_AppTime[appName].windows[windowTitle].totalTime + UP_Slice

    local csvLine = string.format("%s,%s,%s\n", os.date("%H:%M:%S"), appName, windowTitle)
    local file = io.open(UP_FilePath, "a")
    if file then
      file:write(csvLine)
      file:close()
    end
  end

end


function _StartProfiler()
  print("Started profiler")
  UP_ProfilerIsRunning = true
  UP_ProfileStart = os.date("%H:%M:%S")
  if UP_Profiler then UP_Profiler:stop() end

  UP_Menu:setTitle(UP_ProfilingOnTitle)
  if UP_FilePath == nil then
    UP_File = "Profile_"..os.date("%Y-%m-%d-%H%M%S")..".csv"
    UP_FilePath = UP_FileRoot..UP_File
    local file = io.open(UP_FilePath, "a")
    if file then
      file:write("Start Time,Application,Window\n")
      file:close()
    end
  end

  recordActiveAppAndWindow()
  UP_Profiler = hs.timer.doEvery(UP_Slice, recordActiveAppAndWindow)
end


function _StopProfiler()
  print("Stopped profiler")
  UP_ProfilerIsRunning = false
  UP_Menu:setTitle(UP_ProfilingOffTitle)
  dump(UP_AppTime)
  if UP_Profiler then UP_Profiler:stop() end
end


function _ResetProfiler()
  UP_AppTime = {}
  UP_Profile = {}
  UP_ProfileStart = nil
  UP_FilePath = nil
end


function sort(dict, fn)
  local array = {}
  for k,v in pairs(dict) do table.insert(array, kv) end
  dump(array)
  table.sort(array, fn)
  return array
end


function sortedPairs (t, f)
  local a = {}
  for k in pairs(t) do table.insert(a, k) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end 


function _GetUPMenu()
  local menu = {}
  local pad = ""
  local sortByStart = shiftDown()
  
  if UP_UsePopupMenu then
    table.insert(menu, { title = UP_Title.." Profile Usage:", disabled=true})
    table.insert(menu, { title = "-" })
    pad = "     "
  end

  if UP_ProfilerIsRunning then
    table.insert(menu, { title = pad.."Stop Profiler", fn=function() _StopProfiler() end, shortcut="s" })
    table.insert(menu, { title = pad..UP_File, disabled=true })
    -- table.insert(menu, { title = pad.."􀈄 "..UP_File, disabled=true })

  else
    table.insert(menu, { title = pad.."Start Profiler", fn=function() _StartProfiler() end, shortcut="s" })
  end

  if next(UP_AppTime) then
    table.insert(menu, { title = "-" })
    
    for appName, appData in sortedPairs(
          UP_AppTime, 
          function(a1, a2) return UP_AppTime[a1].totalTime > UP_AppTime[a2].totalTime end) do
      local appMenu = {} 
      local winSort = function(w1, w2) return appData.windows[w1].totalTime > appData.windows[w2].totalTime end
      if sortByStart then
        winSort = function(w1, w2) return appData.windows[w1].startTime > appData.windows[w2].startTime end
      end
      for winName, winData in sortedPairs( appData.windows, winSort) do
        if sortByStart then
          table.insert(appMenu, { title = pad..winData.startTime.."\t\t"..winName.." ("..winData.totalTime.."s)"})
        else
          table.insert(appMenu, { title = pad..winData.totalTime.."s\t"..winName})
        end
      end
      table.insert(menu, { title = pad..appData.totalTime.."s\t"..appName, menu = appMenu })
    end
    
    table.insert(menu, { title = "-" })
    table.insert(menu, { title = pad.."Reset Profiler", fn=function() _ResetProfiler() end, shortcut="r" })
  end

  UP_UsePopupMenu = false
  return menu
end

showUPMenu = function()
  UP_UsePopupMenu = true
  local menu = hs.menubar.new():setMenu(_GetUPMenu)
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    menu:popupMenu({x=rect.x+rect.w/2-60,y=rect.y+rect.h/4})
  else
    menu:popupMenu(hs.mouse.absolutePosition())
  end
end

bindKey(hyper, "p", "Profile Usage", showUPMenu)
bindKey(shyper, "p", "Profile Usage (from Start Time)", showUPMenu)

if UP_Menu then
  UP_Menu
    :setTitle(UP_Title)
    :setMenu(_GetUPMenu)
end

print("** Loaded userProfile **")
