local Scene = Scene or require "scene"

local scene_start = Scene('start')

local VERSION_STRING
----------------------------------------
function scene_start:load()
  VERSION_STRING = string.format("v%.02f", VERSION)
end

----------------------------------------
function scene_start:enter(prev_scene,...)
  Scene.enter(self, prev_scene, ...)
  AUDIO.motivational:play()
end

function scene_start:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
  AUDIO.motivational:stop()
end

function scene_start:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
  AUDIO.motivational:resume()
end

function scene_start:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
  AUDIO.motivational:pause()
end

----------------------------------------
function scene_start:update(dt)
end

----------------------------------------
function scene_start:draw(isactive)
  -- TODO: splash-screen etc....
  love.graphics.setColor(1,1,1)
  love.graphics.print("PLEASANT SPACE CRUISE", FONTS.torek_42, 100, 100)
  love.graphics.print(VERSION_STRING, FONTS.torek_16, 100, 200)
  love.graphics.print("Press S to start", FONTS.torek_16, 100, 300)
  love.graphics.print("Press Q to quit", FONTS.torek_16, 100, 500)
end

function scene_start:keypressed(key,scancode,isrepeat)
  if key=='q' or key=='escape' then
    love.event.quit()
  elseif key=='s' then
    scene_play:reset('playing')
    SCENE_MANAGER:set('play')
  -- TODO: options...
  end
end

function scene_start:mousepressed(x,y,button)
end

return scene_start
