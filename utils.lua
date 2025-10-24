------
-- Utilities

hyper  = {"cmd","alt","ctrl"}
shyper = {"cmd","alt","ctrl","shift"}


function log(...)
  if Debug then 
    local args = {...}
    local string = ""
    for i = 1, #args do
      string = string .. " " ..args[i]
    end
    print(string)
  end
end

function dump(x,msg)
  if not msg then 
    print(hs.inspect(x))
  else
    print(msg..": "..hs.inspect(x))
  end
end

function asTitleCase(str)
  return (" "..str)                     -- make title case:
    :gsub("([a-z0-9])([A-Z])","%1 %2")  -- split camel case
    :gsub("['\"‘’“”]","")               -- remove quotes
    :gsub("[^ A-Za-z0-9]"," ")          -- remove punctuation
    :gsub(" +", " ")                    -- remove multiple spaces
    :lower()                            -- lower case
    :gsub("%W%l", string.upper)         -- capitalize words
    :gsub("^ +","")                     -- remove leading spaces
    :gsub(" +$","")                     -- remove trailing spaces
end
--
--
--

function get(v,default)
  return v and v or default
end
--
test("get", {
  existingValue = { args={5, 6}, expected=5, },
  noValue       = { args={nil, 6}, expected=6, },
  nilNil        = { args={nil, nil}, expected=nil, },
})


lastmsg = nil

function show(msg,dur)
  if msg ~= lastmsg then
    lastmsg = msg
    local alert = hs.alert.show(
      msg,
      {
        radius=15,
        fillColor={white=0.85},
        strokeColor={white=0.85},
        textColor={white=0},
        textSize=20,
        padding=18,
        fadeOutDuration=0.75
      },
      hs.screen.mainScreen(),
      get(dur,2)
    )
    hs.timer.doAfter(get(dur,2), function() lastmsg=nil end)
    return alert
  end
end

function min(a,b)
  return a<b and a or b
end
--
test("min", {
  pos     = { args={5, 6}, expected=5, },
  neg     = { args={-5, -6}, expected=-6, },
  testNil = { args={-0, 0}, expected=-0, },
})


function max(a,b)
  return a>b and a or b
end
--
test("max", {
  pos           = { args={5, 6}, expected=6, },
  neg           = { args={-5, -6}, expected=-5, },
  testNil       = { args={-0, 0}, expected=-0, },
  chars         = { args={"a","b"}, expected="b", },
  caseChars     = { args={"a","A"}, expected="a", },
  strings       = { args={"aa","ab"}, expected="ab", },
  stringLengths = { args={"aaa","aa"}, expected="aaa", },
})


function limit(low, value, high)
  if low > high then 
    return limit(high, value, low)
  else
    return min(max(low, value), high)
  end
end
--
test("limit", {
  inRange                 = { args={5, 6, 7}, expected=6, },
  flippedRange            = { args={9, 6, 1}, expected=6, },
  outLow                  = { args={5, 4, 7}, expected=5, },
  outHigh                 = { args={5, 8, 7}, expected=7, },
  negInRange              = { args={-5, -6, -7}, expected=-6, },
  negOutLow               = { args={-5, -8, -7}, expected=-7, },
  negOutHigh              = { args={-5, -4, -7}, expected=-5, },
  negInRangeOrderedParams = { args={-7, -6, -5}, expected=-6, },
  negOutLowOrderedParams  = { args={-7, -8, -5}, expected=-7, },
  negOutHighOrderedParams = { args={-7, -4, -5}, expected=-5, },
  posNegRange             = { args={-7, -4, 5}, expected=-4, },
  chars                   = { args={"a", "b", "c"}, expected="b", },
  strings                 = { args={"aa", "ab", "ac"}, expected="ab", },
})

--
--  List Functions
--

function isEmpty(dict)
  for k,v in pairs(dict) do
    return false
  end
  return true
end
--
test("isEmpty", {
  empty    = { args={{}}, expected=true, },
  notEmpty = { args={{5, 4, 7}}, expected=false, },
})


function containsKey(dict, key)
  for k,v in pairs(dict) do
    if k==key then return true end
  end
  return false
end
--
test("containsKey", {
  empty         = { args={{}, 1}, expected=false, },
  indexPresent1 = { args={{1}, 1}, expected=true, },
  indexPresent2 = { args={{2}, 1}, expected=true, },          -- compare with notPresent test for contains
  keyPresent    = { args={{one=1}, 'one'}, expected=true, },
  keyNotPresent = { args={{one=1}, 'two'}, expected=false, },
})


function contains (tab, val)
  for index, value in ipairs(tab) do
      if value == val then
          return true
      end
  end
  return false
end
--
test("contains", {
  empty      = { args={{}, 1}, expected=false, },
  isPresent  = { args={{1}, 1}, expected=true, },
  notPresent = { args={{2}, 1}, expected=false, },
})


function removeElement(list,element)
  local i = hs.fnutils.indexOf(list, element)
  if i then table.remove(list,i) end
  return i
end
--
test("removeElement", {
  empty      = { args={{}, 1}, expected=nil, },
  isPresent  = { args={{1}, 1}, expected=1, },
  notPresent = { args={{2}, 1}, expected=nil, },
  last       = { args={{1,2,3}, 3}, expected=3, },
})


function containsAll(table, values)
  if #table == #values then return equal(table, values) end

  local _found
  -- dump(values,"values")
  -- dump(table,"table")
  for _,v in pairs(values) do
    _found = false
    for _,t in pairs(table) do
      _found = equal(t, v)
      if _found then break end
    end
    if not _found then return false end
  end
  return true
end
--
test("containsAll", {
  empty     = { args={{}, {}},                                        
                expected=true, },
  emptyLHS  = { args={{}, {1}},                                       
                expected=false, },
  isPresent = { args={{1}, {1}},                                      
                expected=true, },
  isEqual   = { args={{1,2}, {1,2}},                                  
                expected=true, },
  isSubset  = { args={{1,2,3}, {1,2}},                                
                expected=true, },
  emptyRHS  = { args={{1,2,3}, {}},                                   
                expected=true, },
  eqTables  = { args={ {{key="k1",value="a"}}, {{key="k1",value="a"}} },  
                expected=true, },
  tables    = { args={ {{key="k1",value="a"}, {key="k2",value="b"}}, {{key="k1",value="a"}} },  
                expected=true, },
})


function clone(list)
  return {table.unpack(list)}
end
--
test("clone", {
  simple = { args={{1,2}}, expected={1,2}, },
  empty  = { args={{}}, expected={}, },
})


function shallow_copy(t)
  local new_t = {}
  for k, v in pairs(t) do
      new_t[k] = v
  end
  return new_t
end


function deep_copy(t)
  local new_t = {}
  for k, v in pairs(t) do
      if type(v) == "table" then
          new_t[k] = deep_copy(v)
      else
          new_t[k] = v
      end
  end
  return new_t
end


function find(e, list)
  for i = 1,#list do
    if e==list[i] then
      return i
    end
  end
  return nil
end


function match(table, fn)
  for i,val in ipairs(table) do
    if fn(val) then 
      return i,val
    end
  end
  return nil,nil
end


function addAll(table1, table2)
  run(table2, function(k,v) table.insert(table1, v) end)
  return table1
end


function toSet(list)
  local set = {}
  local result = {}
  for _, l in ipairs(list) do set[l] = true end
  for k, _ in pairs(set) do table.insert(result, k) end
  return result
end


function addAllUnique(table1, table2)
  run(table2, function(k,v) 
    if not contains(table1,v) then 
      table.insert(table1, v) 
    end
  end)
  return table1
end


function iany(table, fn)
  for i,val in ipairs(table) do
    if fn(val) then 
      return true
    end
  end
  return false
end


function any(table, fn)
  for key,val in pairs(table) do
    if fn(val) then 
      return true
    end
  end
  return false
end

function removeElement(t, e)
  table.remove(table, find(t, e))
end


function run(table, fn)
  for key,value in pairs(table) do
    fn(key,value)
  end
end

function inject(val, table, fn)
  local result = val
  for _,item in pairs(table) do
    result = fn(result, item)
  end
  return result
end
--
test("inject", {
  empty = {
    args={{}, {}, function(v,i) table.insert(v,i) return v end},
    expected={},
  },
  all = {
    args={{0}, {1,2,3}, function(v,i) table.insert(v,i) return v end},
    expected={0,1,2,3}
  },
  sum = {
    args={0, {1,2,3}, function(v,i) return v+i end},
    expected=6
  },
})


function select(list, fn)
  local result = {}
  for _,item in pairs(list) do
    if fn(item) then
      table.insert(result,item)
    end
  end
  return result
end
--
test("select", {
  all = {
    args={{1,2,3}, function(i) return true end},
    expected={1,2,3}
  },
  none = {
    args={{1,2,3}, function(i) return false end},
    expected={}
  },
  even = {
    args={{1,2,3}, function(i) return i % 2 == 0 end},
    expected={2}
  },
  empty = {
    args={{}, function(i) return true end},
    expected={}
  },
})




--
-- Group (set of lists) functions
--

function groupAdd(group, key, value)
  local values = group[key]
  if values == nil then
    values = {}
  end
  table.insert(values,value)
  group[key] = values
  return values
end
--
test("groupAdd", {
  addNewKeyNewValue = { 
      args={{}, "one", 1},
      expected={1} },
  addExistingKeyNewValue = { 
        args={{["one"]={1}}, "one", 2},
        expected={1,2} },
  addExistingKeyExistingValue = { 
    args={{["one"]={1,2}}, "one", 2},
    expected={1,2,2} },
})

function groupRemoveKey(group, key)
  local values = group[key]
  if values ~= nil then
    group[key] = nil
  end
end

function groupRemoveValue(group, key, value)
  local values = group[key]
  if values ~= nil then
    removeElement(values,value)
  end
  if isEmpty(values) then
    group[key] = nil
  else
    group[key] = values
  end
end

function groupContains(group, key, value)
  local values = group[key]
  if values == nil then
    return false
  else
    return contains(values,value)
  end
end

function groupContainsKey(group, key)
  return containsKey(group, key)
end

function groupKeysForValue(group, value)
  local keys = {}
  run(
    group, 
    function(key, dict) 
      if contains(dict, value) then
        table.insert(keys,key)
      end
    end)
    dump(keys)
  return keys
end


function groupContainsValue(group, value)
  return any(group, function(dict) return contains(dict, value) end)
end

function groupRemoveValue(group, value)
    run(group, function(key, dict) removeElement(dict, value) end)
end


function groupBy(table, fn)
  local groups = {}
  for _,v in pairs(table) do
    local key = fn(v)
    groupAdd(groups, key, v)
  end
  return groups
end
--
test("groupBy",{
  empty = { 
      args={{}, function(v) return v end},
      expected={} },
  singleton = { 
      args={ {{key="k1",value="a"}}, function(t) return t.key end },
      expected={["k1"] = { {key="k1",value="a"} }} },
  oneGroupWithStringKey = {
      args={{{key="1", value="a"}, {key="1", value="b"}, }, function(t) return t.key end},
      expected={["1"] = { {key="1",value="a"}, {key="1", value="b"} }} },
  twoGroupsWithStringKey = {
      args={ {{key="1", value="a"}, {key="1", value="b"}, {key="2", value="c"}}, function(t) return t.key end},
      expected={["1"] = { {key="1",value="a"}, {key="1", value="b"} },
                ["2"] = { {key="2", value="c"} }} },
  twoGroupsWithNumberKey = {
      args={ {{key=1, value="a"}, {key=1, value="b"}, {key=2, value="c"}}, function(t) return t.key end},
      expected={[1] = { {key=1,value="a"}, {key=1, value="b"} },
                [2] = { {key=2, value="c"} }} },
  twoGroupsWithNumberAsIndex = {
      args={ {{key=1, value="a"}, {key=1, value="b"}, {key=2, value="c"}}, function(t) return t.key end},
      expected={{ {key=1,value="a"}, {key=1, value="b"} },
                { {key=2, value="c"} }} },
  twoGroupsWithBoolKey = {
      args = { {1,2,3,4,5,6}, function(v) return v % 2 == 0 end},
      expected = {[false] = {1,3,5}, [true] = {2,4,6}} },
  twoGroupsWithNumberKeyWith0Index = {
    args = { {1,2,3,4,5,6}, function(v) return v % 2 end},
    expected = { [0] = {2,4,6}, [1] = {1,3,5}} },
})

--
-- Menu functions
--

function popupMenu(menuItems, nudgeLeft)
  usePopupMenu = true
  nudgeLeft = nudgeLeft or 0
  local menu = hs.menubar.new():setMenu(menuItems)
  local win = hs.application.frontmostApplication():focusedWindow()
  if win then
    local rect = win:title() == "" and hs.screen.mainScreen():frame() or win:frame()
    menu:popupMenu({x=rect.x+rect.w/2-nudgeLeft,y=rect.y+rect.h/4})
  else
    menu:popupMenu(hs.mouse.absolutePosition())
  end
end

function getMenuItem(_title, _fn, _checked, _disabled, _img, _menu, _hotkey)
  local def = { image=_img, title=_title, fn=_fn, checked=get(_checked,false), disabled=get(_disabled,false), shortcut=_hotkey }
  if _menu then
    def.menu = _menu
  end
  return def
end

function split(s, sep)
  local fields = {}
  
  local sep = sep or " "
  local pattern = string.format("([^%s]+)", sep)
  local _ = string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
  
  return fields
end
--
test("split", {
  normal        = { args={"a,b,c", ","},  expected={"a", "b", "c"} },
  noSep         = { args={"a,b,c", ";"},  expected={"a,b,c"} },
  defaultSep    = { args={"a b c"},       expected={"a", "b", "c"} },
  defaultNoSep  = { args={"a,b,c"},       expected={"a,b,c"} },
  emptyString   = { args={"", ";"},       expected={} },
})

keys = {}
hotkeyCollisions = {}
showingKeyHelp = false

local function normalizeMods(mods)
  if type(mods) == "table" then
    local copy = {}
    for i = 1, #mods do
      copy[i] = mods[i]
    end
    table.sort(copy)
    return copy
  elseif type(mods) == "string" then
    if mods == "" then
      return {}
    end
    return { mods }
  elseif mods ~= nil then
    return { tostring(mods) }
  else
    return {}
  end
end

local function makeHotkeyId(mods, key)
  local normalizedMods = normalizeMods(mods)
  local normalizedKey = type(key) == "string" and string.lower(key) or tostring(get(key, ""))
  if #normalizedMods == 0 then
    return normalizedKey
  end
  return table.concat(normalizedMods, "+") .. "+" .. normalizedKey
end

local function describeHotkey(mods, key)
  local normalizedMods = normalizeMods(mods)
  local keyLabel = type(key) == "string" and string.upper(key) or tostring(get(key, ""))
  if #normalizedMods == 0 then
    return keyLabel
  end
  return (table.concat(normalizedMods, "+")) .. "+" .. keyLabel
end

function bindKey(_mods, _key, _help, _fnDown, _fnUp, _fnRepeat)
  -- show('Binding key "'.._key..'"',10)
  local _hotkey = hs.hotkey.bind(_mods, _key, _fnDown, _fnUp, _fnRepeat)
  local hotkeyId = makeHotkeyId(_mods, _key)
  local collision = hs.fnutils.find(keys, function(k) return k.hotkeyId == hotkeyId end)
  if collision then
    local message = "Hotkey collision: " .. describeHotkey(_mods, _key) .. " (" .. get(collision.help, "existing binding") .. " vs " .. get(_help, "new binding") .. ")"
    table.insert(hotkeyCollisions, {
      id = hotkeyId,
      existing = get(collision.help, ""),
      incoming = get(_help, "")
    })
    print(message)
    if Debug then show(message, 4) end
  end
  table.insert(keys, {mods=_mods, key=_key, help=_help, hotkey=_hotkey, hotkeyId=hotkeyId})
  return _hotkey
end  

function unbindKey(_hotkey)
  if _hotkey then
    _hotkey:delete()
    keys = hs.fnutils.filter(keys, function(k) return k.hotkey ~= _hotkey end)
  end
end

function getHotkeyCollisions()
  return hotkeyCollisions
end


function showKeyHelp()
  if not showingKeyHelp then
    showingKeyHelp = true
    -- table.sort(keys, sortKeys)
    local s = "Keyboard Assignments:\n\n"
    for k = 1,#keys do
      local key = keys[k]
      local mods = key.mods
      local hyper = ""
      if (contains(mods,"cmd")
            and contains(mods,"ctrl")
            and contains(mods,"alt")) then
              hyper = contains(mods,"shift") and "􀆝􀆡" or "     􀆡"
      else
        hyper = (contains(mods,"cmd") and "􀆔" or "")
          .. (contains(mods,"ctrl") and "􀆍" or "")
          .. (contains(mods,"alt") and "􀆕" or "")
          .. (contains(mods,"shift") and "􀆔" or "")
      end

      s = s
        .. hyper
        .. "  "
        .. (key.key=="return" and "↵" or string.upper(key.key))
        .. "\t\t"
        .. get(key.help,"")
        .. "\n"
    end
    local _alert = show(s,5)
    hs.timer.waitWhile(keysDown, function() 
      hs.alert.closeSpecific(_alert,0.75) 
      showingKeyHelp = false
    end)
  end
end

function keysDown(key)
    local mods = hs.eventtap.checkKeyboardModifiers()
    -- dump(mods)
    if key == nil then
      return (mods["alt"] or mods["cmd"] or mods["ctrl"] or mods["shift"])
    else          
      return mods[key]
    end
end

function shiftDown()
    local mods = hs.eventtap.checkKeyboardModifiers()
    return mods["shift"] or false
end

----

function saveSettings(appKey,tableKey,table)
  for i,val in ipairs(table) do
    hs.settings.set(appKey.."."..tableKey.."."..i, val)
    log("Saving "..appKey.."."..tableKey.."."..i)
  end
end

function clearSettings(appKey,tableKey,table)
  for i,val in ipairs(table) do
    hs.settings.clear(appKey.."."..tableKey.."."..i)
  end
end

function restoreSettings(appKey,tableKey,table)
  for i,key in ipairs(hs.settings.getKeys()) do
    local keys = split(key,'.') -- {app,var,index}
    if keys[1] == appKey then
      local val = hs.settings.get(key)
      -- print("-- restoring settings key = "..keys[2].."["..keys[3].."]") -- = "..hs.inspect(val,{depth=1}))
      if keys[2] == tableKey then
        table[tonumber(keys[3])] = val
      else
        -- print("Unknown key: ",keys[2])
      end
    else
      -- print("--     ignoring settings key = "..key)
    end
  end
end

print("** Loaded utils **")
