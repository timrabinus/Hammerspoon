------
-- Window Layout

-- To Do:
--   Make into a spoon
      -- Standalone file
      -- Package icon for menubar
      -- Remove print
-- Upload to github
-- Medium article?
 
require "utils"

lm_All = "All Displays"
lm_Title = "􀏝" -- uiwindow.split.2x1
lm_FullImgSize = 512
lm_ImgSize = 96
 
winstar = hs.menubar.new()
selectedLayout = ""
layoutMode = lm_All
winstar:setTitle(lm_Title) 
layouts = {}  -- {name, snapshot, windows, appIDs, frontWindow }
usePopupMenu = nil

----

wsAppKey="mb_settings_winstar"
wsTableKey="layouts"

----

function recordLayout(_name, _snapshot)
  print("recordLayout")
  if not _snapshot then 
    _snapshot = hs.screen.mainScreen():snapshot():setSize({h=lm_FullImgSize,w=lm_FullImgSize}):encodeAsURLString()
  end

  local _windows = {}
  local _orderedWindows = hs.window.orderedWindows()  -- top to bottom
  local _appIDs = inject({}, visibleWindows, function(appIDs, w)
    if not hs.fnutils.contains(appIDs, w:application():bundleID()) then 
      table.insert(appIDs,w:application():bundleID())
    end
    return appIDs
  end)
  print("found "..#_appIDs.." visible apps")

  
  for w = 1,#_orderedWindows do
    local _win=_orderedWindows[w]
    local _app = win:application()
    local _frame = win:frame()
    local _unitFrame = win:screen():toUnitRect(win:frame())
    
    local lw = {
      app=_app:name(), 
      title=_win:title(),
      screen=_win:screen():name(),
      x=_frame.x, y=_frame.y, w=_frame.w, h=_frame.h,
      ux=_unitFrame.x, uy=_unitFrame.y, uw=_unitFrame.w, uh=_unitFrame.h,
    }
    table.insert(_windows,lw)
  end

  return {
    name=_name, 
    snapshot=_snapshot, 
    windows=_windows,
    appIDs=_appIDs,
    frontWindow=hs.window.frontmostWindow():title()
   }
end

function newLayout(_name, _snapshot)
  print("newLayout")
  local layout = recordLayout(_name, _snapshot)
  table.insert(layouts,layout)

  table.sort(layouts, function(l1,l2) return string.upper(l1.name) < string.upper(l2.name) end)
  saveSettings(wsAppKey,wsTableKey,layouts)
end 

function onRecordNewLayout()
  print("\n ----------------- onRecordNewLayout -----------------")
  local _snapshot = hs.screen.mainScreen():snapshot():setSize({h=lm_ImgSize,w=lm_ImgSize}):encodeAsURLString()

  hs.focus()
  local btn,_name = hs.dialog.textPrompt(
    "",
    "Name this layout:", 
    "Layout "..#layouts+1, 
    "OK", "Cancel")
  if btn=="Cancel" or _name=="" then 
    return 
  end
  
  local existing,_ = getLayout(_name)
  if existing then
    btn = hs.dialog.blockAlert("Update existing layout?",_name.." has already been defined","OK","Cancel")
    if btn=="Cancel" then
      return 
    end
    removeLayoutNamed(_name)
  end
  
  newLayout(_name, _snapshot)
  updateWSMenu(_name)
end

function getLayout(_name)
  for l = 1,#layouts do
    if layouts[l].name == _name then
      return layouts[l],l
    end
  end
  
  return nil,nil
end

function selectScreen(_screenName,screens,w)
  local newScreen
  if layoutMode == lm_All then
    newScreen = _screenName

  elseif layoutMode == "Swap Displays" then
    if _screenName == screens[1]:name() then
      newScreen = screens[2]:name()
    else
      newScreen = screens[1]:name()
    end

  else
    newScreen = layoutMode
  end

  -- prefer original window position if on same screen, else move to same unitFrame on other screen
  local unitRect,frameRect = nil,nil
  if newScreen == w.screen then
    frameRect = hs.geometry.rect(w.x, w.y, w.w, w.h)
  else
    unitRect = hs.geometry.rect(w.ux, w.uy, w.uw, w.uh)
  end

  return newScreen,unitRect,frameRect
end


function collectWindows(layoutName)
  print("collectWindows")
  local screenWindows = hs.window.allWindows()
  local wMap = {}
  local _layout = getLayout(layoutName)
  
  -- go through windows on the screen and match with windows in layout (if there)
  log("GOING THROUGH EXISTING WINDOWS")
  for _,sw in ipairs(screenWindows) do
    local _stitle,_sapp = sw:title(),sw:application():name()
    local _,lw = match(_layout.windows, function(_lw) 
      return _lw.title == _stitle and _lw.app == _sapp 
    end)
    if lw then
      log("  MATCHED { sWindow=".._stitle..", lWindow="..(lw and get(lw.title, "nil title") or "nil"))
    end
    table.insert(wMap,{sWindow=sw,lWindow=lw}) -- lw may be nil
  end

  -- go through windows in the layout that are unmatched and note them
  log("GOING THROUGH LAYOUT WINDOWS")
  for _,lw in ipairs(_layout.windows) do
    local _,sw = match(wMap, function(_map) 
      return _map.lWindow == lw 
    end)
    if not sw then
      log("  LAYOUT { sWindow=nil, lWindow='"..lw.title.."' lApp="..lw.app)
      table.insert(wMap,{sWindow=nil,lWindow=lw})
    end
  end

  return wMap
end

function layoutWindow(wMap, screens, newLayout, mods)
  local sw,lw = wMap.sWindow, wMap.lWindow
  
  if lw then

    if sw then
      print("A SIZE sw { sw="..sw:application():name().." : '"..sw:title().."', lw="..lw.title.." }")
      if sw:isMinimized() then
        sw:unminimize()
      end
      local selectedScreen,unitRect,frameRect = selectScreen(lw.screen,screens,lw)
      local winPos = {
          lw.app,
          lw.title,
          selectedScreen,
          unitRect, 
          frameRect, 
          nil
        }
      newLayout[#newLayout+1] = winPos

    else
      if lw.app == "Finder" and lw.title == "" then
        -- There is a single unnamed finder window for some reason -- do nothing
        print("B IGNORING sw { sw=nil, lw="..lw.app.." : "..lw.title.." }")
      else
        print("B OPEN & SIZE sw { sw=nil, lw="..lw.app.." : "..lw.title.." }")
        hs.application.launchOrFocus(lw.app)
        local selectedScreen,unitRect,frameRect = selectScreen(lw.screen,screens,lw)
        local winPos = {
          lw.app,
          nil, -- we couldn't match by title, so size all the app windows
          selectedScreen,
          unitRect, 
          frameRect, 
          nil
        }
        newLayout[#newLayout+1] = winPos
      end
    end
  else

    if sw then
      print("C MINIMIZE sw { sw="..sw:application():name().." : '"..sw:title().."', lw=nil }")
      if not mods["shift"] then 
        sw:minimize()
      end
  
    else
      print("D HUH? sw { sw=nil, lw=nil }")
      -- shouldnt happen
  
    end
  end

  return newLayout
end

function rehideApps(selectedLayout)
  print("rehideApps")
  local wins = hs.window.visibleWindows()
  -- show/hide current apps
  for w = 1,#wins do
    local win = wins[w]
    local app = win:application()
    local appID = app:bundleID()
    local appVisible = hs.fnutils.find(selectedLayout.appIDs, function(a) 
      return a == appID
    end)
    if appVisible then 
      print("showing "..app:name())
      app:unhide()
    else
      print("hiding "..app:name())
      app:hide() 
    end
  end

  -- show/hide apps in the layout
  for a = 1,#selectedLayout.appIDs do
    local app = hs.application.find(selectedLayout.appIDs[a])
    if app then
      if not app:isRunning() then
        hs.application.launchOrFocus(selectedLayout.appIDs[a])
      end
      if app:isHidden() then 
        print("showing "..app:name())
        app:unhide()
      end
    end
  end

  hs.window.find(selectedLayout.frontWindow):focus():raise()

end


function selectLayoutNamed(layoutName)
  print("-- selectLayoutNamed '"..layoutName.."' on "..layoutMode)
  
    local mods = hs.eventtap.checkKeyboardModifiers()
    if mods["alt"] then
      show("Overlaying layout...")
    else
      local selectedLayout,_= getLayout(layoutName)
      rehideApps(selectedLayout)
    end
  
  local screens = hs.screen.allScreens()
  local newLayout = {}

  local windowMap = collectWindows(layoutName)

  for i,wMap in ipairs(windowMap) do
    newLayout=layoutWindow(wMap,screens,newLayout, mods)
  end

  hs.layout.apply(newLayout)
end

function onSelectLayout(mods,item)
  print("\n ----------------- onSelectLayout -----------------")
  selectLayoutNamed(item.title)
  updateWSMenu(item.title)
end

function removeLayoutNamed(name)
  local l,i = getLayout(name)
  if l then
    clearSettings(wsAppKey,wsTableKey,layouts)
    table.remove(layouts,i)
    if name == selectedLayout then
      selectedLayout = ""
    end
    saveSettings(wsAppKey,wsTableKey,layouts)
  end
end

function onRemoveLayout(mods,item)
  print("\n ----------------- onRemoveLayout -----------------")
  removeLayoutNamed(item.title)
  updateWSMenu(selectedLayout)
end

function onRemoveAllLayouts(mods,item)
  print("\n ----------------- onRemoveAllLayouts -----------------")
  clearSettings(wsAppKey,wsTableKey,layouts)
  layouts={}
  selectedLayout=""
  updateWSMenu(selectedLayout)
end


function onUpdateLayout(mods,item)
  print("\n ----------------- onUpdateLayout -----------------")
  local layoutName = selectedLayout
  removeLayoutNamed(layoutName)
  newLayout(layoutName)
  show("Updated "..layoutName)
  updateWSMenu(layoutName)
end

function onArrangeLayout(mods,item)
  print("\n ----------------- onArrangeLayout -----------------")
  if layoutMode == "Swap Displays" then
    layoutMode = lm_All
  else
    layoutMode = item.title
  end
  selectLayoutNamed(selectedLayout)
  updateWSMenu()
end

--

function getRemoveMenu()
  local mtable = {}
  for l = 1,#layouts do
    table.insert(mtable,getMenuItem(layouts[l].name,onRemoveLayout))
  end
  return mtable
end

function getArrangeMenu(screens)
  local mtable = {}
  table.insert(mtable,getMenuItem(lm_All,onArrangeLayout,layoutMode==lm_All))
  table.insert(mtable, { title = "-" })
  for s = 1,#screens do
    table.insert(mtable,getMenuItem(screens[s]:name(),onArrangeLayout,layoutMode==screens[s]:name()))
  end
  if #screens == 2 then --! TODO: have not tested with 3 screens
    table.insert(mtable, { title = "-" })
    table.insert(mtable,getMenuItem('Swap Displays',onArrangeLayout,layoutMode=='Swap Displays'))
  end
  return mtable
end

function getWSMenu()
  local mods = hs.eventtap.checkKeyboardModifiers()
  local showOptions = mods["alt"] and not mods["cmd"] and not mods["ctrl"]

  local screens = hs.screen.allScreens()

  mtable = {}

  if #layouts > 0 and usePopupMenu then
    table.insert(mtable, { title = "Window Layouts:", disabled=true})
    table.insert(mtable, { title = "-" })
  end

  for l = 1,#layouts do
    local layout=layouts[l]
    local name = showOptions and "Overlay "..layout.name or layout.name
    table.insert(mtable,getMenuItem(
      name,
      onSelectLayout,
      layout.name == selectedLayout,
      nil,
      hs.image.imageFromURL(layout.snapshot):setSize({h=lm_ImgSize,w=lm_ImgSize}),
      nil,
      l<10 and ""..l or ""))

  end
  table.insert(mtable, { title = "-" })
  table.insert(mtable, { title = "Record New Layout...", fn=onRecordNewLayout, shortcut='r'})

  if #layouts>0 and not usePopupMenu then
    table.insert(mtable, { title="Update "..selectedLayout, fn=onUpdateLayout, disabled=(selectedLayout == ""), shortcut='u' })
    table.insert(mtable, { title = "-" })
    table.insert(mtable, { title = (#screens==1) and "Arrange" or "Arrange On",  menu=getArrangeMenu(screens), disabled=(#screens==1)})
    table.insert(mtable, { title = "-" })
    if showOptions then
      table.insert(mtable, { title = "Delete All Layouts", fn=onRemoveAllLayouts })
    else
      table.insert(mtable, { title = "Delete", menu=getRemoveMenu() })
    end
  end
  usePopupMenu = nil
  return mtable
end

function updateWSMenu(_title)
  -- print(_title)
  selectedLayout = get(_title,selectedLayout)
  winstar:setTitle(lm_Title)
  winstar:setMenu(getWSMenu)
end

function wsScreensChanged()
  -- print("wsScreensChanged")
  -- updateWSMenu()
end

if winstar then
  print("\n ================================================= Started Winstar")
  wsScreenWatcher = hs.screen.watcher.new(screensChanged)
  wsScreenWatcher:start()
  restoreSettings(wsAppKey,wsTableKey,layouts)
  updateWSMenu()
end

bindKey(hyper, "w", "Show window layouts", function()
  usePopupMenu = true
  local myPopupMenu = hs.menubar.new():setMenu(getWSMenu())
  myPopupMenu:popupMenu(hs.mouse.absolutePosition())
end)

