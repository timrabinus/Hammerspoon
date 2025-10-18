------
-- Settings

-- Demo app to understand how hs.settings works

-- requires "utils"

settings = hs.menubar.new()
settingsKey="mb_settings"
data = {
  { name="one", value=1 },
  { name="II", value={x=1,y=1,w=1,h=2} },
  "three",
  4
}
snapshots = {}

settings:setTitle("?") -- display.and.arrow.down

function onAdd()
  show("onAdd")

  local btn,_name = hs.dialog.textPrompt(
    "",
    "Add to settings:", 
    "Settings info "..#data+1, 
    "OK", "Cancel")
  if btn=="Cancel" or _name=="" then 
    return 
  end
 
  table.insert(data,_name)
  hs.settings.set(settingsKey..".data."..#data,data[#data])

  local _snapshot = hs.screen.mainScreen():snapshot():setSize({h=128,w=128})
  table.insert(snapshots,_snapshot)
  hs.settings.set(settingsKey..".snapshots."..#data,_snapshot:encodeAsURLString())
  -- hs.settings.setData(settingsKey..".snapshot."..#snapshots,_snapshot)

  updateSettingsMenu()
end 

function onSave()
  show("onSave")
  for i,v in ipairs(data) do
    hs.settings.set(settingsKey..".data."..i,data[i])
  end
end

function onRestore()
  show("onRestore")
  for i,key in ipairs(hs.settings.getKeys()) do
    local keys = split(key,'.') -- {app,var,index}
    if keys[1] == settingsKey then
      local val = hs.settings.get(key)
      print("-- restoring settings key = "..keys[2].."["..keys[3].."] = "..hs.inspect(val))
      if keys[2] == "data" then
        data[tonumber(keys[3])] = val
      elseif keys[2] == "snapshots" then
        snapshots[tonumber(keys[3])] = hs.image.imageFromURL(val)
      else
        print("Unknown key: ",keys[2])
      end
    else
      print("--     ignoring settings key = "..key)
    end
  end

  updateSettingsMenu()
end

function onClear()
  show("onClear")
  local btn,_name = hs.dialog.textPrompt(
    "",
    "Remove from settings:", 
    settingsKey..".data.", 
    "OK", "Cancel")
  if btn=="Cancel" or _name=="" then 
    return 
  end

  hs.settings.clear(_name)
  fields = split(_name,'.')
  if #fields == 3 and fields[1] == settingsKey and fields[2] == "data" then
    data[tonumber(fields[3])] = nil
  end
  updateSettingsMenu()
end

function onClearAll()
  show("onClearAll")
  data={}
  updateSettingsMenu()
end

function addDataMenu(mtable)
  table.insert(mtable, { title = "-" })
  table.insert(mtable, getMenuItem(hs.settings.bundleID,nil,nil,true))  

  for i,v in ipairs(data) do
    local img = nil
    if snapshots[i] then
      img = snapshots[i]
    end
    table.insert(mtable, getMenuItem(i..": "..hs.inspect.inspect(v),nil,nil,nil,img))
  end
  
  return mtable
end

function updateSettingsMenu()
  mtable = {}

  table.insert(mtable, getMenuItem("Add",onAdd))
  table.insert(mtable, { title = "-" })

  table.insert(mtable, getMenuItem("Save",onSave))
  table.insert(mtable, getMenuItem("Restore",onRestore))
  table.insert(mtable, getMenuItem("Clear",onClear))
  table.insert(mtable, getMenuItem("Clear All",onClearAll))

  mtable = addDataMenu(mtable)

  settings:setMenu(mtable)
end

-- function screensChanged()
--   print("screensChanged")
--   updateSettingsMenu()
-- end

-- if settings then
--   updateSettingsMenu()
-- end

