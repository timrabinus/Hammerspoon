------
-- Utilities

function get(v,default)
  return v and v or default
end

function show(msg,dur)
  hs.alert.show(msg,{
      radius=15,
      fillColor={white=0.85},
      strokeColor={white=0.85},
      textColor={white=0},
      textSize=20,
      padding=18,
      fadeOutDuration=.75
  },
  hs.screen.mainScreen(),
  get(dur,2))
end

function get(v,default)
  return v and v or default
end

function find(e,list)
  for i = 1,#list do
    if e==list[i] then
      return i
    end
  end
  return nil
end


function match(table,fn)
  for i,val in ipairs(table) do
    if fn(val) then 
      return i,val
    end
  end
  return nil,nil
end


function getMenuItem(_title, _fn, _checked, _disabled, _img)
  return { image=_img, title=_title, fn=_fn, checked=get(_checked,false), disabled=get(_disabled,false) }
end

-- split("a,b,c", ",") => {"a", "b", "c"}
function split(s, sep)
  local fields = {}
  
  local sep = sep or " "
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
  
  return fields
end
