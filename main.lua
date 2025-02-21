class = require "middleclass"
pq = require "pq"
EventManager = require "event"
Anim = require "anim"

images = require "images"
level = require "level"
action = require "action"
device = require "device"
ship = require "ship"
crew = require "crew"
display = require "display"
progress = require "progress"
state = require "state"

local GAME_TICK = 1/64
local game_dt = 0
local SLOW_GAME_TICK = 1/2
local slow_game_dt = 0

local SHIP_MAP_OFFSET = {24+24,24+24}

EVENT_MANAGER = nil

local the_ship = nil
local chosen_cell = nil
local chosen_crew = nil
local chosen_crew_idx = 0
local the_score = {score=100, breakdown={}}
local elapsed_time = 0
local paused = false
local MAX_MESSAGES = 100
local the_messages = {}
for i=1,MAX_MESSAGES do the_messages[i] = {} end

local the_progress = {
  current_node = START_NODE,
  elapsed_progress = 0,
}

VERSION = 1.0
FONTS = {}
AUDIO = {}

-- TODO: make these adjustable in-game...
-- (game difficulties: decay factor, crew speed factors)
GLOBAL_DECAY_FACTOR = 10.0
AUTO_REPAIR_THRESHOLD = 0.25

--------------------------------------------------------------------------------

-- compacts all entries 1..n removing nils, returns count of non-nil entries
function compact(arr,n)
  local t=0
  for i=1,n do
    if arr[i]~=nil then
      t = t+1
      if t ~= i then
        arr[t],arr[i] = arr[i],nil
      end
    end
  end
  return t
end

--------------------------------------------------------------------------------

function handle_event_crew_death(event, crew)
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
end

function handle_event_score_change(event, value, reason)
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

function handle_message(event, message, color)
  local td = elapsed_time/128
  local td_day = math.floor(td)
  local td_hour = math.floor((td - td_day)*60)
  local message = {string.format('[%02i:%02i]', td_day, td_hour), message, color}
  table.insert(the_messages, 1, message)
  table.remove(the_messages)
end

function handle_add_repair_job(event)
  local d = chosen_cell and chosen_cell.device
  if d and not d.repair_job then
    local j = RepairJob(d.priority,{},d)
    the_ship:add_job(j)
    EVENT_MANAGER:emit('message', string.format("Repair job: %s (efficiency=%i)", j, d.efficiency*100), {0.85,0.85,0.85})
  end
end

function handle_add_operate_job(event)
  local d = chosen_cell and chosen_cell.device
  if d and not d.operate_job then
    local j = OperateJob(d.priority,{},d)
    the_ship:add_job(j)
    EVENT_MANAGER:emit('message', string.format("Operate job: %s", j), {0.85,0.85,0.85})
  end
end

--------------------------------------------------------------------------------
--love.keyboard.getKeyFromScancode('w')
--love.window.setMode(1024, 768, {resizable=false, centered=true, fullscreen=true})
function love.load()
  collectgarbage('setpause',200)
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.keyboard.setKeyRepeat(false)

  FONTS.torek = love.graphics.newFont('font/ToreksRegular.otf',16)
  AUDIO.click = love.audio.newSource('audio/click.wav', 'static')
  load_images()

  EVENT_MANAGER = EventManager()
  EVENT_MANAGER:on('crew_death', 'global', handle_event_crew_death)
  EVENT_MANAGER:on('score:add', 'global', handle_event_score_change)
  EVENT_MANAGER:on('score:sub', 'global', handle_event_score_change)
  EVENT_MANAGER:on('message', 'global', handle_message)
  EVENT_MANAGER:on('add_repair_job', 'global', handle_add_repair_job)
  EVENT_MANAGER:on('add_operate_job', 'global', handle_add_operate_job)

  the_ship = Ship()

  EVENT_MANAGER:emit('message', "Started travel: "..the_progress.current_node.name, {0.5,1,0.5})
end

--------------------------------------------------------------------------------
function love.mousepressed(x,y,button,istouch,presses)
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

--function love.mousereleased(x,y,button,istouch,presses) end
--function love.mousemoved(x,y,dx,dy,istouch) end

--------------------------------------------------------------------------------
function love.keypressed(key, scancode, isrepeat)
  if scancode=='q' or scancode=='escape' then
    love.event.quit()
  end

  if scancode=='space' then
    paused = not paused
    collectgarbage('collect')
  end

  if scancode=='.' then
    chosen_crew_idx = 1 + (chosen_crew_idx % #the_ship.the_crew)
  elseif scancode==',' then
    chosen_crew_idx = 1 + ((chosen_crew_idx-2) % #the_ship.the_crew)
  end
  chosen_crew = the_ship.the_crew[chosen_crew_idx]

  if scancode=='w' then
    for k,v in ipairs(the_ship.jobs_list) do
      EVENT_MANAGER:emit('message', string.format("%s %s", k,v), {1,1,1})
    end
  end

  if scancode=='s' then
    for k,v in pairs(the_score.breakdown) do
      EVENT_MANAGER:emit('message', string.format("%s %s", k,v), {1,1,1})
    end
  end

  if scancode=='r' then
    EVENT_MANAGER:emit('add_repair_job')
  end
  if scancode=='o' then
    EVENT_MANAGER:emit('add_operate_job')
  end
end

function love.keyreleased(key, scancode)
end

--------------------------------------------------------------------------------
function love.update(dt)
  if not paused then
    game_dt = game_dt + dt
    slow_game_dt = slow_game_dt + dt
    elapsed_time = elapsed_time + dt
  end

  if slow_game_dt >= SLOW_GAME_TICK then
    slow_game_dt = slow_game_dt - SLOW_GAME_TICK
    love.slow_game_tick(SLOW_GAME_TICK)
  end

  if game_dt >= GAME_TICK then
    game_dt = game_dt - GAME_TICK
    love.game_tick(GAME_TICK)
  else
    collectgarbage('step')
  end
end

----------------------------------------
function love.slow_game_tick(dt)
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

function love.game_tick(dt)
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

--------------------------------------------------------------------------------

function love.draw()
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
end

--------------------------------------------------------------------------------

