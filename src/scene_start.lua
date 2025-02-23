local Scene = Scene or require "scene"

local scene_start = Scene('start')

local CTHULHU_GREEN = {112/255,151/255,117/255,1}
local VERSION_STRING
local difficulty_level = 2
local MUSIC = nil

----------------------------------------
function scene_start:load()
  VERSION_STRING = string.format("v%.02f", VERSION)
  MUSIC = AUDIO.motivational
end

----------------------------------------
function scene_start:enter(prev_scene,...)
  Scene.enter(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

function scene_start:exit(next_scene,...)
  Scene.exit(self, next_scene, ...)
  if MUSIC then MUSIC:stop() end
end

function scene_start:resume(prev_scene,...)
  Scene.resume(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

function scene_start:pause(next_scene,...)
  Scene.pause(self, next_scene, ...)
  if MUSIC then MUSIC:pause() end
end

----------------------------------------
function scene_start:update(dt)
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
function scene_start:draw(isactive)
  if not isactive then return end

  -- TODO: splash-screen etc....
  love.graphics.setColor(1,1,1)
  love.graphics.print("A PLEASANT SPACE CRUISE", FONTS.torek_42, 100, 100)
  love.graphics.print("Aboard The USSS Ohio", FONTS.torek_42, 150, 150)
  love.graphics.print(VERSION_STRING, FONTS.torek_16, 100, 250)
  love.graphics.print("Press S to start", FONTS.torek_16, 100, 350)
  love.graphics.print("Press C for credits", FONTS.torek_16, 100, 550)
  love.graphics.print("Press M to enable/disable music (or F1 at anytime)", FONTS.torek_16, 100, 575)
  love.graphics.print("Press Q to quit", FONTS.torek_16, 100, 650)

  for i,x in ipairs({"EASY", "NORMAL", "IMPOSSIBLE"}) do
    if i==difficulty_level then
      love.graphics.setColor(1,1,0)
      love.graphics.print("Selected  "..x.."  difficulty", FONTS.torek_16, 100, 398+24*i)
    else
      love.graphics.setColor(0.9,0.9,0.9)
      love.graphics.print("Press  "..tostring(i).."  to select  "..x.."  difficulty", FONTS.torek_16, 100, 398+24*i)
    end
  end

  love.graphics.setColor(1,1,0.5)
  for i,t in ipairs({
      "Guide the USSS Ohio to its destination",
      "The newest premiere space-ship from the Acme Corporation,",
      "incorporating all the latest tech to ensure that nothing can go wrong!",
      "",
      "  Left-mouse click = select cell + device",
      "  Right-mouse click = select crewmember",
      "",
      "  [Spacebar] to pause",
      "",
      "  Instruct them to repair or operate as appropriate.",
      "  Click on-screen buttons or press key to",
      "    [R]epair / [F]ix",
      "    [O]perate / [W]ork",
      "",
      "  Note that *propulsion-power* is what you need to progress",
    }) do
    love.graphics.print(t, 550, 200+15*i)
  end

  love.graphics.setColor(unpack(CTHULHU_GREEN))
  love.graphics.print("Dreaming Rlyeh Studio", FONTS.malefissent_20, 24, 912-48)
  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print(string.format("Made with LÖVE %i.%i.%i (%s)", love.getVersion()), 770, 912-24)
end

function scene_start:keypressed(key,scancode,isrepeat)
  if key=='q' or key=='escape' then
    love.event.quit()
  elseif key=='1' then
    difficulty_level = 1
  elseif key=='2' then
    difficulty_level = 2
  elseif key=='3' then
    difficulty_level = 3
  elseif key=='c' then
    SCENE_MANAGER:push('credits')
  elseif key=='m' then
    MUSIC_ENABLED = not MUSIC_ENABLED
  elseif key=='s' then
    scene_play:reset(difficulty_level)
    SCENE_MANAGER:set('play')
  -- TODO: options...
  end
end

function scene_start:mousepressed(x,y,button)
end

return scene_start
