require "utils"
hs.sound = require("hs.sound")

print("-- loading finderTabs.lua --")

FT_Title             = "􀎦" -- pin
FT_Menu              = hs.menubar.new()
FT_AppKey            = "mb_settings_finder_tabs"
FT_TableKey          = "tabs"
FT_NumberOfScreens   = 0
FT_MainScreenFrame   = { w=0, h=0 }
FT_UsePopupMenu      = false
FT_Finder            = hs.appfinder.appFromName("Finder")
FT_Tabs              = {} -- { title, path, win, isTabbed, tabFrame, winFrame, toolbarIsVisible, sidebarIsVisible, goMenuItem } or {} if nothing in that slot
FT_HasExternalDrive  = hs.fs.displayName('/volumes/TranscendHD/Apps')
FT_NumTabs           = FT_HasAlternativeAppDir and 7 or 6 
FT_AnimationDuration = 50 -- time taken by Mac OS to animate toolbar change
FT_TitlebarHeight    = -30 -- 25
FT_ScreenWatcher     = nil -- set up at end

function Equal(x,y,limit)
  limit = limit or 5
  return math.abs(x-y) < limit
end


function _SetupTabs(num)
  FT_NumTabs = min(num,9)
  print('Setting up '..FT_NumTabs..' tabs')
  for t=1,FT_NumTabs do
    FT_Tabs[t]={}
    hs.hotkey.bind(hyper, ""..t, function() RestoreTab(t) end)
    hs.hotkey.bind(shyper, ""..t, function() MakeTab(t) end)
  end
end


function _InitializeTab(i, t, showTab)
  if FT_MainScreenFrame.w < 2000 and t.wideScreenOnly then
    showTab = false
  else
    showTab = showTab or false
  end

  local restoreTab = function(_i, _t, _win, _showTab)
    if not _win then print("No win for #".._i) end
    _win:setFrame(_t.winFrame) 
    local _, _, tabRect = _GetTabInfo(_win, _i)
    _t.win = _win
    _t.tabFrame = tabRect
    FT_Tabs[_i] = _t
    if _showTab then
      _ShowTab(_win, _i)
    else
      _HideTab(_win, _i)
    end
  end

  -- log(i..": "..t.title.." - "..t.path)
  local win = FT_Finder:getWindow(t.title)
  if not win then
    if t.goMenuItem then
      -- needed for 'Recents' or other commands that return a window but don't have a path
      FT_Finder:selectMenuItem(t.goMenuItem)
      hs.timer.doAfter(FT_AnimationDuration, function() 
        win = FT_Finder:focusedWindow()
        restoreTab(i, t, win)
      end)
    else
      hs.execute("open '"..t.path.."'")
      -- usleep blocks user thread, but we need to give time for open to work
      hs.timer.usleep(50000)
      win = FT_Finder:getWindow(t.title)
      if win then restoreTab(i, t, win)
      else
        if not win then print('Error: could not find win '..t.title) end
      end
    end
  else
    restoreTab(i, t, win)
  end
end


function _InitializeTabs()

  local windows = FT_Finder:allWindows()
  for w = 1,#windows do
    windows[w]:close()
  end

  print("__InitializeTabs()")

  FT_NumberOfScreens = #hs.screen.allScreens()
  FT_MainScreenFrame = hs.screen.mainScreen():frame()

  local displayHeight = FT_MainScreenFrame.h + FT_TitlebarHeight
  local dropboxHome = FT_HasExternalDrive and "/Volumes/TranscendHD/Users/martin/Dropbox/" or "/Users/Martin/Dropbox/"
  local tabs = {
    {
      title            = "Applications",
      winFrame         = { h = displayHeight, w = 316.0, x = 5.0, y = 0.0 },
      path             = "/Applications",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    }, 
    {
      title            = "Downloads",
      winFrame         = { h = displayHeight, w = 532.0, x = 325.0, y = 0.0 },
      path             = "/Users/Martin/Downloads",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    }, 
    {
      title            = "M_Documents",
      winFrame         = { h = displayHeight, w = 840.0, x = FT_MainScreenFrame.w-840.0*2, y = 0.0 },
      path             = dropboxHome.."M_Documents",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    }, {
      title            = "KMJS Documents",
      winFrame         = { h = displayHeight, w = 840.0, x = FT_MainScreenFrame.w-840.0, y = 0.0 },
      path             = dropboxHome.."KMJS Documents",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    }, {
      title            = "Recipes",
      winFrame         = { h = displayHeight, w = 840.0, x = FT_MainScreenFrame.w-840.0, y = 0.0 },
      path             = dropboxHome.."KMJS Documents/Recipes",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    }, {
      title            = "Books",
      winFrame         = { h = displayHeight, w = 760.0, x = FT_MainScreenFrame.w-760.0, y = 0.0 },
      path             = dropboxHome.."KMJS Documents/Books",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    },
    {
      title            = "Apps",
      winFrame         = { h = displayHeight, w = 316.0, x = FT_MainScreenFrame.w-316.0, y = 0.0 },
      path             = "/volumes/TranscendHD/Apps",
      sidebarIsVisible = false,
      toolbarIsVisible = false,
      wideScreenOnly   = false,
    }



    -- , {
    --   title = "Recents",
    --   winFrame = { h = displayHeight, w = 840.0, x = FT_MainScreenFrame.w-840.0, y = 0.0 },
    --   path = "/",
    --   sidebarIsVisible = false,
    --   toolbarIsVisible = false,
    --   goMenuItem = "Recents"
    -- }
  }

  for i,t in ipairs(tabs) do
    print(i)
    _InitializeTab(i, t, false)
  end
  
end


function _SaveTabs()
  log("-- _SaveTabs")
  -- win is a memory object that can't be saved, remove it
  local tabClones=deep_copy(FT_Tabs)
  for i,val in ipairs(tabClones) do
    val.win = nil
  end
  -- dump(FT_Tabs, "FT_Tabs")
  dump(tabClones, "Clone")
  saveSettings(FT_AppKey, FT_TableKey, tabClones)
end


function _ShowTab(win, pos)
  -- log("-- _ShowTab "..pos)
  local tab = FT_Tabs[pos]
  FT_Tabs[pos].isTabbed = false
  win:setFrame(tab.winFrame)

  -- Restore toolbar and sidebar if needed
  if tab.toolbarIsVisible or tab.sidebarIsVisible then
    -- need to wait for animation to finish before moving window or the window state gets confused
    -- if tab.toolbarIsVisible then 
    --   hs.timer.doAfter(FT_AnimationDuration, function() FT_Finder:selectMenuItem("Show Toolbar") end) 
    -- end
    -- if tab.sidebarIsVisible then 
    --   hs.timer.doAfter(FT_AnimationDuration, function() FT_Finder:selectMenuItem("Show Sidebar") end) 
    -- end
  end
end


function _HideTab(win, pos)
  log("-- _HideTab "..pos)

  local tab = FT_Tabs[pos]
  FT_Tabs[pos].isTabbed = true
  local tabRect = FT_Tabs[pos].tabFrame

  local hideTabFn = function()
    local winFrame = win:frame()
    -- reduce width first with anim=0, since MacOS won't do that if window is partially off screen
    win:setFrame({ x=winFrame.x, y=winFrame.y, w=tabRect.w, h=winFrame.h }, 50)
    -- then, place the window at bottom with animation
    win:setFrame(tabRect)
    -- dump(win:frame(),"   moved tab to:")
  end

  -- Hide toolbar and sidebar to make title compact
  tab = tab or FT_Tabs[pos]
  -- if tab.toolbarIsVisible or tab.sidebarIsVisible then
    -- if tab.toolbarIsVisible then 
    --   FT_Finder:selectMenuItem("Hide Toolbar")
    --   -- hs.timer.doAfter(FT_AnimationDuration*4, function() FT_Finder:selectMenuItem("Hide Toolbar") end)
    --   hs.timer.doAfter(FT_AnimationDuration*4, hideTabFn)
    -- else
    --   if tab.sidebarIsVisible then 
    --     FT_Finder:selectMenuItem("Hide Sidebar")
    --     hs.timer.doAfter(FT_AnimationDuration*4, hideTabFn)
    --   end
    -- end
  --   hs.timer.doAfter(FT_AnimationDuration*4, hideTabFn)
  -- end
  FT_Finder:selectMenuItem("Hide Toolbar")
  FT_Finder:selectMenuItem("Hide Sidebar")
  FT_Finder:selectMenuItem("Hide Status Bar")
  hideTabFn()
end


-- returns (atBottom, winFrame, tabRect)
function _GetTabInfo(win, pos)
  local winFrame     = win:frame()
  local screen       = win:screen()
  local screenBottom = screen:frame().h
  local tabWidth     = 320

  -- determine if we're showing or tabing the window, based on whether if it's at the bottom of the screen
  local tabRectLessTitleBar = { x=(pos-1)*tabWidth+5, y=screenBottom-FT_TitlebarHeight, w=tabWidth-10, h=200.0 }
  -- local tabRect = { x=(pos-1)*tabWidth+5, y=screenBottom, w=tabWidth-10, h=200.0 }
  -- dump(tabRect, "tabRect")
  -- dump(tabRectLessTitleBar, "tabRectLessTitleBar")
  return Equal(winFrame.y, tabRectLessTitleBar.y, FT_TitlebarHeight), winFrame, tabRectLessTitleBar
end


function _IsShowingSidebar()
  -- findMenuItem returns nil or state { enabled = true, ticked = false }
  local showingSidebar = FT_Finder:findMenuItem("Hide Sidebar")
  if showingSidebar then return true else return false end
end


function _IsShowingToolbar()
  -- findMenuItem returns nil or state { enabled = true, ticked = false }
  local showingToolbar = FT_Finder:findMenuItem("Hide Toolbar")
  if showingToolbar then return true else return false end
end


function RestoreTab(pos)
  -- log("-- ** restore "..pos.." **")

  local tab = FT_Tabs[pos]
  if tab and tab.win then
    local win = hs.window.frontmostWindow()
    local atBottom = tab.isTabbed

    tab.win:focus()
    if win ~= tab.win and not atBottom then
      -- just bring to front as tab is open but not on top
    else
      -- show/hide as appropriate
      local _, winFrame, tabFrame = _GetTabInfo(tab.win, pos)
      if winFrame.w == 0 then
        _InitializeTab(pos, tab, true)
      else
        if atBottom then
          _ShowTab(tab.win, pos)
        else
          _HideTab(tab.win, pos)
        end
      end
    end

  else
    -- nothing in tab "..pos
    local beep = hs.sound.getByName("Tink")
    beep:play()
  end
end


function MakeTab(pos)
  log("-- ** MakeTab "..pos.." **")

  local win = hs.window.focusedWindow()
  if win:application() ~= FT_Finder then return end

-- get focused window, determine the slot frame
  local winTitle = win:title()
  local atBottom, winRect, tabRect = _GetTabInfo(win, pos)

  if not atBottom then
    for t = 1,FT_NumTabs do
      if FT_Tabs[t] ~= {} then
        local tabTitle = FT_Tabs[t].title
        if t ~= pos then
          -- if another tab had the window, clear it
          if winTitle == tabTitle then
            FT_Tabs[t] = {}
            log("-- removing "..tabTitle.." from old tab "..t)
          end
        else
          -- if pos already has a different window, confirm before replacing
          if tabTitle ~= nil and tabTitle ~= winTitle then
            if hs.dialog.blockAlert("Place over existing tab "..tabTitle.."?", "", "No", "Yes") == "Yes" then
              log("-- overwriting "..tabTitle.." in tab "..pos)
              FT_Tabs[t] = {}
            else
              return
            end
          end
        end
      end
    end

    -- save FT_Tabs
    FT_Tabs[pos] = {
      title            = win:title(),
      win              = win,
      path             = "",
      isTabbed         = false,
      winFrame         = winRect,
      tabFrame         = tabRect,
      toolbarIsVisible = _IsShowingToolbar(),
      sidebarIsVisible = _IsShowingSidebar()
    }

    _HideTab(win, pos)
    _UpdateFTMenu()
    -- _SaveTabs()
  end
end

  
function _OnRestoreWindow(mods,item)
  log("\n ----------------- onRestoreWindow -----------------")
end



function _GetFTMenu()
  local menu = {}
  local pad = ""

  if FT_UsePopupMenu then
    table.insert(menu, { title = "􀎦 Pinned Windows:", disabled=true})
    table.insert(menu, { title = "-" })
    pad = "     "
  end

  local _numTabs = 0
  for t = 1,FT_NumTabs do
    if FT_Tabs[t] ~= {} and FT_Tabs[t].title then
      table.insert(menu, { title = pad..FT_Tabs[t].title, fn=function() RestoreTab(t) end, shortcut=''..t })
      _numTabs = _numTabs + 1
    else
      print('Error: could not get win for #'..t)
    end
  end
  if _numTabs == 0 then
    table.insert(menu, { title = pad.."No pinned windows", disabled=true })
  end
  
  table.insert(menu, { title = "-" })
  table.insert(menu, { title = pad.."Restore Tabs", fn=function() _InitializeTabs() end, shortcut="r" })

  FT_UsePopupMenu = false
  return menu
end


function _UpdateFTMenu()
FT_Menu
    :setTitle(FT_Title)
    :setMenu(_GetFTMenu)
end



local function screenGeometryChanged()
  local newH = hs.screen.mainScreen():frame().h
  local newW = hs.screen.mainScreen():frame().w
  local changed = FT_NumberOfScreens ~= #hs.screen.allScreens()
      or FT_MainScreenFrame.h ~= newH
      or FT_MainScreenFrame.w ~= newW
  if changed then
    log("Number of displays changed from "..FT_NumberOfScreens .." to "..#hs.screen.allScreens())
    log("Screen resolution changed from "..FT_MainScreenFrame.w.." x "..FT_MainScreenFrame.h
      .." to " ..newW.." x "..newH)
      FT_MainScreenFrame.h = newH
      FT_MainScreenFrame.w = newW
      FT_NumberOfScreens = #hs.screen.allScreens()
  end
  return changed
end


function _FTScreenChanged(eventType)
  log("_FTScreenChanged")
  if (eventType == hs.screen.watcher.screensDidChange) then
    if screenGeometryChanged() then
    _InitializeTabs()
    end
  elseif (eventType == hs.screen.watcher.screensDidSleep) then
    log("Displays went to sleep")
  elseif (eventType == hs.screen.watcher.screensDidWake) then
      log("Displays woke up")
  elseif (eventType == hs.screen.watcher.screensChanged) then
    log("resolution or other change")
    if screenGeometryChanged() then
      _InitializeTabs()
    end
  end
end



bindKey(hyper, "f", "Show Finder Tabs", function()
  FT_UsePopupMenu = true
  local menu = hs.menubar.new():setMenu(_GetFTMenu)
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    menu:popupMenu({x=rect.x+rect.w/2-60,y=rect.y+rect.h/4})
  else
    menu:popupMenu(hs.mouse.absolutePosition())
  end
end)

_SetupTabs(FT_NumTabs)
if screenGeometryChanged() then
  _InitializeTabs()
end

if FT_Menu then
  FT_ScreenWatcher = hs.screen.watcher.new(_FTScreenChanged)
  FT_ScreenWatcher:start()
  _UpdateFTMenu()
end

print("** Loaded finderTabs **")

---
