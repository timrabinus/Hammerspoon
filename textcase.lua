-- Textconvert
-- Capitalized case adapted from http://stackoverflow.com/questions/20284515/capitalize-first-letter-of-every-word-in-lua
-- Slug code adapted from https://dracoblue.net/dev/convert-titlestring-to-url-slug-in-php-or-lua/

function url_decode(str)
  str = string.gsub(str, "+", " ")
  str = string.gsub(str, "%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return str
end

function url_encode(str)
  str = string.gsub(str, "\n", "\r\n")
  str = string.gsub(str, "([^%w %-%_%.%~])", function(c) return string.format("%%%02X", string.byte(c)) end)
  str = string.gsub(str, " ", "+")
  return str
end

function getCaseChoices(str)
  local s = asTitleCase(str)
  local t = s:gsub("^[^%a]+","")

  local choices = {
    {
      ["text"] = s,
      ["subText"] = "Title case"
    },
    {
      ["text"] = s:lower():gsub("^%l",s.upper),
      ["subText"] = "Sentence case"
    }, 
    {
      ["text"] = s:upper(),
      ["subText"] = "Caps"
    },
    {
      ["text"] = t:upper():gsub("[ ]+","_"),
      ["subText"] = "Constant"
    },
    {
      ["text"] = (" "..t):gsub("%W%l", t.upper):sub(2):gsub(" ", ""),
      ["subText"] = "Pascal"
    },
    {
      ["text"] = (" "..t):gsub("%W%l", t.upper):sub(2):gsub(" ", ""):gsub("^%u",s.lower),
      ["subText"] = "Camel"
    },
    {
      ["text"] = t:lower():gsub("[ ]+","_"),
      ["subText"] = "Snake"
    },
    {
      ["text"] = (" "..t):gsub("%W%l", t.upper):sub(2):gsub(" ", ""):gsub("%l",""),
      ["subText"] = "Abbreviation"
    },
    {
      ["text"] = (" "..t):gsub("%W%l", t.upper):sub(2):gsub(" ", ""):gsub("%l",""):lower(),
      ["subText"] = "Variable"
    },
    {
      ["text"] = s:lower(),
      ["subText"] = "Lower case"
    },
    {
      ["text"] = s:lower():gsub("[ ]+","-"),
      ["subText"] = "Hyphenated"
    },
    {
      ["text"] = (url_encode(str)),
      ["subText"] = "URL Encoded"
    },
    {
      ["text"] = (""..url_decode(str)),
      ["subText"] = "URL Decoded"
    },
  }
  return choices
end


function pasteSelectedCase(app, s)
  local chooser = hs.chooser.new(function(chosen)
      app:activate()
      if chosen and chosen.text then
        hs.pasteboard.setContents(chosen.text)
        hs.timer.usleep(20000)
        hs.eventtap.keyStroke({"cmd"}, "v")
      end
  end)
  chooser:query(s)
  chooser:queryChangedCallback(function(s) chooser:choices(getCaseChoices(s)) end)
  chooser:searchSubText(false)
  chooser:show()
end


function currentSelection()
  local elem=hs.uielement.focusedElement()
  local sel=nil
  if elem then
      sel=elem:selectedText()
  end
  if (not sel) or (sel == "") then
    print("Can't get selected text from "..hs.application.frontmostApplication():title())
    local oldClipboard =hs.pasteboard.getContents()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(20000)
    sel=hs.pasteboard.getContents()
    if sel == oldClipboard then
      return nil
    end
  end
  return (sel or "")
 end

function pasteWithCase()
  print("pasteWithCase")
  pasteSelectedCase(hs.application.frontmostApplication(), hs.pasteboard.getContents())
end

function replaceWithCase()
  print("replaceWithCase")
  local sel = currentSelection()
  if sel then
    pasteSelectedCase(hs.application.frontmostApplication(), sel)
  end
end


function printClipboard()
  dump(hs.pasteboard.getContents(), "Clipboard")
end


function copySelectedText()
  print("Copying...")
  hs.application.frontmostApplication():activate()
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.usleep(200000)
  sel=hs.pasteboard.getContents()
  printClipboard()
end


hs.hotkey.bind(hyper, "c", pasteWithCase)
hs.hotkey.bind(hyper, "x", replaceWithCase)
-- hs.hotkey.bind("", "f14", replaceWithCase)

print("** Loaded text case **")


-- this_is_a_string
-- thisIsAString
-- this-is-a-string
-- THIS IS A STRING
-- This is a string
-- This 1s a str1ng
-- This, is 'a' string.
-- It’s a “string”
-- "It's a string"
-- hello%20world%21
-- hello world!
-- for identifiers numbers at end ok 123
-- 123 for identifiers numbers at start not ok
-- for identifiers numbers in middle 123 ok