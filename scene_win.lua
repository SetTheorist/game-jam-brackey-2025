local Scene = Scene or require "scene"

local scene_win = Scene('win')

local game_score = nil
local game_score_breakdown = nil
local game_progress = nil
local game_reason = nil
local particle_systems = {}
local game_difficulty = 1
local elapsed = 0
local MUSIC = nil

local COLORS = {
  {1,1,1,0.8},
  --
  {1,0,0,0.8},
  {0,1,0,0.8},
  {0,0,1,0.8},
  --
  {0,1,1,0.8},
  {1,0,1,0.8},
  {1,1,0,0.8},
  --
  {0.5,0.5,0.5,1},
  --
  {1,0.5,0.5,1},
  {0.5,1,0.5,1},
  {0.5,0.5,1,1},
  --
  {0.5,1,1,1},
  {1,0.5,1,1},
  {1,1,0.5,1},
}

----------------------------------------
function scene_win:load()
  local ps = love.graphics.newParticleSystem(PARTICLES.diamond, 128)
  ps:setEmissionRate(20)
  ps:setEmitterLifetime(-1)
  ps:setSpread(2*math.pi)
  ps:setRadialAcceleration(1,20)
  ps:setParticleLifetime(3,10)
  ps:setSpeed(50,200)
  ps:setRelativeRotation(true)
  ps:setPosition(540,456)
  ps:setSpinVariation(1)
  ps:setSizes(0.5,0.9,0.9,1.0)
  particle_systems[1] = ps
  for i=2,14 do
    particle_systems[i] = ps:clone()
  end
  for i,ps in ipairs(particle_systems) do
    ps:setColors(unpack(COLORS[i]))
    ps:setPosition(540+love.math.random(51)-25,456+love.math.random(51)-25)
    if (i%3)==0 then
      ps:setTexture(PARTICLES.star)
    end
  end

  MUSIC = AUDIO.elevator
end

----------------------------------------
function scene_win:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
  if MUSIC then MUSIC:stop() end
end

----------------------------------------
function scene_win:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

----------------------------------------
function scene_win:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
  if MUSIC then MUSIC:pause() end
end

----------------------------------------
function scene_win:enter(prev_scene, the_reason, the_score, the_progress, the_difficulty, ...)
  Scene.enter(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
  AUDIO.applause:play()

  game_score = the_score
  game_progress = the_progress
  game_reason = the_reason
  game_difficulty = the_difficulty

  game_score_breakdown = {}
  for k,v in pairs(game_score.breakdown) do
    game_score_breakdown[#game_score_breakdown+1] = {k,v}
  end
  table.sort(game_score_breakdown,
    function(a,b)
      return ((math.abs(a[2])>math.abs(b[2]))
        or (math.abs(a[2])==math.abs(b[2]) and a[2]>b[2])
        or (a[2]==b[2] and a[1]<b[1])
        )
    end)
end

----------------------------------------
function scene_win:update(dt)
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
  for _,ps in ipairs(particle_systems) do
    ps:update(dt)
  end
  elapsed = elapsed + dt/5
end

----------------------------------------
function scene_win:draw(isactive)
  local c = love.math.noise(elapsed)
  love.graphics.clear(0.25*c,0.25*c,0.3*c,1)

  love.graphics.setColor(1,1,1,1)
  for _,ps in ipairs(particle_systems) do
    love.graphics.draw(ps)
  end

  love.graphics.setColor(1,0.25,0.25)
  love.graphics.print("YOU WON!", FONTS.torek_42, 100-4, 100-4)
  love.graphics.setColor(0.25,0.25,1)
  love.graphics.print("YOU WON!", FONTS.torek_42, 100  , 100  )
  love.graphics.setColor(0.25,1,0.25)
  love.graphics.print("YOU WON!", FONTS.torek_42, 100+4, 100+4)

  love.graphics.setColor(1,1,0)
  love.graphics.print("Difficulty level "..({"EASY","NORMAL","IMPOSSIBLE"})[game_difficulty], FONTS.torek_16, 150, 500)

  love.graphics.setColor(1,0.25,0.25)
  love.graphics.print("Press Q key", FONTS.torek_42, 200-4, 300-4)
  love.graphics.setColor(0.25,0.25,1)
  love.graphics.print("Press Q key", FONTS.torek_42, 200  , 300  )
  love.graphics.setColor(0.25,1,0.25)
  love.graphics.print("Press Q key", FONTS.torek_42, 200+4, 300+4)

  love.graphics.setColor(1,0.25,0.25)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200-4, 400-4)
  love.graphics.setColor(0.25,0.25,1)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200  , 400  )
  love.graphics.setColor(0.25,1,0.25)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200+4, 400+4)


  love.graphics.setColor(1,1,1)
  love.graphics.print(string.format("Final score: %0.01f", game_score.score), 100, 600)
  for i,x in ipairs(game_score_breakdown) do
    love.graphics.print(string.format("%s: %0.01f", x[1], x[2]), 124+math.floor(i/20)*240, 624+(1+(i%20))*12)
  end
end

----------------------------------------
function scene_win:keypressed(key,scancode,isrepeat)
  if key=='q' then
    SCENE_MANAGER:set('start')
  end
end

----------------------------------------
return scene_win

