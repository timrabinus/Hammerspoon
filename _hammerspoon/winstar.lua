------
-- Window Layout

-- To Do:
--   Restore any windows in a layout that are now minimized
--   Minimize any windows that arent in the layout
--   Open applications

require "utils"

winstar = hs.menubar.new()
selectedLayout = ""
layoutMode = "Use All Displays"
winstar:setTitle("􀶽") -- display.and.arrow.down
layouts = {}

----

wsSettingsKey="mb_settings_winstar"

function saveLayoutSettings()
  for i,l in ipairs(layouts) do
    hs.settings.set(wsSettingsKey..".layouts."..i,l)
    print("Saving "..wsSettingsKey..".layouts."..i)
  end
end

function clearLayoutSettings()
  for i,l in ipairs(layouts) do
    hs.settings.clear(wsSettingsKey..".layouts."..i)
  end
end

function restoreLayoutSettings()
  for i,key in ipairs(hs.settings.getKeys()) do
    local keys = split(key,'.') -- {app,var,index}
    if keys[1] == wsSettingsKey then
      local val = hs.settings.get(key)
      -- print("-- restoring settings key = "..keys[2].."["..keys[3].."]") -- = "..hs.inspect(val,{depth=1}))
      if keys[2] == "layouts" then
        layouts[tonumber(keys[3])] = val
      else
        -- print("Unknown key: ",keys[2])
      end
    else
      -- print("--     ignoring settings key = "..key)
    end
  end
end

----

function onNewLayout()
  print("\n ----------------- onNewLayout -----------------")

  local _snapshot = hs.screen.mainScreen():snapshot():setSize({h=128,w=128}):encodeAsURLString()

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

  local screens = hs.screen.allScreens()
  local wins = hs.window.visibleWindows()
  local _windows = {}

  for w = 1,#wins do
    local win=wins[w]
    local app = win:application()
    local f = win:frame()
    local uf = win:screen():toUnitRect(win:frame())
    local l = {
      app=app:name(), 
      title=win:title(),
      screen=win:screen():name(),
      x=f.x, y=f.y, w=f.w, h=f.h,
      ux=uf.x, uy=uf.y, uw=uf.w, uh=uf.h,
    }
    table.insert(_windows,l)
  end

  table.insert(layouts,{name=_name, windows=_windows, snapshot=_snapshot})
  table.sort(layouts, function(l1,l2) return string.upper(l1.name) < string.upper(l2.name) end)
  saveLayoutSettings()
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
  if layoutMode == "Use All Displays" then
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

-- function selectLayoutNamed(name)
--   print("-- selectLayoutNamed '"..name.."' on "..layoutMode)
--   local layout,_ = getLayout(name)
--   local screens = hs.screen.allScreens()
--   local newLayout = {}

--   for i,w in ipairs(layout.windows) do
--   -- local i,w = 1,layout.windows[1]
--     local selectedScreen,unitRect,frameRect = selectScreen(w.screen,screens,w)
--     local winPos = {
--       w.app,
--       w.title,
--       selectedScreen,
--       unitRect, 
--       frameRect, 
--       nil
--     }
--     newLayout[#newLayout+1] = winPos
--   end

--   hs.layout.apply(newLayout)
-- end

function collectWindows(layoutName)
  local screenWindows = hs.window.allWindows()
  local wMap = {}

  -- go through windows on the screen and match with windows in layout (if there)
  local _layout = getLayout(layoutName)
  for _,sw in ipairs(screenWindows) do
    local _stitle,_sapp = sw:title(),sw:application():name()
    local _,lw = match(_layout.windows, function(_lw) 
      return _lw.title == _stitle and _lw.app == _sapp 
    end)
    -- print("{ sWindow=".._stitle..", lWindow="..(lw and get(lw.title, "nil title") or "nil"))
    table.insert(wMap,{sWindow=sw,lWindow=lw}) -- lw may be nil
  end

  -- go through windows in the layout that are unmatched and note them
  for _,lw in ipairs(layouts) do
    local _,sw = match(wMap, function(_map) 
      return _map.lWindow == lw 
    end)
    if not sw then
      -- print("{ sWindow=nil, lWindow="..(lw and get(lw.title, "nil title") or "nil"))
      table.insert(wMap,{sWindow=nil,lWindow=lw})
    end
  end

  return wMap
end

function layoutWindow(i,wMap,screens,newLayout)
  local sw,lw = wMap.sWindow,wMap.lWindow
  
  if sw and lw then
    -- print("size sw { sWindow="..sw:title()..", lWindow="..lw.title.." }")
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

  elseif not sw and lw then
    -- print("open and size sw { sWindow=nil, lWindow="..(lw and get(lw.title, "nil title")).." }")
    -- open sw and size it / or maybe ignore it?

    --   hs.application.launchOrFocus(appname)

elseif sw and not lw then
    -- print("minimize sw { sWindow="..sw:title()..", lWindow=nil }")
    sw:minimize()
  
  else
    -- print("huh? sw { sWindow=nil, lWindow=nil }")
    -- shouldnt happen
  end

  return newLayout
end

function selectLayoutNamed(layoutName)
  print("-- selectLayoutNamed '"..layoutName.."' on "..layoutMode)
  
  local screens = hs.screen.allScreens()
  local newLayout = {}

  local windowMap = collectWindows(layoutName)
  for i,wMap in ipairs(windowMap) do
    newLayout=layoutWindow(i,wMap,screens,newLayout)
  end

  hs.layout.apply(newLayout)
end

function onSelectLayout(mods,item)
  print("\n ----------------- onSelectLayout -----------------")
  selectLayoutNamed(item.title)
  updateWSMenu(name)
end

function removeLayoutNamed(name)
  local l,i = getLayout(name)
  if l then
    clearLayoutSettings()
    table.remove(layouts,i)
    if name == selectedLayout then
      selectedLayout = ""
    end
    saveLayoutSettings()
  end
end

function onRemoveLayout(mods,item)
  print("\n ----------------- onRemoveLayout -----------------")
  removeLayoutNamed(item.title)
  updateWSMenu(selectedLayout)
end

function onArrangeLayout(mods,item)
  print("\n ----------------- onArrangeLayout -----------------")
  if layoutMode == "Swap Displays" then
    layoutMode = "Use All Displays"
  else
    layoutMode = item.title
  end
  selectLayoutNamed(selectedLayout)
  updateWSMenu()
end


function getRemoveMenu()
  local mtable = {}
  for l = 1,#layouts do
    table.insert(mtable,getMenuItem(layouts[l].name,onRemoveLayout))
  end
  return mtable
end

function getArrangeMenu(screens)
  local mtable = {}
  table.insert(mtable,getMenuItem('Use All Displays',onArrangeLayout,layoutMode=='Use All Displays'))
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

function updateWSMenu(_title)
  selectedLayout = get(_title,selectedLayout)
  winstar:setTitle("􀶽 "..selectedLayout) -- display.and.arrow.down

  local screens = hs.screen.allScreens()

  mtable = {}
  for l = 1,#layouts do
    local layout=layouts[l]
    table.insert(mtable,getMenuItem(layout.name,onSelectLayout,nil,nil,hs.image.imageFromURL(layout.snapshot)))
  end
  table.insert(mtable, { title = "-" })
  table.insert(mtable, { title = "New Layout...", fn=onNewLayout})
  
  if #layouts>0 then
    table.insert(mtable, { title = "Arrange On",  menu=getArrangeMenu(screens), disabled=(#screens==1)})
    table.insert(mtable, { title = "-" })
    table.insert(mtable, { title = "Delete", menu=getRemoveMenu() })
  end

  winstar:setMenu(mtable)
end

function screensChanged()
  -- print("screensChanged")
  -- updateWSMenu()
end

if winstar then
  print("\n ================================================= Started")
  screenWatcher = hs.screen.watcher.new(screensChanged)
  screenWatcher:start()
  restoreLayoutSettings()
  updateWSMenu()
end

