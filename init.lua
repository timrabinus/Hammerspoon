
package.path = package.path .. ";" ..  hs.configdir .. "/MSpoons/?.spoon/init.lua"

Debug = false
Verbose = true
TotalTests = 0
TotalPassed = 0

hs.console:clearConsole()

require "test"

require "utils"
bindKey(hyper, "r", "Reload Hammerspoon", function() hs.reload() end)
-- require "reload"


-- if Debug then

  require "finderTabs"
  require "appLauncher"
  require "espresso"
  require "menukeys"
  require "stack"

-- else

  -- Released:
  -- require "workspaces"
  -- require "winmover"
  -- require "winhelper"
  -- require "codehelper"
  -- require "userProfiler"
  -- require "menuCommands"
  -- require "textcase"
  -- require "midiHelper"
  -- require "test"
  
-- end

-- 
-- In the Lab
--

-- require "craftHelper"
-- require "menuCommands"



-- should be last
require "bindings"

if Debug then
  print("Tests: "..TotalTests..", Passed: "..TotalPassed)
end

--
-- Disabled
--

-- require "windebug"
-- require "marco"
-- require "leap"  
-- require "settings"


