local class = class or require "middleclass"

--------------------------------------------------------------------------------

local Scene = class("Scene")

function Scene:initialize(name) self.name=name; self.paused=false; self.active=false end
function Scene:__tostring() return string.format("Scene:%s", self.name) end
function Scene:load() end
function Scene:update(dt) end
function Scene:draw(isactive) end
function Scene:enter(prev_scene,...) self.active=true end
function Scene:exit(next_scene,...) self.active=false end
function Scene:pause(next_scene,...) self.paused=true end
function Scene:resume(prev_scene,...) self.paused=false end
function Scene:quit() end

--[[
function Scene:keypressed(key,scancode,isrepeat)
function Scene:keyreleased(key,scancode)
function Scene:mousemoved(x,y,dx,dy,istouch)
function Scene:wheelmoved(x,y,button)
function Scene:mousepressed(x,y,button,istouch,presses)
function Scene:mousereleased(x,y,button,istouch,presses)
--]]
for _,callback in ipairs({
    'keypressed','keyreleased','wheelmoved',
    'mousepressed','mousereleased','mousemoved',
  }) do
  Scene[callback] =
    function(self,...)
      if self.ui and self.ui[callback] then
        self.ui[callback](self.ui,...)
      end
    end
end

--------------------------------------------------------------------------------

return Scene

