local Scene = Scene or require "scene"

local scene_credits = Scene('credits')

local MUSIC = nil

function scene_credits:load()
  MUSIC = AUDIO.crime
end

----------------------------------------
function scene_credits:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
  if MUSIC then MUSIC:stop() end
end

----------------------------------------
function scene_credits:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
  if MUSIC then MUSIC:play() end
end

----------------------------------------
function scene_credits:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
  if MUSIC then MUSIC:pause() end
end

----------------------------------------
function scene_credits:enter(prev_scene,...)
  Scene.enter(self, prev_scene, ...)
  if MUSIC then MUSIC:play() end
end

----------------------------------------
function scene_credits:draw(isactive)
  local c = {112/2048,151/2048,117/2048,1}
  love.graphics.clear(unpack(c))

  love.graphics.setColor(1,1,1)
  love.graphics.print("CREDITS", FONTS.torek_42, 24,24)

  local y

  y = 120
  love.graphics.print("Programming", FONTS.torek_16, 48,y); y=y+24
  love.graphics.print("Game development: Apollo", 96,y); y=y+16
  love.graphics.print("LÖVE2D game framework: https://love2d.org/", 96,y); y=y+16
  love.graphics.print("The 'middleclass' Lua library by kikito: https://github.com/kikito/middleclass", 96,y); y=y+16

  y = 240
  love.graphics.print("Art", FONTS.torek_16, 48,y); y=y+24
  love.graphics.print("Art assets: Apollo", 96,y); y=y+16

  y = 360
  love.graphics.print("Music", FONTS.torek_16, 48,y); y=y+24

  y = 480
  love.graphics.print("Fonts", FONTS.torek_16, 48,y); y=y+24
end

----------------------------------------
function scene_credits:keypressed(key,scancode,isrepeat)
  SCENE_MANAGER:pop()
end

----------------------------------------
return scene_credits


