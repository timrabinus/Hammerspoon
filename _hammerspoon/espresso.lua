------
-- Display Sleep

espressoOn = "􀛭" -- lightbulb
espressoOff = "􀛮" -- lightbulb.fill
espressoState = espressoOn

espresso = hs.menubar.new()

function setespressoDisplay(state)
  if state then
    espressoState = espressoOn
  else
    espressoState = espressoOff
  end
  espresso:setTitle(espressoState)
end

function espressoClicked()
  local events = hs.eventtap.checkKeyboardModifiers()
  if events["shift"]==true then 
    hs.caffeinate.systemSleep()
  elseif espressoState == espressoOn then -- sunrise
    show("Display Sleep On")
  else
    show("Display Sleep Off")
  end
  setespressoDisplay(hs.caffeinate.toggle("displayIdle"))
end

if espresso then
    espresso:setClickCallback(espressoClicked)
    setespressoDisplay(hs.caffeinate.get("displayIdle"))
end