----
-- Windows like menu bindings

print(hs.inspect(hs.keycodes.map))

k = hs.hotkey.modal.new('cmd-shift', 'k')

function k:entered() hs.alert'Entered mode' end
function k:exited()  hs.alert'Exited mode'  end

k:bind('', 'escape', function() k:exit() end)
k:bind('', 'K', 'Pressed k',function() print'let the record show that k was pressed' end)

-- function control_handler(evt)
--   if hs.keycodes.map[evt:getKeyCode()] == "capslock" then
--     show("caps")
--   end
-- end


-- function sendMenuKeys()
--   -- focus on menubar
--   -- get first key
--   -- send an enter 
--   -- get other keys
-- end


-- hs.hotkey.bind({"ctrl"}, "q", function() 
--     sendMenuKeys()
--   end)


  -- hs.hotkey.bind({}, "padenter", function() 
--   show("padenter")
--   -- hs.eventtap.keyStrokes("-") 
-- end)

--

-- https://github.com/jasonrudolph/keyboard/commit/01a7a5bd8a1e521756d1ec34769119ead5eee0b3


-- function control_handler(evt)
--   if hs.keycodes.map[evt:getKeyCode()] == "capslock" then
--     show("caps")
--   end
-- end

-- control_tap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, control_handler)
-- control_tap:start()


-- -- A global variable for the Hyper Mode
-- k = hs.hotkey.modal.new({}, "F17")

-- -- Trigger existing hyper key shortcuts

-- k:bind({}, 'm', nil, function() hs.eventtap.keyStroke({"cmd","alt","shift","ctrl"}, 'm') end)

-- -- OR build your own

-- launch = function(appname)
--   hs.application.launchOrFocus(appname)
--   k.triggered = true
-- end

-- -- Single keybinding for app launch
-- singleapps = {
--   {'q', 'MailMate'},
--   {'w', 'OmniFocus'},
--   {'e', 'Sublime Text'},
--   {'r', 'Google Chrome'}
-- }

-- for i, app in ipairs(singleapps) do
--   k:bind({}, app[1], function() launch(app[2]); k:exit(); end)
-- end

-- -- Sequential keybindings, e.g. Hyper-a,f for Finder
-- a = hs.hotkey.modal.new({}, "F16")
-- apps = {
--   {'d', 'Twitter'},
--   {'f', 'Finder'},
--   {'s', 'Skype'},
-- }
-- for i, app in ipairs(apps) do
--   a:bind({}, app[1], function() launch(app[2]); a:exit(); end)
-- end

-- pressedA = function() a:enter() end
-- releasedA = function() end
-- k:bind({}, 'a', nil, pressedA, releasedA)

-- -- Shortcut to reload config

-- ofun = function()
--   hs.reload()
--   hs.alert.show("Config loaded")
--   k.triggered = true
-- end
-- k:bind({}, 'o', nil, ofun)

-- -- Enter Hyper Mode when F18 (Hyper/Capslock) is pressed
-- pressedF18 = function()
--   k.triggered = false
--   k:enter()
-- end

-- -- Leave Hyper Mode when F18 (Hyper/Capslock) is pressed,
-- --   send ESCAPE if no other keys are pressed.
-- releasedF18 = function()
--   k:exit()
--   if not k.triggered then
--     hs.eventtap.keyStroke({}, 'ESCAPE')
--   end
-- end

-- -- Bind the Hyper key
-- f18 = hs.hotkey.bind({}, 'F18', pressedF18, releasedF18)

