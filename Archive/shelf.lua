require "utils"

local obj={}
obj.__index = obj

-- Locals

local shelf = {} -- { pos, win, shelfRect, fullRect, putkey, getkey, toolbar }
local slots = 5
-- use the shelf[0] slot for the shelve() command

local function comp(x,y)
  return math.abs(x-y) < 5 
end


-- Public

--- Shelf.slots
--- Variable
--- Integer, the number of slots across the screen to place windows in

function obj:setSlots(num)
  oldnum = slots
  for i=1,slots do
    if shelf[i] then
      unbindKey(shelf[i].putKey)
      unbindKey(shelf[i].getKey)
    end
  end

  slots = min(num,9)
  for i=1,slots do
    shelf[i]={}
    -- shelf[i].getKey = bindKey(hyper, ""..i, "Show window in shelf slot "..i, function() obj:restore(i) end)
    shelf[i].putKey = hs.hotkey.bind(shyper, ""..i, function() obj:place(i) end)
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
---  * pos - the slot to place the window in, starting from slot 1.  If pos > Shelf.slots,
---          the window may be placed off the screen
---
--- Returns:
--- * The shelf object
---
function obj:place(pos)
  -- ** place **
  --* get focused window, determine the slot frame
  local _win = hs.window.focusedWindow()
  local _winFrame = _win:frame()
  local _screen = _win:screen()
  local _screenBottom = _screen:frame().h
  local _width = 320 
  local _shelfRect = {}
  if pos == 0 then
    _shelfRect = { x=_screen:frame().w -_width-5, y=_screenBottom, w=_width-10, h=200.0 }    
  else
    _shelfRect = { x=(pos-1)*_width+5, y=_screenBottom, w=_width-10, h=200.0 }
  end

  local _restoreWindow = comp(_winFrame.y, _shelfRect.y) 
  if _restoreWindow then
    -- need to wait for prepWindow to finish before moving window or the window state gets confused
    _win:setFrame(shelf[pos].full)
    hs.timer.doAfter(0.25, function() 
      prepWindow(_win, pos, true)
      if pos == 0 then
        -- clear the shelf so that other windows can use it
        shelf[0] = {}
      end
    end)
  
  else
    -- need to wait for prepWindow to finish before moving window or the window state gets confused
    local _dur, _toolbar = prepWindow(_win, pos, false)
    hs.timer.doAfter(_dur, function() 
      -- reduce width first with anim=0, since MacOS won't do that if moving a window partially off screen
      _win:setFrame({ x=_winFrame.x, y=_winFrame.y, w=_shelfRect.w, h=_winFrame.h },0)  

      -- the window may have a minimum width, so see what width we actually got
      local _actualRect = hs.window.focusedWindow():frame()

      -- if putting in pos 0 correctly place it at RHS, 
      if pos == 0 and _actualRect.w > _shelfRect.w then
        _shelfRect.x = _screen:frame().w - _actualRect.w -5
      end
      _win:setFrame(_shelfRect)

      local _getKey,_putKey
      if pos > 0 then
        if shelf[pos].getKey then unbind(shelf[pos].getKey) end
        _getKey = bindKey(hyper, ""..pos, "Show window: ".._win:title(), function() obj:restore(pos) end)
        _putKey=shelf[pos].putKey
      end
      shelf[pos] = { pos=pos, win=_win, full=_winFrame, small=_shelfRect, toolbar=_toolbar, putKey=_putKey, getKey=_getKey }
    end)  
  end

  return self
end

function prepWindow(win, pos, restoring)
  local _prepDuration = 0
  local _toolbarState
  local finder = hs.appfinder.appFromName("Finder")

  if win:application() == finder then
    if restoring then
      _toolbarState = shelf[pos].toolbar 
      print("prep Finder for restore")
      if _toolbarState then
        finder:selectMenuItem("Show Toolbar")
        _prepDuration = 0.5
      end

    else
      print("prep Finder for place")
      _toolbarState = finder:findMenuItem("Hide Toolbar")
      if _toolbarState then
        finder:selectMenuItem("Hide Toolbar")
        _prepDuration = 0.5
      end
    end
  end

  return _prepDuration, _toolbarState
end


--- Shelf:switch() 
--- Method
--- Switch to the previous frame of the window.  If the window is shelved, this will return it
--- to its full size; if it has a shelf slot and is currently full size, this will place it
--- back on the shelf (without needing to recall which slot it was in).  If it's never been
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
    show("No shelf found")
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
  local s = shelf[pos]
  if s and s.win then
    s.win:focus()
    obj:switch(pos)
  else
    -- show("Nothing in shelf "..pos)
  end
  return self
end

function obj:shelve()
  -- ** shelve **

  local _shelf = shelf[0]
  if _shelf and _shelf.win then
    _shelf.win:focus()
    obj:restore(0)
  else
    local _focusedWin = hs.window.focusedWindow()

    for i=1,slots do
      if shelf[i] and shelf[i].win == _focusedWin then
        shelf[i] = {}
      end
    end

    obj:place(0)
  end
  return self
end

obj:setSlots(5)
print("** Loaded shelf **")

return obj

