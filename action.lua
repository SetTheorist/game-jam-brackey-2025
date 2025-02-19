
local PI = math.pi
local PI2 = math.pi/2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Job = class("Job")
function Job:initialize(name,priority,min_skills,args)
  self.name = name
  self.priority = priority
  self.min_skills = min_skills
  self.device = nil
  self.owner = nil
  self.on_failure = 'drop'
  for k,v in pairs(args) do
    self[k] = v
  end
end

function Job:actions()
  return {}
end

function Job:start()
end

function Job:finish()
end

function Job:check_skills(agent)
  for skill,value in pairs(self.min_skills) do
    if agent.skills[skill] < value then
      return false
    end
  end
  return true
end

function Job:claim(agent)
  if self.owner~=nil and self.owner~=agent then
    print("ERROR: Attempt to claim already-owned job", self, agent)
    return false
  end
  self.owner = agent
  agent.current_job = self
  return true
end

----------
WaitJob = class("WaitJob", Job)
function WaitJob:actions()
  return {WaitAction(self,self.owner,1.0)} --TODO: specify wait period
end

----------
WanderJob = class("WanderJob", Job)
function WanderJob:actions()
  local ship = self.owner.ship
  local x,y
  for i=1,100 do
    x = love.math.random(ship.x_size)
    y = love.math.random(ship.y_size)
    if ship:cell(x,y).passable then
      return {WalkAction(self,self.owner,{x=x,y=y})}
    end
  end
  print("ERROR: unable to find valid target for WanderJob after 100 tries")
  return {}
end

----------
EatJob = class("EatJob", Job)

----------
SleepJob = class("SleepJob", Job)

----------
WasteJob = class("WasteJob", Job)

----------
OperateJob = class("OperateJob", Job)
function OperateJob:initialize(priority,min_skills,device)
  if device.Operate_job~=nil then
    print("ERROR: Tried to create operate-job for device with existing operate-job", self, device)
  end
  self.class.super.initialize(self,"operate",priority,min_skills,{device=device})
  device.operate_job = self
end

function OperateJob:actions()
  return {
    FinishJobAction(self, self.owner),
    OperateAction(self, self.owner, self.device, 1.0),
    WalkAction(self, self.owner, self.device.cell),
    StartJobAction(self, self.owner) }
end

----------
RepairJob = class("RepairJob", Job)
function RepairJob:initialize(priority,min_skills,device)
  if device.repair_job~=nil then
    print("ERROR: Tried to create repair-job for device with existing repair-job", self, device)
  end
  self.class.super.initialize(self,"repair",priority,min_skills,{device=device})
  device.repair_job = self
end

function RepairJob:finish()
  self.device.repair_job = nil
end

function RepairJob:actions()
  return {
    FinishJobAction(self, self.owner),
    RepairAction(self, self.owner, self.device, 1.0),
    WalkAction(self, self.owner, self.device.cell),
    StartJobAction(self, self.owner) }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
  done
  in-progress
  failed
--]]
Action = class("Action")
function Action:initialize(job,agent)
  self.job = job
  self.agent = agent
end
function Action:start() end
function Action:finish() end
function Action:execute(dt) return 'done' end

-- book-keeping action
StartJobAction = class("StartJobAction", Action)

function StartJobAction:__tostring() return "StartJobAction" end

function StartJobAction:finish()
  if self.job then
    self.job:start()
  end
end

-- book-keeping action
FinishJobAction = class("FinishJobAction", Action)

function FinishJobAction:__tostring() return "FinishJobAction" end

function FinishJobAction:finish()
  if self.job then
    self.job:finish()
  end
end

----------
WaitAction = class("WaitAction", Action)

function WaitAction:__tostring()
  return string.format("WaitAction(%.01f/%.01f)", self.elapsed, self.time)
end

function WaitAction:initialize(job,agent,time)
  self.class.super.initialize(self,job,agent)
  self.time = time
  self.elapsed = 0
end

function WaitAction:execute(dt)
  self.elapsed = self.elapsed + dt
  if self.elapsed >= self.time then
    return 'done'
  else
    return 'in-progress'
  end
end

function WaitAction:start()
  self.agent.anim = self.agent.animations.idle
end

----------
WalkAction = class("WalkAction", Action)

function WalkAction:__tostring()
  return string.format("WalkAction(%s)",self.target_cell)
end

function WalkAction:initialize(job,agent,target_cell)
  self.class.super.initialize(self,job,agent)
  self.target_cell = target_cell
  self.path = nil
end

function WalkAction:start()
  local c0 = self.agent.ship:cell(self.agent.location.x,self.agent.location.y)
  local foundit,the_path = self.agent.ship:path(c0, self.target_cell)
  self.path = the_path
  self.agent.anim = self.agent.animations.walk
end

function WalkAction:execute(dt)
  -- TODO: check grid accessibility
  -- TODO: this is a very clunky approach
  local x,y = unpack(self.path[#self.path])
  local v_x,v_y = x+0.5-self.agent.location.x,y+0.5-self.agent.location.y
  local l = math.sqrt(v_x^2+v_y^2)
  if l < 1/64 then
    table.remove(self.path, #self.path)
  else
    local cell_cost = self.agent.ship:cell(math.floor(self.agent.location.x), math.floor(self.agent.location.y)).cost
    local dir_x,dir_y = v_x/l,v_y/l
    local t = math.min(l, self.agent.walk_speed*dt/cell_cost)
    self.agent.location.x = math.floor((self.agent.location.x + dir_x*t)*1024)/1024
    self.agent.location.y = math.floor((self.agent.location.y + dir_y*t)*1024)/1024

    if dir_x>0 then self.agent.facing = 0
    elseif dir_x<0 then self.agent.facing = PI
    elseif dir_y>0 then self.agent.facing = PI2
    elseif dir_y<0 then self.agent.facing = -PI2
    end

    if t<self.agent.walk_speed*dt/cell_cost then
      table.remove(self.path, #self.path)
    end
  end
  if #self.path==0 then
    return 'done'
  else
    return 'in-progress'
  end
end

----------
RepairAction = class("RepairAction", Action)

function RepairAction:__tostring()
  return string.format("RepairAction(%s:%.1f/%.1f)",self.device, self.elapsed, self.time)
end

function RepairAction:initialize(job,agent,device,time)
  self.class.super.initialize(self,job,agent)
  self.device = device
  self.time = time
  self.elapsed = 0
end

function RepairAction:start()
  self.agent.anim = self.agent.animations.operate
end

function RepairAction:execute(dt)
  dt = dt * self.agent.work_speed
  self.elapsed = self.elapsed + dt

  -- TODO: chance to damage...
  if self.device.health.electronic < 1.0 then
    local x = self.agent.skills.repair_electronic*love.math.random()
    self.device.health.electronic = math.max(0.0, math.min(1.0, self.device.health.electronic + x*dt))
  end
  if self.device.health.mechanical < 1.0 then
    local x = self.agent.skills.repair_mechanical*love.math.random()
    self.device.health.mechanical = math.max(0.0, math.min(1.0, self.device.health.mechanical + x*dt))
  end
  if self.device.health.quantum < 1.0 then
    local x = self.agent.skills.repair_quantum*love.math.random()
    self.device.health.quantum = math.max(0.0, math.min(1.0, self.device.health.quantum + x*dt))
  end

  if self.elapsed >= self.time then
    return 'done'
  else
    return 'in-progress'
  end
end

----------
OperateAction = class("OperateAction", Action)

function OperateAction:initialize(job,agent,device,time)
  self.class.super.initialize(self,job,agent)
  self.device = device
  self.elapsed = 0
  self.device.start_operate(self.agent)
end

function OperateAction:execute(dt)
  self.elapsed = self.elapsed + dt
  if self.device.operate(self.agent, dt)=='done' then
    self.device.stop_operate(self.agent)
    return 'done'
  else
    return 'in-progress'
  end
end

----------------------------------------



