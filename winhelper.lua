------
-- Display Sleep
require "utils"

FH_Title = "􀢌" -- window
FH_Menu = hs.menubar.new()
usePopupMenu = false


function onRaise(win)
  -- print("\n ----------------- onRaise -----------------")
  -- dump{win=win, frame=win:frame(), isMinimized=win:isMinimized(), isVisible=win:isVisible(), isFullScreen=win:isFullScreen()}
  win:raise():focus()
end


function onNewWindow()
  -- print("New Window")
  hs.eventtap.keyStroke({"cmd"}, "n")
end

 
function onHideOthers()
  -- print("Hide Others")
  hs.eventtap.keyStroke({"cmd","alt"}, "h")
end


function onZoomWindow()
    -- print("Zoom Window")
  local app = hs.application.frontmostApplication()
  local win = app:mainWindow()
  if not win or win:isMinimized() then
    if win then win:unminimize() return end
    win = app:focusedWindow()
    if win then win:unminimize() return end
    local wins = app:allWindows()
    if #wins >= 1 then wins[#wins]:unminimize() return end
  else
    win:minimize()
  end
end


function getFHMenu()
  local menu = {}
  local pad = ""
  local frontmostApplication = hs.application.frontmostApplication()
  local mainWin = frontmostApplication:mainWindow()
  local windows = frontmostApplication:allWindows()
  local wins = {}

  if usePopupMenu then
    table.insert(menu, { title = FH_Title.." Window Helper: "..hs.application.frontmostApplication():name(), disabled=true})
    table.insert(menu, { title = "-" })
    pad = "      "
  end

  if mainWin and #windows > 0 then
    for w = 1,#windows do
      if windows[w]:title() ~= "" then
        table.insert(wins,{title=windows[w]:title(),win=windows[w]})
      end
    end
    
    table.sort(wins, function(a,b) return a.title < b.title end)
    
    for w = 1,#wins do
      if w <10 then
        table.insert(menu, { title = pad..w..":  "..wins[w].title, fn=function() onRaise(wins[w].win) end, shortcut=''..w , checked=(mainWin:title()==wins[w].title)})
      else
        table.insert(menu, { title = pad..wins[w].title, fn=function() onRaise(wins[w].win) end })
      end
    end

    table.insert(menu, { title = "-" })

  end

  table.insert(menu, { title = pad.."New Window", fn=function() onNewWindow() end, shortcut='n' })
  table.insert(menu, { title = pad.."Hide Other Apps", fn=function() onHideOthers() end, shortcut='h' })
  table.insert(menu, { title = pad.."Zoom Window", fn=function() onZoomWindow() end, shortcut='z' })

  return menu
end


function updateFHMenu()
  FH_Menu:setTitle(FH_Title)
  FH_Menu:setMenu(getFHMenu)
end


if FH_Menu then
  updateFHMenu()
end


function onFHMenu()
  usePopupMenu = true
  local menu = hs.menubar.new():setMenu(getFHMenu)
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    menu:popupMenu({x=rect.x+rect.w/2-60,y=rect.y+rect.h/4})
  else
    menu:popupMenu(hs.mouse.absolutePosition())
  end
end

bindKey(hyper, "w", "Show Windows", onFHMenu)



-- set up your windowfilter
-- switcher = hs.window.switcher.new() -- default windowfilter: only visible windows, all Spaces
-- switcher = hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter{}) -- include minimized/hidden windows, current Space only
-- switcher = hs.window.switcher.new{'Safari','Google Chrome'} -- specialized switcher for your dozens of browser windows :)

-- hs.hotkey.bind('alt','tab','Next window',function() switcher:next()end)
-- hs.hotkey.bind('alt-shift','tab','Prev window',function() switcher:previous()end)

print("** Loaded winhelper **")
 