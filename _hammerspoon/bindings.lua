----
-- Keyboard bindings

hs.hotkey.bind({"ctrl"}, "x", function() 
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({"Edit","Cut"})
  end)
  hs.hotkey.bind({"ctrl"}, "c", function() 
    local app = hs.application.frontmostApplication()
    app:selectMenuItem({"Edit","Copy"})
  end)
  hs.hotkey.bind({"ctrl"}, "v", function() 
    hs.eventtap.keyStrokes(hs.pasteboard.getContents()) 
  end)