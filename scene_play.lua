local Scene = Scene or require "scene"

local scene_play = Scene('play')

--------------------------------------------------------------------------------
local SHIP_MAP_OFFSET = {24+24,24+24}

local GAME_TICK = 1/64
local SLOW_GAME_TICK = 1/2
local game_dt = 0
local slow_game_dt = 0

local the_ship = nil
local chosen_cell = nil
local chosen_crew = nil
local chosen_crew_idx = 0
local elapsed_time = 0
local paused = false
local MAX_MESSAGES = 100
local the_messages = {}
for i=1,MAX_MESSAGES do the_messages[i] = {} end

local the_score = nil
local the_progress = nil

--------------------------------------------------------------------------------
local function handle_event_crew_death(event, crew)
  if event~='crew_death' then
    print("Unexpected event in handle_event_crew_death", event, crew)
    return
  end
  if crew==chosen_crew then
    chosen_crew = nil
    chosen_crew_idx = 0
  end
  EVENT_MANAGER:emit('score:sub', 10, 'crew_death')
  EVENT_MANAGER:emit('message', string.format("Crew death: %s", crew.name), {1,0.5,0.5})
  love.audio.play(AUDIO.trombone)
end

local function handle_event_score_change(event, value, reason)
  if event=='score:add' then
    the_score.score = the_score.score + value
    the_score.breakdown[reason] = (the_score.breakdown[reason] or 0) + value
  elseif event=='score:sub' then
    the_score.score = the_score.score - value
    the_score.breakdown[reason] = (the_score.breakdown[reason] or 0) - value
  else
    print("Unexpected event in handle_event_score_change", event, value, reason)
  end
  --print(event, value, the_score.score, reason) -- TODO: log
end

local function handle_message(event, message, color)
  local td = elapsed_time/128
  local td_day = math.floor(td)
  local td_hour = math.floor((td - td_day)*60)
  local message = {string.format('[%02i:%02i]', td_day, td_hour), message, color}
  table.insert(the_messages, 1, message)
  table.remove(the_messages)
end

local function handle_add_repair_job(event)
  local d = chosen_cell and chosen_cell.device
  if d and not d.repair_job then
    local j = RepairJob(d.priority,{},d)
    the_ship:add_job(j)
    EVENT_MANAGER:emit('message', string.format("Repair job: %s (efficiency=%i)", j, d.efficiency*100), {0.85,0.85,0.85})
  end
end

local function handle_add_operate_job(event)
  local d = chosen_cell and chosen_cell.device
  if d and not d.operate_job and d.manned and d.enabled then
    local j = OperateJob(d.priority,{},d)
    the_ship:add_job(j)
    EVENT_MANAGER:emit('message', string.format("Operate job: %s", j), {0.85,0.85,0.85})
  end
end


--------------------------------------------------------------------------------
function scene_play:load()
  EVENT_MANAGER:on('crew_death', 'global', handle_event_crew_death)
  EVENT_MANAGER:on('score:add', 'global', handle_event_score_change)
  EVENT_MANAGER:on('score:sub', 'global', handle_event_score_change)
  EVENT_MANAGER:on('message', 'global', handle_message)
  EVENT_MANAGER:on('add_repair_job', 'global', handle_add_repair_job)
  EVENT_MANAGER:on('add_operate_job', 'global', handle_add_operate_job)
end

function scene_play:reset()
  the_ship = Ship()
  chosen_cell = nil
  chosen_crew = nil
  chosen_crew_idx = 0
  the_score = {score=100, breakdown={initial=100}}
  elapsed_time = 0
  paused = false
  for i=1,MAX_MESSAGES do the_messages[i] = {} end
  the_progress = {
    current_node = START_NODE,
    elapsed_progress = 0,
  }

  EVENT_MANAGER:emit('message', "Started travel: "..the_progress.current_node.name, {0.5,1,0.5})
end

--------------------------------------------------------------------------------
function scene_play:enter(prev_scene,...)
  Scene.enter(self, prev_scene, ...)
end

function scene_play:exit(next_scene,...)
  Scene.exit(self, prev_scene, ...)
end

function scene_play:resume(next_scene,...)
  Scene.resume(self, prev_scene, ...)
end

function scene_play:pause(prev_scene,...)
  Scene.pause(self, prev_scene, ...)
end

--------------------------------------------------------------------------------
local function slow_game_tick(dt)
  for _,c in ipairs(the_ship.the_crew) do
    c:slow_update(dt)
  end
  the_ship:slow_update(dt)

  for _,d in ipairs(the_ship.devices) do
    if d.total_health <= AUTO_REPAIR_THRESHOLD and not d.repair_job then
      local j = RepairJob(d.priority,{},d)
      the_ship:add_job(j)
      EVENT_MANAGER:emit('message', string.format("Auto-repair job: %s (health=%i)", j, d.total_health*100), {0.75,0.75,0.75})
    end
  end
end

----------------------------------------
local function game_tick(dt)
  local n = #the_ship.the_crew
  for i=1,n do
    local c = the_ship.the_crew[i]
    c:update(dt)
    if c.level.health <= 0 then
      the_ship.the_crew[i] = nil
      c:die()
    end
  end
  compact(the_ship.the_crew, n)
  the_ship:update(dt)

  the_progress.elapsed_progress = the_progress.elapsed_progress + dt/10
  if the_progress.elapsed_progress >= the_progress.current_node.time then
    the_progress.elapsed_progress = 0
    the_progress.current_node = NODES[the_progress.current_node.next]
    if not the_progress.current_node then
      EVENT_MANAGER:emit('score:add', 1000, 'complete-journey')
      the_progress.current_node = START_NODE -- TODO: actual game WIN screen!
    end
    if the_progress.current_node == FINAL_NODE then
      EVENT_MANAGER:emit('message', "Progressed to final stage of travel: "..the_progress.current_node.name, {0.6,1,0.6})
    else
      EVENT_MANAGER:emit('message', "Progressed to next stage of travel: "..the_progress.current_node.name, {0.5,1,0.5})
      EVENT_MANAGER:emit('score:add', 100, 'level-progression')
    end
  end
end

function scene_play:update(dt)
  if not paused then
    game_dt = game_dt + dt
    slow_game_dt = slow_game_dt + dt
    elapsed_time = elapsed_time + dt
  end

  if slow_game_dt >= SLOW_GAME_TICK then
    slow_game_dt = slow_game_dt - SLOW_GAME_TICK
    slow_game_tick(SLOW_GAME_TICK)
  end

  if game_dt >= GAME_TICK then
    game_dt = game_dt - GAME_TICK
    game_tick(GAME_TICK)
  else
    collectgarbage('step')
  end
end

--------------------------------------------------------------------------------
function scene_play:draw(isactive)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(IMAGES.background, 0, 0)

  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print('FPS',24,0)
  love.graphics.print(tostring(love.timer.getFPS()),48,0)

  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print(string.format('Score: %-6.1f',the_score.score),552,0)

  love.graphics.setColor(1,0.5,1,1)
  local td = elapsed_time/128
  local td_day = math.floor(td)
  local td_hour = math.floor((td - td_day)*60)
  love.graphics.print(string.format('Time: %02i:%02i', td_day, td_hour), 816,0)

  love.graphics.push()
    love.graphics.translate(unpack(SHIP_MAP_OFFSET))
    draw_ship_map_panel(the_ship,chosen_cell,chosen_crew)
  love.graphics.pop()

  love.graphics.push()
    love.graphics.translate(552,24)
    draw_cell_panel(chosen_cell)
  love.graphics.pop()
  --
  love.graphics.push()
    love.graphics.translate(552,360)
    draw_crew_panel(chosen_crew)
  love.graphics.pop()
  --
  love.graphics.push()
    love.graphics.translate(816,24)
    draw_ship_stats_panel(the_ship)
  love.graphics.pop()
  --
  love.graphics.push()
    love.graphics.translate(24,672)
    draw_messages_panel(the_messages)
  love.graphics.pop()
  --
  love.graphics.push()
    love.graphics.translate(816,360)
    draw_jobs_queue_panel(the_ship.jobs_list)
  love.graphics.pop()
  --
  love.graphics.push()
    love.graphics.translate(552,672)
    draw_progress_panel(the_progress)
  love.graphics.pop()

  if not isactive then
    love.graphics.setColor(0.1,0.1,0.2,0.9)
    love.graphics.rectangle('fill',0,0,1080,912)
  end
end

--------------------------------------------------------------------------------
function scene_play:keypressed(key,scancode,isrepeat)
  if key=='q' or key=='escape' then
    SCENE_MANAGER:push('confirm')
  end

  if key=='space' then
    paused = not paused
    collectgarbage('collect')
  end

  if scancode=='.' then
    chosen_crew_idx = 1 + (chosen_crew_idx % #the_ship.the_crew)
  elseif scancode==',' then
    chosen_crew_idx = 1 + ((chosen_crew_idx-2) % #the_ship.the_crew)
  end
  chosen_crew = the_ship.the_crew[chosen_crew_idx]

  if key=='w' then
    SCENE_MANAGER:set('win', the_score, the_progress)
  end
  if key=='l' then
    SCENE_MANAGER:set('lose', the_score, the_progress)
  end

  --[[
  if key=='w' then
    for k,v in ipairs(the_ship.jobs_list) do
      EVENT_MANAGER:emit('message', string.format("%s %s", k,v), {1,1,1})
    end
  end

  if key=='s' then
    for k,v in pairs(the_score.breakdown) do
      EVENT_MANAGER:emit('message', string.format("%s %s", k,v), {1,1,1})
    end
  end
  --]]

  if key=='r' then
    EVENT_MANAGER:emit('add_repair_job')
  end
  if key=='o' then
    EVENT_MANAGER:emit('add_operate_job')
  end
end

function scene_play:mousepressed(x,y,button)
  local a_cell = the_ship:cell(1+(x-SHIP_MAP_OFFSET[1])/24, 1+(y-SHIP_MAP_OFFSET[2])/24)
  if a_cell then
    love.audio.play(AUDIO.click)
    if button == 1 then
      chosen_cell = a_cell  
    elseif button == 2 then
      for i=1,#the_ship.the_crew do
        if math.floor(the_ship.the_crew[i].location.x)==a_cell.x and math.floor(the_ship.the_crew[i].location.y)==a_cell.y then 
          chosen_crew_idx = i
          chosen_crew = the_ship.the_crew[i]
          break
        end
      end
    end
  end

  -- TODO: need real UI elements... this is bad
  if x>550 and x<550+96 and y>24+240 and y<24+288 then
    EVENT_MANAGER:emit('add_repair_job')
  end
  -- TODO: need real UI elements... this is bad
  if (x>550+120 and x<550+240 and y>24+240 and y<24+288) then
    EVENT_MANAGER:emit('add_operate_job')
  end
end

--------------------------------------------------------------------------------
return scene_play
