------
-- Worskpaces: Window Layout

-- To Do:
 
require "utils"

lm_All    = "All Displays"
lm_Swap   = "Swap Displays"
layoutMode = lm_All

lm_FullImgSize = 512
lm_ImgSize = 128

lm_Title = "􀏝" -- uiwindow.split.2x1
winstar = hs.menubar.new()
selectedLayoutName = ""
selectedLayout = {}
winstar:setTitle(lm_Title) 
usePopupMenu = nil

layouts = {}  -- {name, snapshot, windowLayouts {title, appID, screen, frame={x,y,w,h}, unitFrame={x,y,w,h} }, appIDs, frontWindow }

----

wsAppKey="mb_settings_winstar"
wsTableKey="layouts"

----

function recordNewLayout(_name, _snapshot)
  --* recordNewLayout
  if not _snapshot then 
    _snapshot = hs.screen.mainScreen():snapshot():setSize({h=lm_FullImgSize,w=lm_FullImgSize}):encodeAsURLString()
  end

  local _windowLayouts = {}
  local _orderedWindows = hs.window.orderedWindows()  -- top to bottom
  local _appIDs = inject({}, _orderedWindows, function(appIDs, w)
    if not hs.fnutils.contains(appIDs, w:application():bundleID()) then 
      table.insert(appIDs, w:application():bundleID())
    end
    return appIDs
  end)
  --* found "..#_appIDs.." visible apps

  
  for w = 1,#_orderedWindows do
    local _win=_orderedWindows[w]
    local _frame     = _win:frame()
    local _unitFrame = _win:screen():toUnitRect(_win:frame())
    local _windowLayout = {
      title     = _win:title(),
      appID     = _win:application():bundleID(),
      screen    = _win:screen():name(),
      frame     = { x=_frame.x, y=_frame.y, w=_frame.w, h=_frame.h },
      unitFrame = { x=_unitFrame.x, y=_unitFrame.y, w=_unitFrame.w, h=_unitFrame.h },
    }
    table.insert(_windowLayouts, _windowLayout)
  end

  local _layout = {
    name        = _name, 
    snapshot    = _snapshot, 
    windows     = _windowLayouts,
    appIDs      = _appIDs,
    frontWindow = get(hs.window.frontmostWindow():title(),"")
   }
  table.insert(layouts,_layout)
  table.sort(layouts, function(l1,l2) return string.upper(l1.name) < string.upper(l2.name) end)

  saveSettings(wsAppKey,wsTableKey,layouts)
  selectedLayoutName, selectedLayout = _name, _layout
end 

function getLayout(_name)
  for l = 1,#layouts do
    if layouts[l].name == _name then
      return layouts[l],l
    end
  end
  return nil,nil
end

function onRecordNewLayout()
  print("\n ----------------- onRecordNewLayout -----------------")
  local _snapshot = hs.screen.mainScreen():snapshot():setSize({h=lm_ImgSize,w=lm_ImgSize}):encodeAsURLString()

  hs.focus()
  local _btn,_name = hs.dialog.textPrompt(
    "",
    "Name this layout:", 
    "Layout "..#layouts+1, 
    "OK", "Cancel")
  if _btn=="Cancel" or _name=="" then 
    return 
  end
  
  local existing, _ = getLayout(_name)
  if existing then
    _btn = hs.dialog.blockAlert("Update existing layout?",_name.." has already been defined","OK","Cancel")
    if _btn=="Cancel" then
      return
    end
    removeLayoutNamed(_name)
  end
  
  recordNewLayout(_name, _snapshot)
  updateWSMenu()
end

--

function selectScreen(_layout)
  local _preferredScreen, _newScreen = _layout.screen, nil
  local _screens = hs.screen.allScreens()

  -- Determine which screen to place window on 
  if layoutMode == lm_All then
    _newScreen = _preferredScreen
  elseif layoutMode == lm_Swap then
    if _preferredScreen == _screens[1]:name() then
      _newScreen = _screens[2]:name()
    else
      _newScreen = _screens[1]:name()
    end
  else
    _newScreen = layoutMode
  end

  -- prefer original window position if on same screen, else move to same unitFrame on other screen
  local _rect, _unitRect = nil,nil
  if _newScreen == _layout.screen then
    _rect = _layout.frame
  else
    _unitRect = _layout.unitFrame
  end
  -- dump{newScreen=_newScreen, preferredScreen=_preferredScreen, rect=_rect, unitRect=_unitRect}
  
  return _newScreen, _rect, _unitRect
end

---

function sizeWindows()
  --* sizeWindows

  -- layout has windows that should be resized
  -- for document apps the windows may no longer be present
  -- for app windows, should be good
  -- showApps will ensure that all layout apps are visible
  -- there may be other apps if we overlaid -- these should be left alone

  -- get all windows for the application that are currently visible
  local _screenWindows = hs.window.visibleWindows()
  local _newLayouts = {}
  
  for w = #selectedLayout.windows,1,-1 do
    -- find the window with the same title & size it
    local _layout = selectedLayout.windows[w]
    local _application = hs.application.get(_layout.appID)

    if hs.application.launchOrFocusByBundleID(_layout.appID) then
      local _screenWindow = hs.window.get(_layout.title)
      local _screen, _rect, _unitRect = selectScreen(_layout)

      if not _screenWindow then
        print("-- could not find window ".._layout.title.." using the application's frontMost window")
        _screenWindow = _application:mainWindow()
      end
        
      local _winLayout = { _application, _screenWindow, _screen, _unitRect, _rect, nil }
      table.insert(_newLayouts, _winLayout)
      removeElement(_screenWindows, _screenWindow)

    else
      print("--- could not launch ".._application.." ")
    end
  end
  
  -- go through any remaining application windows that are still visible and hide them
  --* "..#_screenWindows.." windows to minimize
  for w = 1,#_screenWindows do
    local _win = _screenWindows[w]
    print("-- minimize ".._win:application():name()..": '".._win:title().."'")
    _win:minimize()
  end

  hs.layout.apply(_newLayouts)
end


function showApps()
  --* showApps
  local wins = hs.window.visibleWindows()
  --* show/hide current apps
  for w = 1,#wins do
    local _win = wins[w]
    local _app = _win:application()
    local _appVisible = hs.fnutils.find(selectedLayout.appIDs, function(a) 
      return a == _app:bundleID()
    end)
    if _appVisible then 
      --* showing ".._app:name(
      _app:unhide()
    else
      --* hiding ".._app:name(
      _app:hide() 
    end
  end

  -- show/hide apps in the layout
  for a = 1,#selectedLayout.appIDs do
    local _app = hs.application.find(selectedLayout.appIDs[a])
    if _app then
      if not _app:isRunning() then
        hs.application.launchOrFocus(selectedLayout.appIDs[a])
      end
      if _app:isHidden() then 
        print("-- showing ".._app:name())
        _app:unhide()
      end
    end
  end

  -- hs.window.find(selectedLayout.frontWindow):focus():raise()

end


function selectLayoutNamed(layoutName)
  print("-- selectLayoutNamed '"..layoutName.."' on "..layoutMode)
  
  selectedLayoutName, selectedLayout = layoutName, getLayout(layoutName)  -- update global selectedLayout
  showApps()
  sizeWindows()
  
end

function onSelectLayout(mods,item)
  print("\n ----------------- onSelectLayout -----------------")
  selectLayoutNamed(item.title:gsub("^  ", "")) -- remove prefix from menu
  updateWSMenu()
end

--

function removeLayoutNamed(name)
  local _layout, i = getLayout(name)
  if _layout then
    clearSettings(wsAppKey, wsTableKey, layouts)
    table.remove(layouts, i)
    if name == selectedLayoutName then
      selectedLayoutName, selectedLayout = "", {}
    end
    saveSettings(wsAppKey, wsTableKey, layouts)
  end
end

function onRemoveLayout(mods,item)
  print("\n ----------------- onRemoveLayout -----------------")
  removeLayoutNamed(item.title)
  updateWSMenu()
end

--

function onRemoveAllLayouts(mods,item)
  print("\n ----------------- onRemoveAllLayouts -----------------")
  clearSettings(wsAppKey,wsTableKey,layouts)
  layouts={}
  selectedLayoutName, selectedLayout = "", {}
  updateWSMenu()
end

--

function onUpdateLayout(mods,item)
  print("\n ----------------- onUpdateLayout -----------------")
  local _layoutName = selectedLayoutName
  removeLayoutNamed(_layoutName)
  recordNewLayout(_layoutName)
  show("Updated ".._layoutName)
  updateWSMenu()
end

--

function onArrangeLayout(mods,item)
  print("\n ----------------- onArrangeLayout -----------------")
  if layoutMode == lm_Swap then
    layoutMode = lm_All
  else
    layoutMode = item.title
  end
  selectLayoutNamed(selectedLayoutName)
  updateWSMenu()
end

--
-- Menu Building
--

function getRemoveMenu()
  local _menu = {}
  for l = 1,#layouts do
    table.insert(_menu,getMenuItem(layouts[l].name,onRemoveLayout))
  end
  return _menu
end

function getArrangeMenu(screens)
  local _menu = {}
  table.insert(_menu,getMenuItem(lm_All,onArrangeLayout,layoutMode==lm_All))
  table.insert(_menu, { title = "-" })
  for s = 1,#screens do
    table.insert(_menu,getMenuItem(screens[s]:name(),onArrangeLayout,layoutMode==screens[s]:name()))
  end
  if #screens == 2 then --! TODO: have not tested with 3 screens
    table.insert(_menu, { title = "-" })
    table.insert(_menu,getMenuItem(lm_Swap,onArrangeLayout,layoutMode==lm_Swap))
  end
  return _menu
end

function getWSMenu()
  local mods = hs.eventtap.checkKeyboardModifiers()
  local showOptions = mods["alt"] and not mods["cmd"] and not mods["ctrl"]

  local screens = hs.screen.allScreens()

  _menu = {}

  if #layouts > 0 and usePopupMenu then
    table.insert(_menu, { title = "􀏝 Workspaces:", disabled=true})
    table.insert(_menu, { title = "-" })
  end

  for l = 1,#layouts do
    local layout=layouts[l]
    table.insert(_menu,getMenuItem(
      "  "..layout.name,  -- need to remove in onSelectLayout
      onSelectLayout,
      layout.name == selectedLayoutName,
      nil,
      hs.image.imageFromURL(layout.snapshot):setSize({h=lm_ImgSize,w=lm_ImgSize}),
      nil,
      l<10 and ""..l or ""))

  end
  table.insert(_menu, { title = "-" })
  table.insert(_menu, { title = "Record New Workspace...", fn=onRecordNewLayout, shortcut='r'})

  if #layouts>0 and not usePopupMenu then
    table.insert(_menu, { title="Update "..selectedLayoutName, fn=onUpdateLayout, disabled=(selectedLayoutName == ""), shortcut='u' })
    -- table.insert(_menu, { title = "-" })
    -- table.insert(_menu, { title = (#screens==1) and "Arrange" or "Arrange On",  menu=getArrangeMenu(screens), disabled=(#screens==1)})
    table.insert(_menu, { title = "-" })
    if showOptions then
      table.insert(_menu, { title = "Delete All Workspaces", fn=onRemoveAllLayouts })
    else
      table.insert(_menu, { title = "Delete", menu=getRemoveMenu() })
    end
  end
  usePopupMenu = nil
  return _menu
end

function updateWSMenu()
  winstar
    :setTitle(lm_Title)
    :setMenu(getWSMenu)
end

function screensChanged()
  -- print("screensChanged")
  -- updateWSMenu()
end

if winstar then
  print("\n ================================================= Started Winstar")
  screenWatcher = hs.screen.watcher.new(screensChanged)
  screenWatcher:start()
  restoreSettings(wsAppKey,wsTableKey,layouts)
  updateWSMenu()
end

bindKey(hyper, "s", "Show Workspaces", function()
  usePopupMenu = true
  local myPopupMenu = hs.menubar.new():setMenu(getWSMenu())
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    myPopupMenu:popupMenu({x=rect.x+rect.w/2-150,y=rect.y+rect.h/4})
  else
    myPopupMenu:popupMenu(hs.mouse.absolutePosition())
  end
end)

