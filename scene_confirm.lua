local Scene = Scene or require "scene"

local scene_confirm = Scene('confirm')

function scene_confirm:draw(isactive)
  love.graphics.setColor(0,0,0)
  love.graphics.print("Do you want to quit to main menu?", FONTS.torek_42, 100-4, 100-4)
  love.graphics.setColor(1,1,1)
  love.graphics.print("Do you want to quit to main menu?", FONTS.torek_42, 100, 100)
  love.graphics.setColor(0,0,0)
  love.graphics.print("Press Y to confirm", FONTS.torek_16, 100-4, 300-4)
  love.graphics.setColor(1,1,1)
  love.graphics.print("Press Y to confirm", FONTS.torek_16, 100, 300)
  love.graphics.setColor(0,0,0)
  love.graphics.print("Anything else to continue", FONTS.torek_16, 100-4, 500-4)
  love.graphics.setColor(1,1,1)
  love.graphics.print("Anything else to continue", FONTS.torek_16, 100, 500)
end

function scene_confirm:keypressed(key,scancode,isrepeat)
  if key=='y' then
    SCENE_MANAGER:pop()
    SCENE_MANAGER:set('start')
  else
    SCENE_MANAGER:pop()
  end
end

return scene_confirm

