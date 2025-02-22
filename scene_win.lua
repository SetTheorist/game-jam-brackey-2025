local Scene = Scene or require "scene"

local scene_win = Scene('win')

local game_score = nil
local game_progress = nil

function scene_win:enter(prev_scene, the_score, the_progress)
  game_score = the_score
  game_progress = the_progress
end

function scene_win:draw(isactive)
  love.graphics.setColor(1,0,0)
  love.graphics.print("YOU WON!", FONTS.torek_42, 100-4, 100-4)
  love.graphics.setColor(0,0,1)
  love.graphics.print("YOU WON!", FONTS.torek_42, 100  , 100  )
  love.graphics.setColor(0,1,0)
  love.graphics.print("YOU WON!", FONTS.torek_42, 100+4, 100+4)

  love.graphics.setColor(1,0,0)
  love.graphics.print("Press any key", FONTS.torek_42, 200-4, 300-4)
  love.graphics.setColor(0,0,1)
  love.graphics.print("Press any key", FONTS.torek_42, 200  , 300  )
  love.graphics.setColor(0,1,0)
  love.graphics.print("Press any key", FONTS.torek_42, 200+4, 300+4)

  love.graphics.setColor(1,0,0)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200-4, 400-4)
  love.graphics.setColor(0,0,1)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200  , 400  )
  love.graphics.setColor(0,1,0)
  love.graphics.print("to return to main menu", FONTS.torek_42, 200+4, 400+4)

  love.graphics.setColor(1,1,1)
  love.graphics.print(string.format("Final score: %0.01f", game_score.score), 100, 600)
  local i = 0
  for k,v in pairs(game_score.breakdown) do
    love.graphics.print(string.format("%s - %0.01f", k, v), 124, 624+i*12)
    i = i+1
  end
end

function scene_win:keypressed(key,scancode,isrepeat)
  SCENE_MANAGER:set('start')
end

return scene_win

