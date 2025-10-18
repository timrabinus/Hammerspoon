-- 
-- Simple unit testing framework
--


function tostr(v)
    if type(v) == "table" then
        dump(v)
        return "{"..table.concat(v, ", ").."}"
    elseif type(v) == "function" then
        return "function"
    elseif type(v) == "nil" then
        return "nil"
    elseif type(v) == "boolean" then
        return v and "true" or "false"
    end
    return ""..v
end

-- print(tostr(1))
-- print(tostr("a"))
-- print(tostr({1,2,3}))
-- print(tostr(nil))
-- print(tostr(tostr))


          
function test(fnName, tests)
    if Debug then
        local testsRun,testsFailed,log = 0,0,""
        local fn = _ENV[fnName]
        if fn then
            for name,test in pairs(tests) do
                if Verbose then print("Testing "..fnName.."() test case: "..name) end
                TotalTests = TotalTests + 1
                local result = fn(table.unpack(test.args))
                testsRun = testsRun + 1
                if not equal(result, test.expected) then
                    log = log..("\n                         *** Test "..name.." failed: expected "..tostr(test.expected).." got "..tostr(result))
                    testsFailed = testsFailed+1
                else
                    TotalPassed = TotalPassed + 1
                end
            end
            local result = testsFailed > 0 and "FAIL" or "OK"
            print(string.sub(fnName.."()                  ",1,20)..result..": "..testsRun.." tests run: "..testsRun-testsFailed.." passed, "..testsFailed.." failed"..log)
        else
            print("Could not find function "..fnName)
        end
    end
end

-----

function equalValues(a, b)
    if #a ~= #b then return false end

    for k,v in pairs(a) do
        if not equal(a[k], b[k]) then return false end
    end
    return true
end

function equalKeys(a, b)
    if #a ~= #b then return false end
  
    local t1,t2 = {},{}
     -- copy all values into keys for constant time lookups
    for k,v in pairs(a) do
        t1[k] = (t1[k] or 0) + 1 -- make sure we track how many times we see each value.
    end
    for k,v in pairs(b) do
        t2[k] = (t2[k] or 0) + 1
    end
    -- go over every key
    for k,v in pairs(t1) do 
        if not equal(v, t2[k]) then return false end -- if the number of times that element was seen don't match...
    end
    return true
end

function equalTable(a,b)
    return equalKeys(a,b) and equalValues(a,b)
end


function equal(v1,v2)
    if type(v1) ~= type(v2) then
        return false
    elseif type(v1) == "table" then
        return equalTable(v1,v2)
    else
        return v1 == v2
    end
end
--
test("equalKeys", {
    arrays        = { args={{1,2,3}, {1,2,3}}, expected=true },
    nonContig     = { args={{1,2,6}, {1,2,6}}, expected=true },
    order         = { args={{1,2,3}, {3,2,1}}, expected=true },
    diffArrays    = { args={{1,2,3}, {1,2,3,4}}, expected=false },
    diffBags      = { args={{1,2,3}, {1,2,3,3,2,2,2}}, expected=false },
    testNil       = { args={{}, {}}, expected=true },
    tables        = { args={{a=1,b=2,c=3}, {a=1,b=2,c=3}}, expected=true },
    diffTables    = { args={{a=1,b=2,c=3}, {a=1,b=2}}, expected=false },
    diffTableKeys = { args={{a=1,b=2,c=3}, {a=1,b=2,d=3}}, expected=false },
})
test("equalValues", {
    arrays          = { args={{1,2,3}, {1,2,3}}, expected=true },
    order           = { args={{1,2,3}, {3,2,1}}, expected=false },             -- note diff from equalKeys
    diffArrays      = { args={{1,2,3}, {1,2,3,4}}, expected=false },
    diffBags        = { args={{1,2,3}, {1,2,3,3,2,2,2}}, expected=false },
    testNil         = { args={{}, {}}, expected=true },
    tables          = { args={{a=1,b=2,c=3}, {a=1,b=2,c=3}}, expected=true },
    diffTableValues = { args={{a=1,b=2,c=3}, {a=1,b=2,c=4}}, expected=false },
    diffTables      = { args={{a=1,b=2,c=3}, {a=1,b=2}}, expected=false },
    diffTableKeys   = { args={{a=1,b=2,c=3}, {a=1,b=2,d=3}}, expected=false },
})
test("equal", {
    testNil     = { args={nil, nil}, expected=true, },
    numbers     = { args={1, 1}, expected=true, },
    diffNumbers = { args={1, 2}, expected=false, },
    bools       = { args={true, true}, expected=true, },
    diffBools   = { args={true, false}, expected=false, },
    fns         = { args={test, test}, expected=true, },
    diffFns     = { args={test, equal}, expected=false, },
    chars       = { args={"a", "a"}, expected=true, },
    diffChars   = { args={"a", "b"}, expected=false, },
    strings     = { args={"aa", "aa"}, expected=true, },
    diffStrings = { args={"aa", "ab"}, expected=false, },
    tables      = { args={{k=1,v=2}, {k=1,v=2}}, expected=true },
    diffTables  = { args={{k=1,v=2}, {k=1,v=3}}, expected=false },
})
test("equalTable", {
    empty        = { 
        args={{}, {}}, 
        expected=true, },
    notEmpty     = { 
        args={{}, {1}}, 
        expected=false, },
    subset       = { 
        args={{1,2}, {1}}, 
        expected=false, },
    order       = { 
        args={{1,2}, {2,1}}, 
        expected=false, },
    strings      = { 
        args={{"1","2"}, {"1","2"}}, 
        expected=true, },
    stringSubset = { 
        args={{"1","2","2"}, {"1","2"}}, 
        expected=false, },
    tables       = { 
        args={ {{"1","2"}, {"1","2"}}, {{"1","2"}, {"1","2"}} }, 
        expected=true, },
    tables2      = { 
        args={ {{"1","2"}, {"3","4"}}, {{"1","2"}, {"3","4"}} }, 
        expected=true, },
    tablesOrder  = { 
        args={ {{"1","2"}, {"3","4"}}, {{"3","4"}, {"1","2"}} }, 
        expected=false, },
    tablesWithKeysSameValues = { 
        args={ {{k="1",v="2"}, {k="1",v="2"}}, {{k="1",v="2"}, {k="1",v="2"}} }, 
        expected=true, },
    tablesWithKeysDiffValues = { 
        args={ {{k="1",v="2"}, {k="1",v="2"}}, {{k="1",v="2"}, {k="1",v="x"}} }, 
        expected=false, },
    tablesWithEmptyRHS = { 
        args={ {{k="1",v="2"}, {k="1",v="3"}}, {} }, 
        expected=false, },
    tablesWithDiffRHS = { 
        args={ {{k="1",v="2"}, {k="1",v="3"}}, {{k="1",v="2"}, {k="1",v="x"}} }, 
        expected=false, },
})  

  
function first(list)
    if list and #list > 1 then
        return list[1]
    else
        return nil
    end
end
--
test("first", {
    simple = { args={{1,2,3}}, expected=1 },
    empty  = { args={{}}, expected=nil }
})
