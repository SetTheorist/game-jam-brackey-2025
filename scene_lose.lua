local Scene = Scene or require "scene"

local scene_lose = Scene('lose')

local game_score = nil
local game_score_breakdown = nil
local game_progress = nil
local game_reason = nil
local game_difficulty = 1
local elapsed = 0
local MUSIC = nil

function scene_lose:load()
  MUSIC = AUDIO.crime
end

----------------------------------------
function scene_lose:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
  if MUSIC then MUSIC:stop() end
end

----------------------------------------
function scene_lose:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end
end

----------------------------------------
function scene_lose:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
  if MUSIC then MUSIC:pause() end
end

----------------------------------------
function scene_lose:enter(prev_scene, the_reason, the_score, the_progress, the_difficulty, ...)
  Scene.enter(self, prev_scene, ...)
  if MUSIC and MUSIC_ENABLED then MUSIC:play() end

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
function scene_lose:update(dt)
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
  elapsed = elapsed + dt/5
end

----------------------------------------
function scene_lose:draw(isactive)
  local c = love.math.noise(elapsed)/5
  love.graphics.clear(c,c,c,1)

  love.graphics.setColor(0,1,0)
  love.graphics.print("YOU LOST!", FONTS.torek_42, 100-4, 100-4)
  love.graphics.setColor(0,0,1)
  love.graphics.print("YOU LOST!", FONTS.torek_42, 100  , 100  )
  love.graphics.setColor(1,0,0)
  love.graphics.print("YOU LOST!", FONTS.torek_42, 100+4, 100+4)

  love.graphics.setColor(1,1,1)
  love.graphics.print(game_reason, FONTS.torek_42, 150, 200)

  love.graphics.setColor(1,1,0)
  love.graphics.print("Difficulty level "..({"EASY","NORMAL","IMPOSSIBLE"})[game_difficulty], FONTS.torek_16, 150, 500)

  love.graphics.setColor(0,1,0)
  love.graphics.print("Press Q key", FONTS.torek_42, 200-4, 300-4)
  love.graphics.setColor(0,0,1)
  love.graphics.print("Press Q key", FONTS.torek_42, 200  , 300  )
  love.graphics.setColor(1,0,0)
  love.graphics.print("Press Q key", FONTS.torek_42, 200+4, 300+4)

  love.graphics.setColor(0,1,0)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200-4, 400-4)
  love.graphics.setColor(0,0,1)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200  , 400  )
  love.graphics.setColor(1,0,0)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200+4, 400+4)

  love.graphics.setColor(1,1,1)
  love.graphics.print(
      string.format("Progressed %0.01f/%0.01f in %s",
        game_progress.elapsed_progress, game_progress.current_node.time,
        game_progress.current_node.name),
      100, 550)

  love.graphics.setColor(1,1,1)
  love.graphics.print(string.format("Final score: %0.01f", game_score.score), 100, 600)
  for i,x in ipairs(game_score_breakdown) do
    love.graphics.print(string.format("%s: %0.01f", x[1], x[2]), 124+math.floor(i/20)*240, 624+(1+(i%20))*12)
  end
end

----------------------------------------
function scene_lose:keypressed(key,scancode,isrepeat)
  if key=='q' then
    SCENE_MANAGER:set('start')
  end
end

----------------------------------------
return scene_lose

