
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
    combat_melee  = love.math.random(128)/128,
    combat_ranged = love.math.random(128)/128,
    manning_comms       = love.math.random(128)/128,
    manning_navigations = love.math.random(128)/128,
    manning_propulsion  = love.math.random(128)/128,
    manning_reactor     = love.math.random(128)/128,
    manning_sensors     = love.math.random(128)/128,
    manning_shields     = love.math.random(128)/128,
    manning_weapons     = love.math.random(128)/128,
    repair_electronic = love.math.random(128)/128,
    repair_mechanical = love.math.random(128)/128,
    repair_quantum    = love.math.random(128)/128,
    zen = love.math.random(128)/128,
    }

  self.level = {
    health=100-50*love.math.random(64)/64,
    food=10+50*love.math.random(64)/64,
    o2=120,
    waste=1+10*love.math.random(64)/64,
    rest=100-30*love.math.random(64)/64,
    stress=10,
    }
  self.name = name
  self.walk_speed = 2.0 + 3.0*math.floor(love.math.random()*64)/64
  self.work_speed = 1/2 + math.floor(love.math.random()*64)/64*(3/4)
  self.color = {0.5+love.math.random()*0.5,0.5+love.math.random()*0.5,0.5+love.math.random()*0.5}
  self.color[love.math.random(3)] = 0.0
  self.animations = {
    idle    = Anim(4,CREW_IMAGE,4,1, 24,24, 0, 0, 0),
    sleep   = Anim(4,CREW_IMAGE,4,1, 24,24, 0, 0, 0),
    --
    walk    = Anim(1,CREW_IMAGE,4,1, 24,24, 0,24, 0),
    --
    operate = Anim(1,CREW_IMAGE,4,1, 24,24, 0,48, 0),
    repair  = Anim(1,CREW_IMAGE,4,1, 24,24, 0,48, 0),
    }
  self.animations.walk:set_fps_scale(6*self.walk_speed/4)
  self.animations.operate:set_fps_scale(5*self.work_speed)
  self.animations.repair:set_fps_scale(6*self.work_speed)
  self.anim = self.animations.walk

  self.effects = {}
  
  local c1
  repeat
    c1 = love.math.random(#ship.cells)
  until ship.cells[c1].passable
  self.location = {x=ship.cells[c1].x+0.5,y=ship.cells[c1].y+0.5}
  self.facing = 0

  self.current_job = nil
  self.current_action = nil
  self.action_stack = {}
  self.job_stack = {}

  self.job_flags = {}

  self.claim_device = nil
end

function Crew:__tostring()
  return string.format("<%s@%0.01f,%0.01f|o%0.01f,h%0.01f,f%0.01f,r%0.01f,s%0.01f,w%0.01f|%s>", self.name,
    self.location.x, self.location.y,
    self.level.o2, self.level.health, self.level.food, self.level.rest, self.level.stress, self.level.waste,
    (self.current_action or '-')
    )
end

function Crew:die()
  if self.current_job then
    self.current_job:finish()
    self.current_job:unclaim()
    self.current_job = nil
  end
  if self.current_action then
    self.current_action:finish()
    self.current_action = nil
    self.job_stack = {}
  end
  if chosen_crew == self then
    chosen_crew = nil
  end
  -- TODO: rest of death handling...
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
  if self.level.health < 10 and not self.job_flags.MedJob then
    self.job_stack[#self.job_stack+1] = MedJob(5.0)
    self.job_flags.MedJob = true
  elseif self.level.health < 50 and not self.job_flags.MedJob then
    self.job_stack[#self.job_stack+1] = MedJob(1.0)
    self.job_flags.MedJob = true
  elseif self.level.food < 1  and not self.job_flags.EatJob then
    self.job_stack[#self.job_stack+1] = EatJob(5.0)
    self.job_flags.EatJob = true
  elseif self.level.food < 10  and not self.job_flags.EatJob then
    self.job_stack[#self.job_stack+1] = EatJob(1.0)
    self.job_flags.EatJob = true
  elseif self.level.waste > 10 and not self.job_flags.WasteJob then
    self.job_stack[#self.job_stack+1] = WasteJob(1.0)
    self.job_flags.WasteJob = true
  elseif self.level.rest < 10 then
    self.job_stack[#self.job_stack+1] = SleepJob(1.0)
    self.job_flags.SleepJob = true
  elseif self.level.stress > 100 then
    --self.job_stack[#self.job_stack+1] = WaitJob(1.0)
    --self.job_flags.WaitJob = true
    --TODO: wait and/or wander and/or insanity :-)
  end
end

function Crew:claim_job(j)
  if j:claim(self) then
    self.action_stack = j:actions()
    return true
  end
  return false
end

-- TODO: should look at global job queue, etc.
function Crew:new_action()
  self.current_action = nil

  if #self.action_stack>0 then
    self.current_action = self.action_stack[#self.action_stack]
    self.action_stack[#self.action_stack] = nil
    if not self.current_action:start() then
      --print("Failed to start action: waiting and retrying", self)
      self.action_stack[#self.action_stack+1] = self.current_action
      self.current_action = WaitAction(nil, self, love.math.random()+0.5)
      self.current_action:start()
    end
    return
  end

  if #self.job_stack > 0 then
    local j = self.job_stack[#self.job_stack]
    self.job_stack[#self.job_stack] = nil
    self.job_flags[j.class.name] = nil
    if not self:claim_job(j) then
      print("ERROR: failure to claim job", self, j)
      -- TODO!
    end
    return
  end

  if #the_jobs > 0 then
    local j = the_jobs[#the_jobs]
    if j:check_skills(self) then
      the_jobs[#the_jobs] = nil
      if not self:claim_job(j) then
        print("ERROR: failure to claim job", self, j)
        -- TODO!
      end
      return
    end
  end

  if love.math.random()<0.50 then
    self.current_action = WaitAction(nil, self, love.math.random()+0.5)
    self.current_action:start()
  else
    local c1
    repeat
      c1 = love.math.random(#self.ship.cells)
    until self.ship.cells[c1].passable
    self.current_action = WalkAction(nil, self, self.ship.cells[c1])
    self.current_action:start()
  end
end

function Crew:update(dt)
  -- effects
  local n = #self.effects
  for i=1,n do
    if self.effects[i].update(dt) then
      self.effects[i] = nil    
    end
  end
  compact(self.effects, n)

  -- metabolism
  -- TODO: replenish o2 if <max
  -- TODO: incorporate co2 levels somehow
  local do2 = self.ship.level.o2:sub(2*dt)
  self.level.o2 = self.level.o2 - (2*dt - do2)
  self.ship.level.co2:add(2*dt)
  self.ship.level.temp:add(dt/16)

  self.level.health = math.min(100.0, self.level.health + dt*1/64)
  self.level.food = math.min(100.0, self.level.food - dt*1/64)
  self.level.rest = math.min(100.0, self.level.rest - dt*1/64)
  self.level.waste = math.min(200.0, self.level.waste + dt*1/128)

  if love.math.random() < (1.0-self.skills.zen)*dt then
    self.level.stress = math.min(1000.0, self.level.stress + love.math.random())
  end
  
  if self.level.waste>100 then
    if love.math.random()*100 < self.level.waste-100 then
      self.level.health = math.max(0.0, self.level.health - dt)
    end
  end
  if self.level.food<10 then
    if love.math.random()*100 < (10-self.level.food) then
      self.level.health = math.max(0.0, self.level.health - dt)
    end
  end
  if self.level.o2<1 then
    self.level.health = math.max(0.0, self.level.health - dt)
  end
  -- TODO: stress

  -- activity
  if not self.current_action then
    self:new_action()
  else
    local res = self.current_action:execute(dt)
    if res ~= 'in-progress' then
      self.current_action:finish()
      self:new_action()
    end
  end

  -- animation
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



