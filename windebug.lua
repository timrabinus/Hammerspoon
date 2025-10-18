------
-- Window Layout
 
require "utils"

WD_Menu = hs.menubar.new()
WD_Menu:setTitle("􀝾") 

state = 'inactive'

---

function onPrintState()
  print("\n ----------------- onPrintState -----------------")

  local frontmostApplication = hs.application.frontmostApplication()
  local frontmostWindow = hs.window.frontmostWindow()
  local focusedWindow = frontmostApplication:focusedWindow()
  local orderedWindows = hs.window.orderedWindows()
  local invisibleWindows = hs.window.invisibleWindows()
  local minimizedWindows = hs.window.minimizedWindows()
  local visibleWindows = hs.window.visibleWindows()

  dump{frontmostApplication=frontmostApplication}
  dump{frontmostWindow=frontmostWindow}
  dump{focusedWindow=focusedWindow}
  dump{orderedWindows=orderedWindows}
  dump{invisibleWindows=invisibleWindows}
  dump{minimizedWindows=minimizedWindows}
  dump{visibleWindows=visibleWindows}

end

function onActivate(mods,item)
  print("\n ----------------- onActivate -----------------")
  if state == 'inactive' then
    state = 'active'
  else 
    state = 'inactive'
  end 
end

function onRaise(win, mods, item)
  print("\n ----------------- onRaise -----------------")
  dump{win=win, frame=win:frame(), isMinimized=win:isMinimized(), isVisible=win:isVisible(), isFullScreen=win:isFullScreen()}
  win:raise():focus()
end

function onRaiseApp(app, mods, item)
  print("\n ----------------- onRaiseApp -----------------")
  dump{app=app}
  app:setFrontmost():unhide()
end

----

function insertScreenMenus(_menu)
  local _screens = hs.screen.allScreens()
  for s = 1,#_screens do
    local _screen = _screens[s]
    local _windowMenu = {}
    local _visibleWindows = hs.window.visibleWindows()
    for w = 1,#_visibleWindows do
      local _window = _visibleWindows[w]
      if _window:screen() == _screen then
        table.insert(_windowMenu, { 
          title = _window:application():name()..": '".._window:title().."'", 
          function(mods,item) onRaise(_window,mods,item) end })
      end
    end
    table.insert(_menu, { title = _screen:name(), menu=_windowMenu })
  end
end

function getAppMenu(apps)
  table.sort(apps, function(l1,l2) return string.upper(l1:name()) < string.upper(l2:name()) end)

  local _menu = {}
  for l = 1,#apps do
    local app = apps[l]
    table.insert(
      _menu,
      getMenuItem(l..": \t"..app:name(), function(mods,item) onRaiseApp(app,mods,item) end)
    )
  end
  return _menu
end

function getWindowMenu(windows)
  local _menu = {}
  for l = 1,#windows do
    local win = windows[l]
    table.insert(
      _menu,
      getMenuItem(win:application():name()..": '"..win:title().."'", function(mods,item) onRaise(win,mods,item) end)
    )
  end
  return _menu
end

function time(label,fn)
  local start = os.time()
  local val = fn()
  local finish = os.time()
  dump{label=label,time=finish-start}
  return val
end

function getWDMenu()
  local orderedWindows = time("orderedWindows", function() return hs.window.orderedWindows() end)
  local invisibleWindows = time("invisibleWindows", function() return hs.window.invisibleWindows() end)
  local minimizedWindows = time("minimizedWindows", function() return hs.window.minimizedWindows() end)
  local visibleWindows = time("visibleWindows", function() return hs.window.visibleWindows() end)
  local runningApplications = time("runningApplications", function() return hs.application.runningApplications() end)

  local frontmostApplication = time("frontmostApplication", function() return hs.application.frontmostApplication() end)
  local appFocusedWindow = time("appFocusedWindow", function() return frontmostApplication:focusedWindow() end)
  
  _menu = {}

  insertScreenMenus(_menu)
  table.insert(_menu, { title="-" })

  table.insert(_menu, { title = "Ordered Windows", menu=getWindowMenu(orderedWindows) })
  table.insert(_menu, { title = "Visible Windows", menu=getWindowMenu(visibleWindows) })
  table.insert(_menu, { title = "Minimized Windows", menu=getWindowMenu(minimizedWindows) })
  table.insert(_menu, { title = "Invisible Windows", menu=getWindowMenu(invisibleWindows) })
  table.insert(_menu, { title = "RunningApplications", menu=getAppMenu(runningApplications) })

  table.insert(_menu, { title="-" })

  table.insert(_menu, { title = "Frontmost Application: "..frontmostApplication:name(), fn=onPrintState })
  table.insert(_menu, { title = "  Application Frontmost", fn=onPrintState, checked=frontmostApplication:isFrontmost(), disabled=true })
  table.insert(_menu, { title = "  Hidden", fn=onPrintState, checked=frontmostApplication:isHidden(), disabled=true })
  table.insert(_menu, { title = "  Running", fn=onPrintState, checked=frontmostApplication:isRunning(), disabled=true })
  table.insert(_menu, { title = "All Windows", menu=getWindowMenu(frontmostApplication:allWindows()) })
  table.insert(_menu, { title = "Visible Windows", menu=getWindowMenu(frontmostApplication:visibleWindows()) })

  table.insert(_menu, { title="-" })
  if appFocusedWindow then
    table.insert(_menu, { title = "Application Frontmost Window: "..appFocusedWindow:title(), fn=onPrintState })
    table.insert(_menu, { title = "  Full Screen", fn=onPrintState, checked=appFocusedWindow:isFullScreen(), disabled=true })
    table.insert(_menu, { title = "  Maximizable", fn=onPrintState, checked=appFocusedWindow:isMaximizable(), disabled=true })
    table.insert(_menu, { title = "  Minimized", fn=onPrintState, checked=appFocusedWindow:isMinimized(), disabled=true })
    table.insert(_menu, { title = "  Standard", fn=onPrintState, checked=appFocusedWindow:isStandard(), disabled=true })
    table.insert(_menu, { title = "  Visible", fn=onPrintState, checked=appFocusedWindow:isVisible(), disabled=true })
  else
    table.insert(_menu, { title="No Frontmost Window", fn=onPrintState, disabled=true })
  end

  local frontmostWindow = time("frontmostWindow", function() return hs.window.frontmostWindow() end)
  local focusedWindow = time("focusedWindow", function() return hs.window.focusedWindow() end)

  table.insert(_menu, { title="-" })
  table.insert(_menu, { title="Focused Window: "..focusedWindow:title(), disabled=true })
  -- table.insert(_menu, { title="Full Screen", fn=onPrintState, checked=focusedWindow:isFullScreen()  })
  -- table.insert(_menu, { title="Maximizable", fn=onPrintState, checked=focusedWindow:isMaximizable()  })
  -- table.insert(_menu, { title="Minimized", fn=onPrintState, checked=focusedWindow:isMinimized()  })
  -- table.insert(_menu, { title="Standard", fn=onPrintState, checked=focusedWindow:isStandard()  })
  -- table.insert(_menu, { title="Visible", fn=onPrintState, checked=focusedWindow:isVisible()  })

  -- table.insert(_menu, { title="-" })
  table.insert(_menu, { title="Window Frontmost Window: "..frontmostWindow:title(), disabled=true })
  -- table.insert(_menu, { title="Full Screen", fn=onPrintState, checked=frontmostWindow:isFullScreen()  })
  -- table.insert(_menu, { title="Maximizable", fn=onPrintState, checked=frontmostWindow:isMaximizable()  })
  -- table.insert(_menu, { title="Minimized", fn=onPrintState, checked=frontmostWindow:isMinimized()  })
  -- table.insert(_menu, { title="Standard", fn=onPrintState, checked=frontmostWindow:isStandard()  })
  -- table.insert(_menu, { title="Visible", fn=onPrintState, checked=frontmostWindow:isVisible()  })

  return _menu
end

if WD_Menu then
  hs.console.clearConsole()
  print("\n ================================================= Started WinState")
  WD_Menu:setMenu(getWDMenu)
end

bindKey(hyper, "e", "Win Debug", function()
  local myPopupMenu = hs.menubar.new():setMenu(getWDMenu)
  myPopupMenu:popupMenu(hs.mouse.absolutePosition())
end)


print("** Loaded windebug **")

