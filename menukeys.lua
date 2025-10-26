--
-- Emulate windows-like alt key processing in a popupMenu
--

MK_Menu = hs.menubar.new()
-- MK_Icon = "􀱢" -- filemenu.and.selection
MK_Icon = "􀭈" -- filemenu.and.selection
MK_Menu:setTitle(MK_Icon)
MK_MenuLoc = {}
MK_AppWatcher = nil
MK_MenuItems = {}
MK_CommonKeys = {
  ["Settings…"]=",",
  ["Save"]="s",
  ["Save As…"]="a",
  ["Save All"]="l",
  ["Print"]="p",
  ["Print…"]="p",
  ["Print..."]="p",
  ["Select All"]="a",
  ["Show in Finder"]="f",
  ["New Finder Window"]="w",
  ["Cut"]="x",
  ["Copy"]="c",
  ["Paste"]="v",
  ["File"]="f",
  ["Find Next"]=">",
  ["Find Previous"]="<",
  ["Find…"]="f",
  ["Find"]="f",
  ["Replace"]="r",
  ["Delete"]="d",
  ["Duplicate"]="u",
  ["Tile Window to Left of Screen"]="[",
  ["Tile Window to Right of Screen"]="]",
  ["Move Window to Left Side of Screen"]="{",
  ["Move Window to Right Side of Screen"]="}",
  ["Move Window to the Left Side of the Screen"]="{",
  ["Move Window to the Right Side of the Screen"]="}",
}

function buildWindowMenuItems()
  app = hs.application.frontmostApplication()
  if not app then return nil end

  local windows = app:allWindows()
  table.sort(windows, function(a,b) return a:title() < b:title() end)

  local windowItems = {}
  local index = 1

  for _, window in ipairs(windows) do
    print(window)
    local title = window:title()
    if title ~= nil and title ~= "" then
      table.insert(windowItems, {
          title="     􃑷  "..title,
          fn=function(cmd,item) bringToFront(window) end,
          shortcut=""..index})
      index = index + 1
    end
  end
  return windowItems
end


function bringToFront(window)
  if window then
    window:unminimize()
    window:focus()
  end
end


-- [] Fix duplicate "Save As…" (same key) and "Close Window" (diff keys)

-- Find keys that are common, like Save etc
function getCommonShortcut(existing, title)
  -- print("? '"..title.."'")
  if title ~= nil and title ~= "" and title ~= "-" then
    local key = MK_CommonKeys[title]
    if key ~= nil and not contains(existing, key) then
      -- prefer matching upper case if available
      local upperKey = key:upper()
      for i = 1, #title do
        char = title:sub(i, i)
        if char == upperKey then
          local newTitle = hs.styledtext.new(" "..title):setStyle({underlineStyle=hs.styledtext.lineStyles.single}, i+1, i+1)
          table.insert(existing, key)
          return existing, key, newTitle
        end
      end
      -- else match lower
      for i = 1, #title do
        char = title:sub(i, i):lower()
        if char == key then
          local newTitle = hs.styledtext.new(" "..title):setStyle({underlineStyle=hs.styledtext.lineStyles.single}, i+1, i+1)
          table.insert(existing, key)
          return existing, key, newTitle
        end
      end
      -- else shortcut is not in title; eg "Find Next" -> "]"
      table.insert(existing, key)
      return existing, key, " "..title
    end
  end
  return existing, "", ""
end


function getShortcut(existing, title)
  -- handle separators
  if title == nil or title == "" or title == "-" then
    return existing, "", ""
  end

  -- if first letter is not numeric, use numbers
  local char = title:sub(1,1):lower()
  if not string.match(char, "%a") then
    for i = 1,9 do
      char = tostring(i)
      if not contains(existing, char) then
        table.insert(existing, char)
        return existing, char, title
      end
    end
    return existing, "", title
  end

  -- first letter of word that's not in existing
  local newTitle = hs.styledtext.new("")
  local found = false
  local newChar = ""
  local newWord = ""
  for word in title:gmatch("%S+") do
    char = word:sub(1,1)
    if not found and string.match(char, "%u") and not contains(existing, char:lower()) then
      newWord = hs.styledtext.new(word):setStyle({underlineStyle=hs.styledtext.lineStyles.single}, 1, 1)
      newChar = char:lower()
      found = true
    else
      newWord = hs.styledtext.new(word)
    end
    newTitle = newTitle..hs.styledtext.new(" ")..newWord
  end
  if found then
    table.insert(existing, newChar)
    return existing, newChar, newTitle
  end

  -- first available letter in whole title
  for i = 1, #title do
    char = title:sub(i, i):lower()
    if string.match(char, "%a") then
      if not contains(existing, char) then
        local newTitle = hs.styledtext.new(" "..title):setStyle({underlineStyle=hs.styledtext.lineStyles.single}, i+1, i+1)
        table.insert(existing, char)
        return existing, char, newTitle
      end
    end
  end

  -- nothing
  return existing, "", " "..title
end


-- The table is nested with the same structure as the menus of the application. 
-- Each item has several keys containing information about the menu item. Not all keys will 
-- appear for all items. The possible keys are:
--
-- AXTitle - A string containing the text of the menu item (entries which have no title 
--     are menu separators)
-- AXEnabled - A boolean, 1 if the menu item is clickable, 0 if not
-- AXRole - A string containing the role of the menu item - this will be either 
--     AXMenuBarItem for a top level menu, or AXMenuItem for an item in a menu
-- AXMenuItemMarkChar - A string containing the "mark" character for a menu item. This is
--     for toggleable menu items and will usually be an empty string or a Unicode tick 
--     character (✓)
-- AXMenuItemCmdModifiers - A table containing string representations of the keyboard 
--     modifiers for the menu item's keyboard shortcut, or nil if no modifiers are present
-- AXMenuItemCmdChar - A string containing the key for the menu item's keyboard shortcut, 
--     or an empty string if no shortcut is present
-- AXMenuItemCmdGlyph - An integer, corresponding to one of the defined glyphs in 
--     hs.application.menuGlyphs if the keyboard shortcut is a special character usually 
--     represented by a pictorial representation (think arrow keys, return, etc), or an 
--     empty string if no glyph is used in presenting the keyboard shortcut.
--
-- Using hs.inspect() on these tables, while useful for exploration, can be extremely slow, 
-- taking several minutes to correctly render very complex menus

function getMenuKeysMenu(menu, isAppMenu, parentTitle)
  local popupMenu = {}
  local lastItemWasSeparator = false
  local keys = {}
  local commonShortcuts = {}
  local lastTitle
  local cpad = "    "
  local appendWindows = false
  local windowTitles = {}
  local windowShortcut = 1

  if menu == nil then return end

  -- Insert parent title at top and recognise window titles if in Window menu
  if parentTitle ~= nil then
    newTitle = MK_Icon.." "..parentTitle
    table.insert(popupMenu, { title=MK_Icon.." "..parentTitle, disabled=true })
    table.insert(popupMenu, { title = "-" })    

    if parentTitle == 'Window' then
      -- get the last group of titles, so that we can order by name (?) and put numbers as shortcuts
      for m = #menu,1,-1 do
        local item = menu[m]
        local title = item.AXTitle
        if title == "" then
          break
        else
          table.insert(windowTitles, title)
        end
      end
      dump(windowTitles, "Window titles")
    end
  end

  -- initialise keys with any common shortcuts, eg for Save etc
  for m = 1,#menu do
    local item = menu[m]
    local title = item.AXTitle
    if parentTitle == 'Window' and contains(windowTitles, title) then
      key = tostring(windowShortcut)
      commonShortcuts[title] = {key=key, newTitle=(" "..title)}
      windowShortcut = windowShortcut + 1
    else
      keys, key, newTitle = getCommonShortcut(keys, title)
      if key ~= nil and key ~= "" then
        commonShortcuts[title] = {key=key, newTitle=newTitle}
      end
    end
  end
  -- dump(commonShortcuts)


  -- now assign keys for each menu item
  for m = 1,#menu do
    local item = menu[m]
    local title = item.AXTitle

    if title == "" then
      if lastItemWasSeparator then
        -- don't add two separators in a row
      else
        table.insert(popupMenu, { title = "-" })
      end
      lastItemWasSeparator = true

    elseif title == "Help" then
      -- skip help menu; windows will be placed after this if available

    else
      lastItemWasSeparator = false
      local children = item["AXChildren"]
      local key, newTitle

      -- if this item was a common shortcut, use that; else assign a new shortcut
      local shortcut = commonShortcuts[title]
      if shortcut ~= nil then
        key = shortcut.key
        newTitle = shortcut.newTitle
      else -- if item.AXEnabled then
        keys, key, newTitle = getShortcut(keys, title)
      end

      if children then

        if isAppMenu and m == 1 then
          newTitle = MK_Icon.." "..hs.application.frontmostApplication():name()
          -- use " " as shortcut and make prior shortcut key available for other menuitems
          removeElement(keys, key)
          key=" "
        else
          newTitle = hs.styledtext.new(cpad)..newTitle
        end

        if title == 'Window' then
          table.insert(popupMenu, { title = "-" })
          appendWindows = true
        end

        -- local submenu = getMenuKeysMenu(children[1], pad)
        local submenu = {}   -- otherwise submenu keys take the shortcut
        table.insert(popupMenu, {
          title=newTitle,
          -- indent=pad,
          fn=function(cmd,item) onParentMenuSelect(title,children[1],cmd,item) end,
          disabled=not item.AXEnabled,
          menu=submenu,
          shortcut=key
         })

        if isAppMenu and m == 1 then
          table.insert(popupMenu, { title = "-" })
          -- pad = pad+1
          -- cpad = "    "
        end
        -- print(title.."  "..key.." > ")

      elseif newTitle ~= nil and newTitle ~= lastTitle then
        lastTitle = newTitle
        newTitle = hs.styledtext.new(cpad)..newTitle

        table.insert(popupMenu, {
          title = newTitle,
          -- indent=pad,
          fn=function(cmd,item) onMenuSelect(title,cmd,item) end,
          disabled=not item.AXEnabled,
          checked=item.AXMenuItemMarkChar ~= "",
          shortcut=key })

      else
        -- dump(item, "title should not be nil")
      end
    end
  end

  if appendWindows then
    windowItems = buildWindowMenuItems()
    if windowItems and #windowItems > 0 then
      -- table.insert(popupMenu, { title = "-" })
      for w = 1, #windowItems do
        table.insert(popupMenu, windowItems[w])
      end
    end
  end

  return popupMenu
end


function onMenuSelect(title, cmds, item)
  -- dump(title, "Selected")
  local app = hs.application.frontmostApplication()
  local found = app:selectMenuItem(title)
  print(found)
end


function onParentMenuSelect(title, children, cmds, item)
  showPopupMenu(children, false, title)
end


function containsPoint(frame, point)
  return point.x >= frame.x and point.x <= frame.x + frame.w
     and point.y >= frame.y and point.y <= frame.y + frame.h
end

function showPopupMenu(menuItems, isAppMenu, parentTitle)
  local menuTable = getMenuKeysMenu(menuItems, isAppMenu, parentTitle)
  local hsMenu = hs.menubar.new():setMenu(menuTable)
  local app = hs.application.frontmostApplication()
  local win = app:focusedWindow()
  if isEmpty(MK_MenuLoc) then
    if win and not containsPoint(win:frame(), hs.mouse.absolutePosition()) then
      local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
      MK_MenuLoc = {x=rect.x+rect.w/2-60,y=rect.y+rect.h/4}
    else
      MK_MenuLoc= hs.mouse.absolutePosition()
    end
  end
  hsMenu:popupMenu(MK_MenuLoc)
end

function ShowMKMenu()
  MK_MenuLoc = {}
  if MK_MenuItems and #MK_MenuItems == 0 then
    hs.application.frontmostApplication():getMenuItems(onGetMKMenuItemsLaunch)
  else
    showPopupMenu(MK_MenuItems, true)
  end
end

function onGetMKMenuItems(menuItems)
  MK_MenuItems = menuItems
end


function onGetMKMenuItemsLaunch(menuItems)
  MK_MenuItems = menuItems
  showPopupMenu(menuItems, true)
end

function onMKAppSwitch(appName, event, app)
  if event == hs.application.watcher.activated then
    MK_MenuItems = {}
    hs.application.frontmostApplication():getMenuItems(onGetMKMenuItems)
  end
end



bindKey(hyper, "space", "Menu Keys", ShowMKMenu)

MK_AppWatcher = hs.application.watcher.new(onMKAppSwitch)
MK_AppWatcher:start()

print("** Loaded menukeys **")
