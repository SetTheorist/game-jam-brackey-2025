class = require "middleclass"
Anim = require "anim"
pq = require "pq"

level = require "level"
action = require "action"
device = require "device"
ship = require "ship"
crew = require "crew"
display = require "display"
progress = require "progress"

local GAME_TICK = 1/64
local game_dt = 0
local SLOW_GAME_TICK = 1/2
local slow_game_dt = 0

local the_ship = nil
local the_crew = {}
the_jobs = {}
local ship_map_offset = {16+24,16+24}
chosen_cell = nil
chosen_crew = nil
chosen_crew_idx = 1

the_score = 100

local elapsed_time = 0
local paused = false

FONT_1 = nil

CREW_IMAGE = nil

ELECTRONIC_IMAGE = nil
ELECTRONIC_ANIM = nil
MECHANICAL_IMAGE = nil
MECHANICAL_ANIM = nil
QUANTUM_IMAGE = nil
QUANTUM_ANIM = nil

BED_IMAGE = nil
CONSOLE_IMAGE = nil
CONSOLE_ANIM = nil
REACTOR_IMAGE = nil
REACTOR_ANIM = nil
REACTOR_X,REACTOR_Y = nil,nil
REACTOR4_IMAGE = nil
REACTOR4_ANIM = nil

SHIP_FRAME_IMAGE = nil
MACHINE_1_IMAGE = nil
MACHINE_1_ANIM = nil
MACHINE_2_IMAGE = nil
MACHINE_2_ANIM = nil
CONSOLE_1_IMAGE = nil
CONSOLE_1_ANIM = nil

AUDIO = {}

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

  FONT_1 = love.graphics.newFont('font/FreeSans.ttf',20)

  AUDIO.click = love.audio.newSource('audio/click.wav', 'static')

  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.keyboard.setKeyRepeat(false)
  --love.keyboard.getKeyFromScancode('w')
  --love.window.setMode(1024, 768, {resizable=false, centered=true, fullscreen=true})

  CREW_IMAGE = love.graphics.newImage(string.format('art/crew.png'))

  SHIP_FRAME_IMAGE = love.graphics.newImage(string.format('art/ship-frame.png'))

  ELECTRONIC_IMAGE = love.graphics.newImage(string.format('art/electronic.png'))
  ELECTRONIC_ANIM = {
    Anim(3.6,ELECTRONIC_IMAGE,5,1,24,24,0,0,0),
    Anim(4.1,ELECTRONIC_IMAGE,5,1,24,24,0,24,0),
    Anim(4.6,ELECTRONIC_IMAGE,5,1,24,24,0,48,0)}
  MECHANICAL_IMAGE = love.graphics.newImage(string.format('art/mechanical.png'))
  MECHANICAL_ANIM = {
    Anim(3.6,MECHANICAL_IMAGE,5,1,24,24,0,0,0),
    Anim(4.1,MECHANICAL_IMAGE,5,1,24,24,0,24,0),
    Anim(4.6,MECHANICAL_IMAGE,5,1,24,24,0,48,0)}
  QUANTUM_IMAGE = love.graphics.newImage(string.format('art/quantum.png'))
  QUANTUM_ANIM = {
    Anim(3.5,QUANTUM_IMAGE,5,1,24,24,0,0,0),
    Anim(3.9,QUANTUM_IMAGE,5,1,24,24,0,24,0),
    Anim(4.3,QUANTUM_IMAGE,5,1,24,24,0,48,0)}
  BED_IMAGE = love.graphics.newImage(string.format('art/bed.png'))
  CONSOLE_1_IMAGE = love.graphics.newImage(string.format('art/console-1.png'))
  CONSOLE_1_ANIM = Anim(3,CONSOLE_1_IMAGE,4,1,48,24,0,0,0)
  MACHINE_1_IMAGE = love.graphics.newImage(string.format('art/machine-1.png'))
  MACHINE_1_ANIM = Anim(3,MACHINE_1_IMAGE,4,1,48,24,0,0,0)
  MACHINE_2_IMAGE = love.graphics.newImage(string.format('art/machine-2.png'))
  MACHINE_2_ANIM = Anim(3,MACHINE_2_IMAGE,4,1,48,24,0,0,0)
  CONSOLE_IMAGE = love.graphics.newImage(string.format('art/console.png'))
  CONSOLE_ANIM = Anim(3,CONSOLE_IMAGE,4,1,24,24,0,0,0)
  REACTOR_IMAGE = love.graphics.newImage(string.format('art/reactor.png'))
  REACTOR_ANIM = Anim(8,REACTOR_IMAGE,10,1,24,24,0,0,0)
  REACTOR4_IMAGE = love.graphics.newImage(string.format('art/reactor-4.png'))
  REACTOR4_ANIM = Anim(7,REACTOR4_IMAGE,8,1,48,48,0,0,0)



  the_ship = Ship()
  for i,n in ipairs({'pat','chris','terry','dana','francis','jean','jo','jordan','cameron','casey','kelly','ollie'}) do
    the_crew[#the_crew+1] = Crew(n,the_ship)
    --if i==5 then break end
  end
  chosen_crew = the_crew[chosen_crew_idx]

  local r = the_ship:locate_device('ReactorCore',0,0)
  REACTOR_X,REACTOR_Y = r.cell.x,r.cell.y
end

--------------------------------------------------------------------------------
function love.mousepressed(x,y,button,istouch,presses)
  local a_cell = the_ship:cell(1+(x-ship_map_offset[1])/24, 1+(y-ship_map_offset[2])/24)
  if a_cell then
    chosen_cell = a_cell  
    love.audio.play(AUDIO.click)
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
    chosen_crew_idx = 1 + (chosen_crew_idx % #the_crew)
  elseif scancode==',' then
    chosen_crew_idx = 1 + ((chosen_crew_idx-2) % #the_crew)
  end
  chosen_crew = the_crew[chosen_crew_idx]

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

  CONSOLE_ANIM:update(dt)
  REACTOR4_ANIM:update(dt)
  MACHINE_1_ANIM:update(dt)
  MACHINE_2_ANIM:update(dt)
  CONSOLE_1_ANIM:update(dt)
end

----------------------------------------
function love.slow_game_tick(dt)
  for _,c in ipairs(the_crew) do
    c:slow_update(dt)
  end
  the_ship:slow_update(dt)

  for _,d in ipairs(the_ship.devices) do
    if d.total_health <= 1/64 and not d.repair_job then
      the_jobs[#the_jobs+1] = RepairJob(3.0,{},d)
      print("Auto-Repair", d)
    end
  end
end

function love.game_tick(dt)
  local n = #the_crew
  for i=1,n do
    local c = the_crew[i]
    c:update(dt)
    if c.level.health <= 0 then
      the_crew[i] = nil
      c:die()
      print("Dead:", c)
    end
  end
  compact(the_crew, n)
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

  love.graphics.push()
    love.graphics.translate(unpack(ship_map_offset))
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(SHIP_FRAME_IMAGE,0-24,0-24) -- XXX - using 0.5 here gives aliasing
    the_ship:draw_map()
    love.graphics.setColor(1,1,1,1)
    for i,c in ipairs(the_crew) do
      c:draw()
      if c == chosen_crew then
        love.graphics.setColor(1,0,1,0.8)
        love.graphics.circle('line',(c.location.x-1)*24,(c.location.y-1)*24,12)
        love.graphics.setColor(1,1,1,1)
      end
    end
    love.graphics.setColor(1,1,1,1)
    CONSOLE_ANIM.x = 4*24-12
    CONSOLE_ANIM.y = 2*24-12
    CONSOLE_ANIM.rotation = 0
    CONSOLE_ANIM:draw(dt)
    love.graphics.setColor(1,1,1,1)
    REACTOR4_ANIM.x = REACTOR_X*24+76-4
    REACTOR4_ANIM.y = REACTOR_Y*24
    REACTOR4_ANIM.rotation = 0
    REACTOR4_ANIM:draw()
    if chosen_cell then
      love.graphics.setColor(1,0,1,0.8)
      love.graphics.rectangle('line',(chosen_cell.x-1)*24,(chosen_cell.y-1)*24,24,24)
    end

    MACHINE_1_ANIM.x = (6-1)*24
    MACHINE_1_ANIM.y = (2.5-1)*24
    MACHINE_1_ANIM.rotation = 0
    MACHINE_1_ANIM:draw()
    MACHINE_2_ANIM.x = (9-1)*24
    MACHINE_2_ANIM.y = (2.5-1)*24
    MACHINE_2_ANIM.rotation = 0
    MACHINE_2_ANIM:draw()

    CONSOLE_1_ANIM.x = (3-1)*24
    CONSOLE_1_ANIM.y = (2.5-1)*24
    CONSOLE_1_ANIM.rotation = 0
    CONSOLE_1_ANIM:draw()

  love.graphics.pop()

  love.graphics.setColor(1,0.5,1,1)
  love.graphics.print('FPS',900,0)
  love.graphics.print(tostring(love.timer.getFPS()),950,0)

  local td = elapsed_time/128
  local td_day = math.floor(td)
  local td_hour = math.floor((td - td_day)*60)
  love.graphics.print(
    string.format('Time: %02i:%02i', td_day, td_hour), 900,16*1)

  love.graphics.push()
    love.graphics.translate(24,600+48)
    draw_crew_panel()
  love.graphics.pop()

  love.graphics.push()
    love.graphics.translate(550,20)
    draw_cell_panel()
  love.graphics.pop()

  love.graphics.push()
    love.graphics.translate(800,32)
    draw_ship_panel(the_ship)
  love.graphics.pop()
end

--------------------------------------------------------------------------------

