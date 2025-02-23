local Scene = Scene or require "scene"

local scene_credits = Scene('credits')

local MUSIC = nil

function scene_credits:load()
  MUSIC = AUDIO.cyberpunk
end

----------------------------------------
function scene_credits:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
  if MUSIC then MUSIC:stop() end
end

----------------------------------------
function scene_credits:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

----------------------------------------
function scene_credits:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
  if MUSIC then MUSIC:pause() end
end

----------------------------------------
function scene_credits:enter(prev_scene,...)
  Scene.enter(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

----------------------------------------
function scene_credits:update(dt)
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
function scene_credits:draw(isactive)
  local c = {112/2048,151/2048,117/2048,1}
  love.graphics.clear(unpack(c))

  love.graphics.setColor(1,1,1)
  love.graphics.print("CREDITS", FONTS.torek_42, 24,24)

  local y

  y = 120
  love.graphics.print("Programming", FONTS.torek_16, 48,y); y=y+24
  love.graphics.print("Game development: Apollo (Dreaming Rlyeh Studio)", 96,y); y=y+16
  y=y+4
  love.graphics.print("LÖVE2D game framework -- https://love2d.org/", 96,y); y=y+16
  love.graphics.print("The 'middleclass' Lua library by kikito -- https://github.com/kikito/middleclass", 96,y); y=y+16

  y = 240
  love.graphics.print("Art", FONTS.torek_16, 48,y); y=y+24
  love.graphics.print("Art assets: Apollo (Dreaming Rlyeh Studio)", 96,y); y=y+16

  y = 360
  love.graphics.print("Fonts", FONTS.torek_16, 48,y); y=y+24
  love.graphics.print("Malefissent: Theyann PentaGram / Full Moon Design House", 96,y); y=y+16
  love.graphics.print("Toreks Regular: AsyaLogo", 96,y); y=y+16

  y = 480
  love.graphics.print("Music", FONTS.torek_16, 48,y); y=y+24
  love.graphics.print("Some effects made by Apollo (Dreaming Rlyeh Studio) using jsfxr -- https://sfxr.me/", 96,y); y=y+16
  y=y+4
  love.graphics.print("Celestial Voices by Nancy_Sinclair -- https://freesound.org/s/759643/ -- License: Creative Commons 0", 96,y); y=y+16
  love.graphics.print("Future of Hope - bpm 85 loop by DenKyschuk -- https://freesound.org/s/726343/ -- License: Attribution NonCommercial 4.0", 96,y); y=y+16
  love.graphics.print("infobleep.wav by Divinux -- https://freesound.org/s/198414/ -- License: Creative Commons 0", 96,y); y=y+16
  love.graphics.print("Motivational Day by Universfield -- https://freesound.org/s/701089/ -- License: Attribution 4.0", 96,y); y=y+16
  love.graphics.print("music elevator ext by Jay_You -- https://freesound.org/s/467240/ -- License: Attribution 4.0", 96,y); y=y+16
  love.graphics.print("Tense Crime Atmosphere for Films and Media by Nancy_Sinclair -- https://freesound.org/s/750627/ -- License: Creative Commons 0", 96,y); y=y+16
  love.graphics.print("Wooden Hover by BenjaminNelan -- https://freesound.org/s/321082/ -- License: Creative Commons 0", 96,y); y=y+16
  love.graphics.print("lasershot.wav by senitiel -- https://freesound.org/s/131432/ -- License: Attribution NonCommercial 3.0", 96,y); y=y+16
  y=y+4
  love.graphics.print("https://pixabay.com/sound-effects/applause-sound-effect-240470/", 96,y); y=y+16
  love.graphics.print("https://pixabay.com/sound-effects/beeping-robot-or-machine-102595/", 96,y); y=y+16
  love.graphics.print("https://pixabay.com/sound-effects/breaking-glass-83809/", 96,y); y=y+16
  love.graphics.print("https://pixabay.com/sound-effects/cyberpunk-beat-64649/", 96,y); y=y+16
  love.graphics.print("https://pixabay.com/sound-effects/cartoon-trombone-sound-effect-241387/", 96,y); y=y+16
  love.graphics.print("https://pixabay.com/sound-effects/large-underwater-explosion-190270/", 96,y); y=y+16
  love.graphics.print("https://pixabay.com/sound-effects/sci-fi-weapon-shoot-firing-plasma-pp-05-233829/", 96,y); y=y+16
end

----------------------------------------
function scene_credits:keypressed(key,scancode,isrepeat)
  SCENE_MANAGER:pop()
end

----------------------------------------
return scene_credits


