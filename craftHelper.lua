function changeViewIfInCraft(key, letter)
  local mouseX, mouseY = 120,51
  local currentApp = hs.application.frontmostApplication()
  local frame = hs.window.frontmostWindow():frame()
  if currentApp:title() == "Craft" then
    local mouseLoc = hs.mouse.absolutePosition()
    hs.eventtap.leftClick({x=mouseX+frame.x,y=mouseY+frame.y-20})
    hs.mouse.absolutePosition(mouseLoc)
    hs.eventtap.event.newKeyEvent("", letter, true):post(currentApp)
    hs.eventtap.event.newKeyEvent("", letter, false):post(currentApp)
    hs.eventtap.event.newKeyEvent("", "return", true):post(currentApp)
    hs.eventtap.event.newKeyEvent("", "return", false):post(currentApp)
  else
    hs.eventtap.event.newKeyEvent("cmd", key, true):post(currentApp)
    hs.eventtap.event.newKeyEvent("cmd", key, false):post(currentApp)
  end
end
-- 120,51 - 0,25
-- bindKey("cmd", "2", "", function() changeViewIfInCraft("1", "C") end)
-- bindKey("cmd", "1", "", function() changeViewIfInCraft("2", "O") end)

print("** Loaded craftHelper **")

---


