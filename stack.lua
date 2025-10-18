------
-- Task Stack

require "utils"

TS_Title = "􀏕" -- rectangle.badge.checkmark
stacks = {}


function getMenuTitle()
  flags = { "", "􀃊", "􀃌", "􀃎", "􀃐", "􀃒", "􀃔", "􀃖", "􀃘", "􀃚", "􀃜"}
  local count = hs.fnutils.filter(stacks, function(_s) return _s.done == 0 end )
  return TS_Title..flags[min(#count,#flags-1)+1]
end

ss_FullImgSize = 1024
ss_ImgSize = 64

stackstar = hs.menubar.new()
stackstar:setTitle(getMenuTitle()) 
showing = nil
order = 1
lastMousePosition = nil
markCompleteHotKey = nil
usePopupMenu = nil

----

ssAppKey="mb_settings_stack"
ssTableKey="stacks"

----

function sortStack(s1,s2) 
  return 
        (s1.done < s2.done)
    or  (s1.done == s2.done 
        and (
                (order==1 and s1.time > s2.time)
            or  (order==2 and s1.time < s2.time)
            or  (order==3 and string.upper(s1.name) < string.upper(s2.name)))
        )
end


function unbindShowingKeys()
  if markCompleteHotKey then
    -- print("unbinding...")
    unbindKey(markCompleteHotKey)
    markCompleteHotKey = nil
    unbindKey(keepIncompleteHotKey)
    keepIncompleteHotKey = nil
  else
    -- print("key not bound")
  end
  showing.drawing:hide(.75)
  showing = nil
end


function keepIncomplete()
  if showing then
    local i,_stack = match(stacks, function(_s)
      return _s.name == showing.stack.name
    end)
    unbindShowingKeys()
  end
end


function markComplete()
  if showing then
    local i,_stack = match(stacks, function(_s)
      return _s.name == showing.stack.name
    end)

    show("Completed: "..stacks[i].name)
    stacks[i].done = 1 
    table.sort(stacks, sortStack)

    unbindShowingKeys()
    updateSSMenu()
  end
end


function onDrawingMouseDown()
end


function onDrawingMouseUp()
  if showing then
    local ok = "Yes"
    if hs.dialog.blockAlert("Completed?", "", ok, "No") == ok then
      markComplete()
    else
      showing.drawing:hide(.75)
      showing = nil
    end
  end
end


function onSelectSave(mods, item)
  if showing then
    showing.drawing:hide(.75)
    showing = nil
  end

  local _,_stack = match(stacks, function(_s)
    return _s.name == item.title
  end)
  local image = hs.image.imageFromURL(_stack.snapshot)
  local size = image:size()
  local frame = hs.screen.mainScreen():frame()

  local _drawing = hs.drawing.image({x=frame.x+frame.w-size.w-40,y=40,w=size.w,h=size.h}, image)
  _drawing
      :imageFrame("photo")
      :setClickCallback(onDrawingMouseDown,onDrawingMouseUp)
      :show()
  showing = { drawing = _drawing, stack = _stack }

  show("Press hyper ↵ to mark complete or click for menu")

  markCompleteHotKey = bindKey(hyper, "return", "Mark task as complete", function()
    markComplete()
  end)

  keepIncompleteHotKey = bindKey("", "escape", "Keep task", function()
    keepIncomplete()
  end)

end


function onAddTask()
  if showing then
    showing.drawing:hide(.75)
    showing = nil
  end

  local app,_snapshot = hs.application.frontmostApplication(),nil
  if app then
     _snapshot = app:focusedWindow():snapshot()
  else
    _snapshot = hs.screen.mainScreen():snapshot()
  end

  local size = _snapshot:size()
  _snapshot = _snapshot
      :setSize({w=size.w/3,h=size.h/3})
      :encodeAsURLString()

  hs.focus()
  local btn,_name = hs.dialog.textPrompt(
    "Add Task\t\t\t\t\t", 
    "", -- "Add task to "..string.lower(getOrderName()),
    "",
    "OK", "Cancel")
  if btn=="Cancel" or _name=="" then 
    return 
  end

  table.insert(stacks, { 
    id = #stacks+1,
    time = os.date("%I:%M:%S"), 
    name = _name, 
    snapshot = _snapshot,
    done = 0 })
  table.sort(stacks, sortStack)
  updateSSMenu()
end

--- 


function onClearCompleted() 
  clearSettings(ssAppKey,ssTableKey,stacks) 
  local count = 0
  for s = #stacks,1,-1 do
    if stacks[s].done == 1 then
      table.remove(stacks,s)
      count = count+1
    end
  end
  updateSSMenu()
 
  show("Cleared "..count.." task"..(count > 1 and "s" or ""))
end


function onClearAll() 
  clearSettings(ssAppKey,ssTableKey,stacks) 
  local count = 0
  for s = #stacks,1,-1 do
    table.remove(stacks,s)
  end
  updateSSMenu()
end


function onChangeOrder(_order)
  order = _order
  table.sort(stacks, sortStack)
  updateSSMenu()
end

----

function getOrderMenu()
  local mtable = {}
  table.insert(mtable, { title = getOrderName(1),  fn=function() onChangeOrder(1) end, checked=order==1 })
  table.insert(mtable, { title = getOrderName(2),  fn=function() onChangeOrder(2) end, checked=order==2 })
  table.insert(mtable, { title = getOrderName(3),  fn=function() onChangeOrder(3) end, checked=order==3 })
  return mtable
end


-- function getStackMenu(date)
--   local mtable = {}
--   for l = 1,4 do
--     table.insert(mtable,getMenuItem("Save "..l,onSelectSave))
--   end
--   return mtable
-- end


function getOrderName(order)
  if order == 1 then
    return "Newest First"
  elseif order == 2 then
    return "Oldest First"
  else
    return "By Name"
  end
end


function getSSMenu()
  local mtable = {}
  local pad = ""

  if usePopupMenu then
    table.insert(mtable, { 
      title="􀥂 Quick Tasks ("..getOrderName().."):",
      disabled=true})
    table.insert(mtable, { title = "-" })
    pad = "      "
  end

  for s = 1,#stacks do
    local stack=stacks[s]
    table.insert(mtable, { 
      title=pad..stack.name, 
      fn=function(mods,item) onSelectSave(mods, {title=stack.name}) end,
      disabled=stack.done==1,
      checked=stack.done==1,
      shortcut=(stack.done==0 and s<10 and ""..s or "") })
  end

  table.insert(mtable, { title = "-" })
  table.insert(mtable, { title = pad.."Add New Task...", fn=onAddTask,shortcut='a'})
  table.insert(mtable, { title = pad.."Clear Completed", 
      fn=onClearCompleted,shortcut="c",
      disabled=not any(stacks, function(_s) return _s.done==1 end) })
  table.insert(mtable, { title = pad.."Clear All Tasks", 
      fn=onClearAll,shortcut="t",
      disabled=#stacks == 0 })

  -- if not usePopupMenu then
    table.insert(mtable, { title = "-" })
    table.insert(mtable, { title = pad.."Order", menu=getOrderMenu() })
  -- end

  usePopupMenu = false
  return mtable
end


function updateSSMenu()
  stackstar
    :setMenu(getSSMenu)
    :setTitle(getMenuTitle())
    :returnToMenuBar()
  
  saveSettings(ssAppKey,ssTableKey,stacks)
end


function popupMenu()
  usePopupMenu = true
  local menu = hs.menubar.new():setMenu(getSSMenu())
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    menu:popupMenu({x=rect.x+rect.w/2-150,y=rect.y+rect.h/4})
  else
    local mousePosition = lastMousePosition or hs.mouse.absolutePosition()
    -- DUMP{mousePosition=mousePosition}
    menu:popupMenu(mousePosition)
  end
end


if stackstar then
  print("\n ================================================= Started Stack")
  restoreSettings(ssAppKey,ssTableKey,stacks)
  updateSSMenu()
end

bindKey(hyper, "a", "Add quick task", onAddTask)

bindKey(hyper, "q", "Show quick tasks", function()
  popupMenu()
end)

print("** Loaded stack **")