local class = class or require "middleclass"

--------------------------------------------------------------------------------
local EventManager = class("EventManager")

function EventManager:initialize()
  self.handlers = {}
end

function EventManager:emit(event,...)
  if not self.handlers[event] then return end
  for _,h in ipairs(self.handlers[event]) do
    if #h==3 then
      h[2](h[3], event, ...)
    else
      h[2](event, ...)
    end
  end
end

-- arg is optional first argument to handler
function EventManager:on(event,id,handler,arg)
  if not self.handlers[event] then self.handlers[event] = {} end
  local l = self.handlers[event]
  if arg == nil then
    l[#l + 1] = {id,handler}
  else
    l[#l + 1] = {id,handler,arg}
  end
end

-- removes ALL watchers with matching id
function EventManager:remove(event,id)
  local a = self.handlers[event]
  for i = #a, 1, -1 do
    if a[i][1]==id then
      table.remove(a, i)
    end
  end
end

--------------------------------------------------------------------------------

return EventManager

