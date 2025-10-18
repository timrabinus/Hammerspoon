require "utils"

ftTitle = "􀎦" -- pin
ftMenu = hs.menubar.new()
usePopupMenu = nil

local obj={}
obj.__index = obj

ftAppKey="mb_settings_tabs"
ftTableKey="tabs"


-- Locals

-- time taken by Mac OS to animate toolbar change
local prepDuration = 0.25

local QuickTab = 0
-- use the tabs[0] slot for the shelve() command

local tabs = {} -- { pos, win, full, hideKey, showKey, showToolbar }
local numTabs = 5

local function comp(x,y)
  return math.abs(x-y) < 5 
end


-- Public

--- Shelf:setupTabs(num)
--- Variable
--- Integer, the number of tabs across the screen to place windows in

function obj:setupTabs(num)
  -- unbind hyper-1 et
  for t=1,numTabs do
    if tabs[t] then
      unbindKey(tabs[t].hideKey)
      unbindKey(tabs[t].showKey)
    end
  end

  numTabs = min(num,9)
  for t=1,numTabs do
    tabs[t]={}
    -- tabs[i].showKey = bindKey(hyper, ""..i, "Show window in tab slot "..i, function() obj:restore(i) end)
    tabs[t].hideKey = hs.hotkey.bind(shyper, ""..t, function() obj:place(t) end)
  end
end

function place_ShowTab(win, pos)
  -- need to wait for setFrame to finish before moving window or the window state gets confused
  win:setFrame(tabs[pos].full)
  hs.timer.doAfter(prepDuration, function()
    prepWindow(win, pos, true)
    if pos == QuickTab then
      -- clear the tabs so that other windows can use it
      tabs[QuickTab] = {}
    end
  end)
end


function place_HideTab(win, pos, screen, winFrame, tabRect)
  print("-- if pos already has a window, confirm")
  local placeTab = true
  if pos ~= QuickTab then
    if tabs[pos] then
      local w = tabs[pos].win
      if w and win ~= w then
        if hs.dialog.blockAlert("Replace existing tab "..w:title().."?", "", "No", "Replace") == "Replace" then
          print("Overwriting "..w:title())
        else
          -- placeTab = false
        end
      end
    end
  end

  if placeTab or pos == QuickTab then
    print("-- hide window chrome, which is animated")
    local toolbarState = prepWindow(win, pos, false)

    print("-- wait for prepWindow to finish before moving window or the window state gets confused")
    hs.timer.doAfter(prepDuration, function() 
      print("-- reduce width first with anim=0, since MacOS won't do that if moving a window partially off screen")
      win:setFrame({ x=winFrame.x, y=winFrame.y, w=tabRect.w, h=winFrame.h },0)

      print("-- the window may have a minimum width, so see what width we actually got")
      local actualRect = hs.window.focusedWindow():frame()

      print("-- if putting in pos QuickTab correctly place it at RHS of screen")
      if pos == QuickTab and actualRect.w > tabRect.w then
        tabRect.x = screen:frame().w - actualRect.w -5
      end

      print("-- place the window")
      win:setFrame(tabRect)

      print("-- update the tab and hotkeys")
      if pos ~= QuickTab then
        local showKey,hideKey

        print("-- if window exists in another tab, remove old one")
        dump(tabs)
        for t = 1,numTabs do
          if t ~= pos then
            print("-- checking "..t)
            if tabs[pos] and tabs[pos].win then
              print("-- found tab")
              if win:title() == tabs[pos].win:title() then
                print("-- same window -> removing hotkey")
                print("Removing old tab")
                if tabs[t].showKey then unbindKey(tabs[t].showKey) end
                tabs[t] = {}
              end
            end
          end
        end

        print("-- bind hyper key")
        showKey = bindKey(hyper, ""..pos, "Show window: "..win:title(), function() obj:restore(pos) end)
        hideKey=tabs[pos].hideKey
        dump(toolbarState)
        tabs[pos] = { pos=pos, win=win, full=winFrame, toolbarState=toolbarState, hideKey=hideKey, showKey=showKey }
        dump(tabs)

        saveSettings(ftAppKey, ftTableKey, tabs)
      end
    end)
  end
end


--- Shelf:place(pos)
--- Method
--- Shelve the current window into a position at the bottom of the screen.  If the window
--- is already shelved, restore it to it's prior position.  place() will attempt to size
--- the window to not overlap the next slot, but the window may have a minimimum width that
--- prevents this.
---
--- Parameters:
---  * pos - the slot to place the window in, starting from slot 1.  If pos > numTabs,
---          the window may be placed off the screen
---
--- Returns:
--- * The shelf object
---
function obj:place(pos)
  -- ** place **
  --* get focused window, determine the slot frame
  local win = hs.window.focusedWindow()
  local winFrame = win:frame()
  local screen = win:screen()
  local screenBottom = screen:frame().h
  local width = 320 
  local tabRect = {}

  -- determine if we're showing or tabing the window, based on whether if it's at the bottom of the screen
  if pos == QuickTab then
    tabRect = { x=screen:frame().w -width-5, y=screenBottom, w=width-10, h=200.0 }
  else
    tabRect = { x=(pos-1)*width+5, y=screenBottom, w=width-10, h=200.0 }
  end
  local atBottom = comp(winFrame.y, tabRect.y)

  if atBottom then
    place_ShowTab(win, pos)
  else
    place_HideTab(win, pos, screen, winFrame, tabRect)
  end

  return self
end


function prepWindow(win, pos, restoring)
  local toolbarState = false
  local finder = hs.appfinder.appFromName("Finder")

  if win:application() == finder then
    if restoring then
      toolbarState = tabs[pos].toolbarState
      print("prep Finder for restore")
      if toolbarState then
        finder:selectMenuItem("Show Toolbar")
      end

    else
      print("prep Finder for place")
      -- findMenuItem returns nil or state { enabled = true, ticked = false }
      toolbarState = finder:findMenuItem("Hide Toolbar") or false
      if toolbarState then
        finder:selectMenuItem("Hide Toolbar")
      end
    end
  end

  return toolbarState
end


--- Shelf:switch() 
--- Method
--- Switch to the previous frame of the window.  If the window is shelved, this will return it
--- to its full size; if it has a tabs slot and is currently full size, this will place it
--- back on the tabs (without needing to recall which slot it was in).  If it's never been
--- shelved and there's room, put it in the next available slot
---    
--- Returns:
--- * The shelf object
---
function obj:switch(pos)
  -- ** switch **
  local win = hs.window.focusedWindow()
  if win and pos then
      obj:place(pos)
  else
    show("No tab found")
  end
  return self
end

--- Shelf:restore() 
--- Method
--- Restore the window at pos to the previous frame of the window.  
---
--- Parameters:
---  * pos - the slot to restore
---
--- Returns:
--- * The shelf object
---
function obj:restore(pos)
  -- ** restore **
  local tab = tabs[pos]
  if tab and tab.win then
    tab.win:focus()
    obj:switch(pos)
  else
    -- show("Nothing in tabs "..pos)
  end
  return self
end

function obj:shelve()
  -- ** shelve **

  local tab = tabs[QuickTab]
  if tab and tab.win then
    tab.win:focus()
    obj:restore(QuickTab)
  else
    local focusedWin = hs.window.focusedWindow()

    for t=1,numTabs do
      if tabs[t] and tabs[t].win == focusedWin then
        tabs[t] = {}
      end
    end

    obj:place(QuickTab)
  end
  return self
end


function onRestoreWindow(mods,item)
  print("\n ----------------- onRestoreWindow -----------------")

end


function getFTMenu()
  local menu = {}

  -- if usePopupMenu then
    table.insert(menu, { title = "􀎦 Pinned Windows:", disabled=true})
    table.insert(menu, { title = "-" })
  -- end

  local _numTabs = 0
  for t = 1,numTabs do
    local w = tabs[t].win
    if w then
      table.insert(menu, { title = "     "..w:title(), fn=function() obj:restore(t) end, shortcut=''..t })
      _numTabs = _numTabs + 1
    end
  end
  local s = tabs[QuickTab]
  if s and s.win then
    table.insert(menu, { title = "-" })
    table.insert(menu, { title = "     "..s.win:title(), fn=function() obj:restore(QuickTab) end, shortcut=''..0 })
    _numTabs = 1
  end
  if _numTabs == 0 then
    table.insert(menu, { title = "     No pinned windows", disabled=true })
  end

  usePopupMenu = nil
  return menu
end

function updateFTMenu()
  ftMenu
    :setTitle(ftTitle)
    :setMenu(getFTMenu)
    :returnToMenuBar()
end


bindKey(hyper, "f", "Show Finder Tabs", function()
  usePopupMenu = true
  local menu = hs.menubar.new():setMenu(getFTMenu)
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    menu:popupMenu({x=rect.x+rect.w/2-60,y=rect.y+rect.h/4})
  else
    local rect = hs.screen.mainScreen():frame() 
    menu:popupMenu(rect)
  end
end)


obj:setupTabs(5)

if ftMenu then
  restoreSettings(ftAppKey, ftTableKey, tabs)
  updateFTMenu()
end

print("** Loaded finderTabs **")

return obj

