------
-- Window Widths

XStep,YStep = 150,100

function moveWindow(xdiff, ydiff)
  local _app = hs.application.frontmostApplication()
  if _app then
    local _win = _app:focusedWindow()
    if _win then
      local _f = _win:frame()
      if _f.x+xdiff < 0 then
        _win:setFrame(hs.geometry.rect(_f.x+xdiff, max(0,_f.y+ydiff), _f.w, _f.h), 0.1)
        hs.timer.doAfter(0.1, function()
          _win:setFrame(hs.geometry.rect(max(0,_f.x+xdiff), max(0,_f.y+ydiff), _f.w, _f.h), 0.1)
        end)
      else
      _win:setFrame(hs.geometry.rect(max(0,_f.x+xdiff), max(0,_f.y+ydiff), _f.w, _f.h), 0.1)
      end
    end
  end
end


function resizeWindow(xdiff, ydiff, moveOtherWins)
  local _app = hs.application.frontmostApplication()
  if _app then
    local _win = _app:focusedWindow()
    local _screen = _win:screen()

    if _win then
      -- reframe the top window
      local _f = _win:frame()

      local _newF = hs.geometry.rect(_f.x, _f.y, _f.w+xdiff, _f.h+ydiff)
      _win:setFrame(_newF, 0.1)

      if hs.hid.capslock.get() then
      -- if moveOtherWins then
        show("Laying out screen")
        local _wins = {}

        -- determine windows strictly to east/south to move
        if xdiff ~= 0 then
          local _eastWins = _win:windowsToEast()
          for _,ew in ipairs(_eastWins) do
            if ew:frame().x >= _f.x+_f.w then table.insert(_wins, ew) end
          end
        else
          local _southWins = _win:windowsToSouth()
          for _,sw in ipairs(_southWins) do
            if sw:frame().y >= _f.y+_f.h then table.insert(_wins, sw) end
          end
        end

        -- move them
        for _,w in ipairs(_wins) do
          if w ~= _win and w:isVisible() and w:screen() == _screen then
            local _wf = w:frame()
            local _nF = hs.geometry.rect(_wf.x+xdiff, _wf.y+ydiff, _wf.w-xdiff, _wf.h-ydiff)
            w:setFrame(_nF, 0.1)
          end
        end
      end

    end
  end
end

function increaseWindowWidth()
  resizeWindow(XStep, 0, false)
end

function decreaseWindowWidth() 
  resizeWindow(-XStep, 0, false)
end

function increaseWindowSpine()
  resizeWindow(XStep, 0, true)
end

function decreaseWindowSpine() 
  resizeWindow(-XStep, 0, true)
end


function moveWindowLeft()
  moveWindow(-XStep, 0)
end

function moveWindowRight()
  moveWindow(XStep, 0)
end

function moveWindowUp()
  moveWindow(0, -YStep)
end

function moveWindowDown()
  moveWindow(0, YStep)
end


function increaseWindowHeight()
  resizeWindow(0, YStep, false)
end

function decreaseWindowHeight()
  resizeWindow(0, -YStep, false)
end

function increaseWindowFold()
  resizeWindow(0, YStep, true)
end

function decreaseWindowFold() 
  resizeWindow(0, -YStep, true)
end

-- winmover
bindKey(hyper, "i", "Decrease window height", decreaseWindowHeight, nil, decreaseWindowHeight)
bindKey(hyper, "j", "Decrease window width", decreaseWindowWidth, nil, decreaseWindowWidth)
bindKey(hyper, "k", "Increase window height", increaseWindowHeight, nil, increaseWindowHeight)
bindKey(hyper, "l", "Increase window width", increaseWindowWidth, nil, increaseWindowWidth)

bindKey(shyper, "i", "Move up", moveWindowUp, nil, moveWindowUp)
bindKey(shyper, "j", "Move left", moveWindowLeft, nil, moveWindowLeft)
bindKey(shyper, "k", "Move down", moveWindowDown, nil, moveWindowDown)
bindKey(shyper, "l", "Move right", moveWindowRight, nil, moveWindowRight)

-- bindKey(shyper, "i", "Reframe up", decreaseWindowFold)
-- bindKey(shyper, "j", "Reframe left", decreaseWindowSpine)
-- bindKey(shyper, "k", "Reframe down", increaseWindowFold)
-- bindKey(shyper, "l", "Reframe right", increaseWindowSpine)
  
print("** Loaded winmover **")