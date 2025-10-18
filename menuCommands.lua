--
-- Command line menu finding thing
--

-- [/] Match menu items with regex
-- [/] Get target from keyboard
-- [] Execute menu item
-- [/] HUD on screen
-- [/] Handle options
-- [] Preload on application switch

require "utils"

MCMenuItems = {}
MCMatchingMenuItems = {}
MCChoices = {}
MCChooser = nil
MCAppWatcher = nil


function refreshCommandHUD(str) 
  MCChoices = {}
  if #str > 1 then
    local items = findMatchingMenuItems(str, MCMenuItems)
    MCMatchingMenuItems = toSet(items)
    run(
      MCMatchingMenuItems, 
      function(_,v) 
        local choice = {}
        choice.text = v
        table.insert(MCChoices, choice)
      end)
    end

  -- table.sort(
  --   MCChoices, 
  --   function(a,b)
  --     if string.match(a.text, " > ") and not string.match(b.text, " > ") then
  --         return true
  --     elseif string.match(b.text, ">") then
  --       return false
  --     else
  --       return a.text <= b.text
  --     end
  --   end)
  -- dump(matches, "refreshCommandHUD")
  MCChooser:choices(MCChoices)
end


function commandHUDSelection(chosen)
  if chosen and chosen.text then
    print(chosen.text)
    hs.application.frontmostApplication():selectMenuItem(chosen.text  )
  end
  MCChooser:delete()
end


function showCommandHUD()
  MCChooser = hs.chooser.new(commandHUDSelection)
  MCChooser:queryChangedCallback(refreshCommandHUD)
  MCChooser:searchSubText(false)
  MCChooser:placeholderText("Search "..hs.application.frontmostApplication():title().." commands")
  MCChooser:show()
end


function findMatchingMenuItems(target, menuItems)
  local matches = {}

  for _,item in ipairs(menuItems) do
    if item.AXTitle ~= nil then

      local children = item.AXChildren
      local title = item.AXTitle:lower()
      local match = string.find(title, target)

      -- if menu has a submenu
      if children then
        local subs = {}
        if title == target then -- if user typed menu title, add all items in a submenu
          run(children[1], function(k,v)
            if v.AXTitle == "" then
              -- table.insert(subs, "------" )
            elseif v.AXTitle then
              table.insert(subs, item.AXTitle.." > "..v.AXTitle)
            else
              -- no title
            end
          end)

        else -- otherwise look for partials in submenu
          subs = findMatchingMenuItems(target, children[1])
        end
        addAllUnique(matches, subs)

      -- otherwise add menuitem if it matches
      else
        if match and not contains(matches, item.AXTitle) then
          table.insert(matches, item.AXTitle)
        end
      end
    end
  end

  return matches
end


function findMenuItems(target, menuItems)
  MCMatchingMenuItems = findMatchingMenuItems(target, MCMenuItems)
  run(searchMatches, function(i,m) print(i.."  "..m) end)
end


function ShowMCMenu()
  print("showMCMenu")
  if #MCMenuItems == 0 then
    hs.application.frontmostApplication():getMenuItems(onGotMCItemsLaunch)
  else
    showCommandHUD()
  end
end


function onGotMCItemsLaunch(items)
  MCMenuItems = items
  showCommandHUD()
end

function onGotMCItems(items)
  MCMenuItems = items
end


function onMCAppSwitch(appName, event, app)
  if event == hs.application.watcher.activated then
    MCMenuItems = {}
    hs.application.frontmostApplication():getMenuItems(onGotMCItems)
  end
end


bindKey(hyper, "space", "Menu Commands", ShowMCMenu)

MCAppWatcher = hs.application.watcher.new(onMCAppSwitch)
MCAppWatcher:start()

print("** Loaded menukeys **")
