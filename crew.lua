
local class = class or require "middleclass"

Crew = class("Crew")

--[[
STATES:
  idle
  walk
  repair
  operate
  sleep
  eat?
--]]

--[[
EFFECTS:
  respiration
  digestion
  stress
  healing
  sleep
  insanity
  fire
  radiation
--]]

function Crew:initialize(name,ship)
  self.ship = ship
  self.skills = {
    combat_melee=math.floor(love.math.random()*128)/128,
    combat_ranged=math.floor(love.math.random()*128)/128,
    manning_comms=math.floor(love.math.random()*128)/128,
    manning_navigations=math.floor(love.math.random()*128)/128,
    manning_propulsion=math.floor(love.math.random()*128)/128,
    manning_reactor=math.floor(love.math.random()*128)/128,
    manning_sensors=math.floor(love.math.random()*128)/128,
    manning_shields=math.floor(love.math.random()*128)/128,
    manning_weapons=math.floor(love.math.random()*128)/128,
    repair_electronic=math.floor(love.math.random()*128)/128,
    repair_mechanical=math.floor(love.math.random()*128)/128,
    repair_quantum=math.floor(love.math.random()*128)/128,
    zen=math.floor(love.math.random()*128)/128,
    }

  self.level = {
    health=100-10*love.math.random(),
    food=10+50*love.math.random(),
    o2=120,
    waste=1,
    rest=100,
    stress=10,
    }
  self.name = name
  self.walk_speed = 1.0 + 3.0*math.floor(love.math.random()*64)/64
  self.work_speed = 1/2 + math.floor(love.math.random()*64)/64*(3/4)
  self.color = {0.5+love.math.random()*0.5,0.5+love.math.random()*0.5,0.5+love.math.random()*0.5}
  self.color[love.math.random(3)] = 0.0
  self.animations = {
    idle=Anim(4,CREW_1_IDLE_IMAGE,4,24,24,0,0,0),
    walk=Anim(6*(self.walk_speed/4),CREW_1_WALK_IMAGE,4,24,24,0,0,0),
    operate=Anim(6*(self.work_speed),CREW_1_WORK_IMAGE,4,24,24,0,0,0),
    repair=Anim(6*(self.work_speed),CREW_1_WORK_IMAGE,4,24,24,0,0,0),
    }
  self.anim = self.animations.walk

  self.effects = {}
  
  self.location = {x=love.math.random(3,10)+0.5,y=love.math.random(3,5)+0.5}
  self.facing = 0

  self.inventory = {food=0}

  self.current_job = nil
  self.current_action = Action(self,nil)
  self.action_stack = {}

  self.claim_job = nil
  self.claim_device = nil
end

function Crew:__tostring()
  return string.format("<%s@%0.01f,%0.01f|o%0.01f,h%0.01f,f%0.01f,r%0.01f,s%0.01f,w%0.01f|%s>", self.name,
    self.location.x, self.location.y,
    self.level.o2, self.level.health, self.level.food, self.level.rest, self.level.stress, self.level.waste,
    (self.current_action or '-')
    )
end

function Crew:slow_update(dt)
  local to_remove = {}
  local n = #self.effects
  for i=1,n do
    if self.effects[i].slow_update(dt) then
      -- remove
    end
  end

  -- check basic needs
  if self.level.health < 50 then
    print(self,"medical-1")
  elseif self.level.health < 10 then
    print(self,"medical-2")
  elseif self.level.food < 10 then
    print(self,"food-1")
  elseif self.level.food < 1 then
    print(self,"food-2")
  elseif self.level.waste > 10 then
    print(self,"waste-1")
  elseif self.level.rest < 10 then
    print(self,"rest-1")
  elseif self.level.stress > 100 then
    print(self,"stress-1")
  end
end

-- TODO: should look at global job queue, etc.
function Crew:new_action()
  if #self.action_stack>0 then
    self.current_action = self.action_stack[#self.action_stack]
    self.action_stack[#self.action_stack] = nil
    self.current_action:start()
    return
  end

  if #the_jobs > 0 then
    local j = the_jobs[1]
    if j:check_skills(self) then
      self.current_action:start()
      return
    end
  end

  if love.math.random()<0.50 then
    self.current_action = WaitAction(nil, self, love.math.random()+0.5)
  else
    local c1
    repeat
      c1 = love.math.random(#self.ship.cells)
    until self.ship.cells[c1].passable
    self.current_action = WalkAction(nil, self, self.ship.cells[c1])
    self.current_action:start()
  end
  self.current_action:start()
end

function Crew:update(dt)
  local to_remove = {}
  local n = #self.effects
  for i=1,n do
    if self.effects[i].update(dt) then
      -- remove
    end
  end

  -- TODO: replenish o2 if <max
  local do2 = self.ship.level.o2:sub(2*dt)
  self.level.o2 = self.level.o2 - (2*dt - do2)
  self.ship.level.co2:add(dt)
  self.ship.level.temp:add(dt/16)

  self.level.health = math.min(100.0, self.level.health + dt*1/256)
  self.level.food = math.min(100.0, self.level.food - dt*1/64)
  self.level.rest = math.min(100.0, self.level.rest - dt*1/64)
  self.level.stress = math.min(1000.0, self.level.stress + dt*1/64)
  self.level.waste = math.min(200.0, self.level.waste + dt*1/128)

  if not self.current_action then
    self:new_action()
  else
    local res = self.current_action:execute(dt)
    if res ~= 'in-progress' then
      self:new_action()
    end
  end

  self.anim.x = (self.location.x-1)*24
  self.anim.y = (self.location.y-1)*24
  self.anim.rotation = self.facing
  self.anim:update(dt)
end

function Crew:draw()
  if self.current_action and self.current_action.path then
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],0.25)
    local the_path = self.current_action.path
    if the_path then
      for i=1,#the_path-1 do
        local x0,y0 = unpack(the_path[i])
        local x1,y1 = unpack(the_path[i+1])
        love.graphics.line((x0-1)*24+12,(y0-1)*24+12,(x1-1)*24+12,(y1-1)*24+12)
      end
    end
  end
  --
  love.graphics.setColor(1,1,1,1)
  self.anim:draw()
  love.graphics.setColor(self.color[1],self.color[2],self.color[3],1.0)
  local x = (self.location.x-1)*24
  local y = (self.location.y-1)*24
  love.graphics.circle('fill', x, y, 3)
end



