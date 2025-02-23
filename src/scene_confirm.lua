local Scene = Scene or require "scene"

local scene_confirm = Scene('confirm')

local MUSIC = nil

----------------------------------------
function scene_confirm:load()
  MUSIC = AUDIO.celestial
end

----------------------------------------
function scene_confirm:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
  if MUSIC then MUSIC:stop() end
end

----------------------------------------
function scene_confirm:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

----------------------------------------
function scene_confirm:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
  if MUSIC then MUSIC:pause() end
end

----------------------------------------
function scene_confirm:enter(prev_scene, the_reason, the_score, the_progress, the_difficulty, ...)
  Scene.enter(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

----------------------------------------
function scene_confirm:update(dt)
  if MUSIC then
    if MUSIC_ENABLED then
      if not MUSIC:isPlaying() then
        MUSIC:play()
      end
    else
      if MUSIC:isPlaying() then
        MUSIC:stop()
      end
    end
  end
end

----------------------------------------
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

----------------------------------------
function scene_confirm:keypressed(key,scancode,isrepeat)
  if key=='y' then
    SCENE_MANAGER:pop()
    SCENE_MANAGER:set('start')
  else
    SCENE_MANAGER:pop()
  end
end

----------------------------------------
return scene_confirm

