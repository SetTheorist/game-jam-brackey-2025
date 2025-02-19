class = require "middleclass"
Anim = require "anim"
pq = require "pq"

level = require "level"
action = require "action"
device = require "device"
ship = require "ship"
crew = require "crew"

local GAME_TICK = 1/64
local game_dt = 0
local SLOW_GAME_TICK = 1/2
local slow_game_dt = 0

local the_ship = nil
local the_crew = {}
the_jobs = {}

local paused = false

FONT_1 = nil

CREW_1_IDLE_IMAGE = nil
CREW_1_WALK_IMAGE = nil
CREW_1_WORK_IMAGE = nil

--CONSOLE_IMAGE = nil
--CONSOLE_ANIM = nil

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
function love.load()
  collectgarbage('setpause',200)
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.keyboard.setKeyRepeat(false)
  --love.keyboard.getKeyFromScancode('w')
  --love.window.setMode(1024, 768, {resizable=false, centered=true, fullscreen=true})

  CREW_1_IDLE_IMAGE = love.graphics.newImage(string.format('art/crew-1-idle.png'))
  CREW_1_WALK_IMAGE = love.graphics.newImage(string.format('art/crew-1-walk.png'))
  CREW_1_WORK_IMAGE = love.graphics.newImage(string.format('art/crew-1-work.png'))

  --CONSOLE_IMAGE = love.graphics.newImage(string.format('art/console.png'))
  --CONSOLE_ANIM = Anim(3,CONSOLE_IMAGE,4,24,24,0,0,0)

  the_ship = Ship(MAP)
  for i,n in ipairs({'pat','chris','terry','dana','francis','jean','jo','jordan','cameron','casey','kelly','ollie'}) do
    the_crew[#the_crew+1] = Crew(n,the_ship)
    if i==5 then break end
  end

  FONT_1 = love.graphics.newFont('font/FreeSans.ttf',20)
end

--------------------------------------------------------------------------------
function love.keypressed(key, scancode, isrepeat)
  if scancode=='q' or scancode=='escape' then
    love.event.quit()
  end

  if scancode=='space' then
    paused = not paused
    collectgarbage('collect')
  end

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

  --CONSOLE_ANIM:update(dt)
end

----------------------------------------
function love.slow_game_tick(dt)
  for _,c in ipairs(the_crew) do
    c:slow_update(dt)
  end
  the_ship:slow_update(dt)

  for _,d in ipairs(the_ship.devices) do
    if d.total_health < 0.5 and not d.repair_job then
      the_jobs[#the_jobs+1] = RepairJob(3.0,{},d)
      print("Repair", d)
    end
  end
end

function love.game_tick(dt)
  for i,c in ipairs(the_crew) do
    c:update(dt)
  end
  the_ship:update(dt)
end

--------------------------------------------------------------------------------
function draw_border()
  local XB = {109/255,155/255,195/255} -- cerulean_frost = Color::rgb(0x6D,0x9B,0xC3)
  local XA = {10/255,17/255,149/255} -- cadmium_blue = Color::rgb(0x0A,0x11,0x95)
  local XC = {150/255,1/255,69/255} -- rose_garnet = Color::rgb(0x96,0x01,0x45)
  local XD = {255/255,228/255,225/255} -- misty_rose = Color::rgb(0xFF,0xE4,0xE1)
  local function border(x,y)
    local t = math.sqrt(x^2+y^2)/math.sqrt(63^2+48^2)
    love.graphics.setColor((XA[1]*t+XD[1]*(1-t)), (XA[2]*t+XD[2]*(1-t)), (XA[3]*t+XD[3]*(1-t)))
    love.graphics.rectangle('fill',x*16,y*16,16,16)
  end
  for x=0,63 do border(x,0);border(x,47) end
  for y=0,47 do border(0,y);border(63,y) end
end

function love.draw()
  draw_border()

  love.graphics.push()
  love.graphics.translate(16,16)
  the_ship:draw_map()
  for i,c in ipairs(the_crew) do
    c:draw()
  end
  --CONSOLE_ANIM.x = 5*24-12
  --CONSOLE_ANIM.y = 5*24-12
  --CONSOLE_ANIM.rotation = 0
  --CONSOLE_ANIM:draw(dt)
  love.graphics.pop()

  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print('FPS',900,16*1)
  love.graphics.print(tostring(love.timer.getFPS()),950,16*1)

  love.graphics.setColor(1,1,1,1)
  local i = 2
  for _,l in pairs(the_ship.level) do
    love.graphics.print(tostring(l),700,16*i)
    i = i+1
  end
  for i,d in ipairs(the_ship.devices) do
    love.graphics.print(tostring(d),700,200+16*i)
  end

  for i,c in ipairs(the_crew) do
    love.graphics.setColor(c.color[1],c.color[2],c.color[3],1.0)
    love.graphics.print(tostring(c),24,520+i*16)
  end

end

--------------------------------------------------------------------------------

