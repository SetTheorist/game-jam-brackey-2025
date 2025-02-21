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

local SHIP_MAP_OFFSET = {16+24,16+24}

EVENT_MANAGER = nil

the_ship = nil
the_jobs = {}
local chosen_cell = nil
local chosen_crew = nil
local chosen_crew_idx = 0
local the_score = 100
local elapsed_time = 0
local paused = false

FONT_1 = nil
AUDIO = {}

-- TODO: make these adjustable in-game...
-- (game difficulties: decay factor, crew speed factors)
GLOBAL_DECAY_FACTOR = 1.0
AUTO_REPAIR_THRESHOLD = 0.05

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
  print("Crew death", crew) -- TODO: log
  if crew==chosen_crew then
    chosen_crew = nil
    chosen_crew_idx = 0
  end
  EVENT_MANAGER:emit('score:sub', 10, 'crew_death')
end

function handle_event_score_change(event, value)
  if event=='score:add' then
    the_score = the_score + value
  elseif event=='score:sub' then
    the_score = the_score - value
  else
    print("Unexpected event in handle_event_score_change", event, value)
  end
  print(event, value, the_score) -- TODO: log
end

--------------------------------------------------------------------------------
--love.keyboard.getKeyFromScancode('w')
--love.window.setMode(1024, 768, {resizable=false, centered=true, fullscreen=true})
function love.load()
  collectgarbage('setpause',200)
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.keyboard.setKeyRepeat(false)

  FONT_1 = love.graphics.newFont('font/FreeSans.ttf',20)
  AUDIO.click = love.audio.newSource('audio/click.wav', 'static')
  load_images()

  EVENT_MANAGER = EventManager()
  EVENT_MANAGER:on('crew_death', 'global', handle_event_crew_death)
  EVENT_MANAGER:on('score:add', 'global', handle_event_score_change)
  EVENT_MANAGER:on('score:sub', 'global', handle_event_score_change)

  the_ship = Ship()
end

--------------------------------------------------------------------------------
function love.mousepressed(x,y,button,istouch,presses)
  local a_cell = the_ship:cell(1+(x-SHIP_MAP_OFFSET[1])/24, 1+(y-SHIP_MAP_OFFSET[2])/24)
  if a_cell then
    chosen_cell = a_cell  
    love.audio.play(AUDIO.click)
    for i=1,#the_ship.the_crew do
      if math.floor(the_ship.the_crew[i].location.x)==a_cell.x and math.floor(the_ship.the_crew[i].location.y)==a_cell.y then 
        chosen_crew_idx = i
        chosen_crew = the_ship.the_crew[i]
        break
      end
    end
  end

  -- TODO: need real UI elements... this is bad
  if (x>550+10.5 and x<550+60.5 and y>20+179.5 and y<20+199.5) and chosen_cell and not chosen_cell.device.repair_job then
    the_jobs[#the_jobs+1] = RepairJob(3.0,{},chosen_cell.device)
    print("Repair", chosen_cell.device)
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
    for k,v in ipairs(the_jobs) do
      print(k,v)
    end
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
      the_jobs[#the_jobs+1] = RepairJob(3.0,{},d)
      -- TODO: write to messages log... (auto-repair)
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
end

--------------------------------------------------------------------------------
function draw_border()
  local XD = {10/255,10/255,20/255}
  local XA = {255/255/4,228/255/4,225/255/4}
  local XE = {109/255,155/255,195/255} -- cerulean_frost = Color::rgb(0x6D,0x9B,0xC3)
  local XB = {10/255,17/255,149/255} -- cadmium_blue = Color::rgb(0x0A,0x11,0x95)
  local XC = {150/255,1/255,69/255} -- rose_garnet = Color::rgb(0x96,0x01,0x45)
  local XF = {255/255,228/255,225/255} -- misty_rose = Color::rgb(0xFF,0xE4,0xE1)
  local function border(x,y)
    local t = math.sqrt(x^2+y^2)/math.sqrt(63^2+48^2)
    love.graphics.setColor((XA[1]*t+XD[1]*(1-t)), (XA[2]*t+XD[2]*(1-t)), (XA[3]*t+XD[3]*(1-t)))
    love.graphics.rectangle('fill',x*16,y*16,16,16)
  end
  for x=0,79 do border(x,0);border(x,55) end
  for y=0,55 do border(0,y);border(79,y) end
end

function love.draw()
  draw_border()

  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print('FPS',900,0)
  love.graphics.print(tostring(love.timer.getFPS()),950,0)

  local td = elapsed_time/128
  local td_day = math.floor(td)
  local td_hour = math.floor((td - td_day)*60)
  love.graphics.print(
    string.format('Time: %02i:%02i', td_day, td_hour), 900,16*1)

  love.graphics.push()
    love.graphics.translate(unpack(SHIP_MAP_OFFSET))
    draw_ship_map_panel(the_ship,chosen_cell,chosen_crew)
  love.graphics.pop()

  love.graphics.push()
    love.graphics.translate(24,600+48)
    draw_crew_panel(chosen_crew)
  love.graphics.pop()

  love.graphics.push()
    love.graphics.translate(550,20)
    draw_cell_panel(chosen_cell)
  love.graphics.pop()

  love.graphics.push()
    love.graphics.translate(800,32)
    draw_ship_stats_panel(the_ship)
  love.graphics.pop()
end

--------------------------------------------------------------------------------

