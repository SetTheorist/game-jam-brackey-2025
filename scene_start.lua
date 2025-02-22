local Scene = Scene or require "scene"

local scene_start = Scene('start')

local cthulhu_green = {112/255,151/255,117/255,1}

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

  love.graphics.setColor(1,1,0.5)
  for i,t in ipairs({
      "Guide the GSS Gigantic to its destination",
      "The newest premiere space-ship from the Acme Corporation,",
      "incorporating all the latest tech to ensure that nothing can go wrong!",
      "",
      "  Left-mouse click = select cell + device",
      "  Right-mouse click = select crewmember",
      "",
      "  Spacebar to pause",
      "",
      "  Instruct them to repair or operate as appropriate.",
      "  Click on-screen buttons or press key to",
      "    [R]epair / [F]ix",
      "    [O]perate / [W]ork",
      "",
      "  Note that {propulsion_power} is what you need to progress",
    }) do
    love.graphics.print(t, 500, 200+15*i)
  end

  love.graphics.setColor(unpack(cthulhu_green))
  love.graphics.print("Dreaming Rlyeh Studio", FONTS.malefissent_20, 24, 912-48)
  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print("Made with LÖVE "..love.getVersion(), 950, 912-24)
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
