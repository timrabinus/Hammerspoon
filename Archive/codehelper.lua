----
-- Lua code helpers

require "utils"

function typeKey(key, mods)
  mods = mods or {}
  hs.eventtap.event.newKeyEvent(mods, key, true):post()
end

function typeString(s)
  local e = hs.eventtap.event.newEvent()
  e:setType(hs.eventtap.event.types.keyDown)
  e:setUnicodeString(s)
  e:post()
  e = hs.eventtap.event.newEvent()
  e:setType(hs.eventtap.event.types.keyUp)
  e:setUnicodeString(s)
  e:post()
end


function commentToPrint()
  typeKey("left", {"command"})

  typeString("print(")
  typeString("\"")

  typeKey("right", {"command"})
  typeString("\")")
end

function printToComment()
  typeKey("left", {"command"})
  typeKey("right", {"alt", "shift"})
  typeKey("delete")
  typeKey("forwarddelete")
  typeKey("forwarddelete")

  typeKey("right", {"command"})
  typeKey("delete")
  typeKey("delete")
end


-- codehelper
bindKey(hyper, "'", "Comment to print", commentToPrint)
bindKey(shyper, "'", "Print to comment", printToComment)


print("** Loaded codehelper **")

-- tests 
