
----------------------------------------
Device = class("Device")

function Device:initialize(name,char,ship,cell,inputs,outputs,decay,args)
  self.ship = ship
  self.name = name
  self.char = char
  self.efficiency = 1.0
  self.inputs = inputs or {}
  self.outputs = outputs or {}
  self.cell = cell
  self.facing = 0
  self.enabled = true
  self.health = {electronic = 1.0, mechanical = 1.0, quantum = 1.0}
  self.total_health = 1.0
  self.decay = {
    electronic = (decay and decay[1] or 4)/1024,
    mechanical = (decay and decay[2] or 8)/1024,
    quantum = (decay and decay[3] or 1)/1024
    }
  self.manned = false
  self.activated = false
  self.activation_time = 5.0 --default
  self.activation_elapsed = 0.0
  self.owner = nil
  self.repair_job = nil
  self.operate_job = nil
  self.animations = {
    electronic = {
      ELECTRONIC_ANIM[1]:clone({x=12,y=12}),
      ELECTRONIC_ANIM[2]:clone({x=12,y=12}),
      ELECTRONIC_ANIM[3]:clone({x=12,y=12}),
    },
  }
  -- tile, electronic, mechanical, quantum
  self.active_animations = {nil,nil,nil,nil}
  self.tile = nil
  if args then for k,v in pairs(args) do self[k] = v end end
end

function Device:draw()
  if not self.cell then print("Attempt to draw device with nil cell", self); return end
  love.graphics.setColor(1,1,1,1)
  if self.tile then
    love.graphics.draw(self.tile)
  else
    love.graphics.print(self.char, FONT_1, 0,0)
  end
  for i=1,4 do
    if self.active_animations[i] then
      self.active_animations[i]:draw()
    end
  end
end

function Device:unclaim()
  self.owner = nil
end

function Device:claim(agent)
  if self.owner and self.owner~=agent then
    return false
  end
  self.owner = agent
  return true
end

function Device:start_operate(agent)
  if self.owner~=agent then
    print("ERROR: Device:start_operate() but self.owner~=agent",self,agent)
  end
  self.activation_elapsed = 0.0
end
function Device:operate(agent,dt)
  if self.owner~=agent then
    print("ERROR: Device:operate() but self.owner~=agent",self,agent)
  end
  -- TODO: skill
  self.activation_elapsed = self.activation_elapsed + dt
  if self.activation_elapsed >= self.activation_time then
    self:on_completion(agent)
    self:stop_operate(agent)
    return 'done'
  else
    return 'in-progress'
  end
end
function Device:stop_operate(agent)
  if self.owner~=agent then
    print("ERROR: Device:stop_operate() but self.owner~=agent",self,agent)
  end
  self.activation_elapsed = 0.0
end
function Device:on_completion(agent)
end

function Device:__tostring()
  return string.format("[%s]%s(%.01f|%.01f,%.01f,%.01f)", self.char, self.name, self.efficiency,
    self.health.electronic, self.health.mechanical, self.health.quantum)
end

function Device:slow_update(dt)
  local scale = 1.0
  -- TODO: greater decay for manned/activated devices when being used, less when idle
  --if self.manned or self.activated then scale = 1/8 end
  self.health.electronic = math.max(0, self.health.electronic - dt*self.decay.electronic*scale)
  self.health.mechanical = math.max(0, self.health.mechanical - dt*self.decay.mechanical*scale)
  self.health.quantum = math.max(0, self.health.quantum - dt*self.decay.quantum*scale)
  self.total_health = math.min(self.health.electronic,self.health.mechanical,self.health.quantum)
  if self.total_health <= 0.0 then
    self.enabled = false
    self.total_health = 0.0
    self.efficiency = 0.0
  else
    self.efficiency = math.min(1.0,math.ceil(self.total_health*16)/16)
  end

  if self.active_animations[1] then
    self.active_animations[1]:set_fps_scale(self.efficiency)
  end

  if self.health.electronic < 0.25 then
    self.active_animations[2] = self.animations.electronic[3]
  elseif self.health.electronic < 0.50 then
    self.active_animations[2] = self.animations.electronic[2]
  elseif self.health.electronic < 0.75 then
    self.active_animations[2] = self.animations.electronic[1]
  else
    self.active_animations[2] = nil
  end
end

function Device:update(dt)
  for i=1,4 do
    if self.active_animations[i] then
      self.active_animations[i]:update(dt)
    end
  end
  if self.manned or self.activated then return end
  if not self.enabled then return end
  local t = 1.0
  for l,c in pairs(self.inputs) do
    t = math.min(t, self.ship.level[l].value/(c*dt))
  end
  for l,c in pairs(self.inputs) do
    self.ship.level[l]:add(-t*c*dt)
  end
  for l,c in pairs(self.outputs) do
    self.ship.level[l]:add(self.efficiency*t*c*dt)
  end
end

----------
ReactorCore = class("ReactorCore", Device)
function ReactorCore:initialize(ship,cell)
  self.class.super.initialize(self,"Reactor Core",'R',ship,cell,{},{energy=1000,radiation=1/8},{1,4,8})
  self.animations.tile = REACTOR_ANIM:clone({x=12,y=12})
  self.active_animations[1] = self.animations.tile
  self.health.electronic = 0.25
  self.health.mechanical = 0.75
  self.health.quantum = 0.75
end
----------
O2Reprocessor = class("O2Reprocessor", Device)
function O2Reprocessor:initialize(ship,cell)
  self.class.super.initialize(self,"O2 Reprocessor",'O',ship,cell,{energy=10},{o2=32},{4,8,1})
end
----------
ShieldSystem = class("ShieldSystem", Device)
function ShieldSystem:initialize(ship,cell)
  self.class.super.initialize(self,"Shield System",'s',ship,cell,{energy=100},{},{2,4,4})
end
----------
ThermalRegulator = class("ThermalRegulator", Device)
function ThermalRegulator:initialize(ship,cell)
  self.class.super.initialize(self,"Thermal Regulator",'T',ship,cell,{energy=10},{temp=2}, {4,8,1})
  self.mode = 'heat'
end
function ThermalRegulator:slow_update(dt)
  Device.slow_update(self, dt)
  -- TODO: clean this up
  if self.mode=='heat' then
    if self.ship.level.temp.value>90 then
      self.mode = 'cool'
      self.outputs.temp = -5
      self.inputs.energy = 25
    elseif self.ship.level.temp.value>80 then
      self.outputs.temp = 2
      self.inputs.energy = 10
    end
  elseif self.mode=='cool' then
    if self.ship.level.temp.value<70 then
      self.mode = 'heat'
      self.outputs.temp = 5
      self.inputs.energy = 25
    elseif self.ship.level.temp.value<80 then
      self.outputs.temp = -2
      self.inputs.energy = 10
    end
  end
end
----------
Co2Scrubber = class("Co2Scrubber", Device)
function Co2Scrubber:initialize(ship,cell)
  self.class.super.initialize(self,"Co2 Scrubber",'S',ship,cell,{energy=10,co2=50},{o2=25}, {4,8,1})
end
----------
FoodSynthesizer = class("FoodSynthesizer", Device)
function FoodSynthesizer:initialize(ship,cell)
  self.class.super.initialize(self,"Food Synthesizer",'F',ship,cell,{energy=10,slurry=1},{food=1}, {4,8,1})
end
----------
Toilet = class("Toilet", Device)
function Toilet:initialize(ship,cell)
  self.class.super.initialize(self,"Toilet",'t',ship,cell,{energy=1},{}, {2,16,1},{activated=true})
end
function Toilet:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  local t = math.min(dt,agent.level.waste)
  agent.level.waste = agent.level.waste - t
  self.ship.level.waste:add(t)
  return res
end
----------
Bed = class("Bed", Device)
function Bed:initialize(ship,cell)
  self.class.super.initialize(self,"Bed",'b',ship,cell,{energy=1},{}, {1/8,1,1/256},{activated=true,activation_time=10.0})
  self.tile = BED_IMAGE
end
function Bed:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  agent.level.rest = math.min(100, agent.level.rest + dt)
  return res
end
----------
Door = class("Door", Device)
function Door:initialize(ship,cell)
  self.class.super.initialize(self,"Door",'+',ship,cell,{energy=1},{}, {1/256,1/512,1/1024})
end
----------
Table = class("Table", Device)
function Table:initialize(ship,cell)
  self.class.super.initialize(self,"Table",'z',ship,cell,{energy=1},{}, {1/512,1/256,1/1024},{activated=true})
end
function Table:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  local t = math.min(dt,agent.inventory.food)
  agent.inventory.food = agent.inventory.food - t
  agent.level.food = agent.level.food + t
  return res
end
----------
NutrientDispenser = class("NutrientDispenser", Device)
function NutrientDispenser:initialize(ship,cell)
  self.class.super.initialize(self,"Nutrient Dispenser",'f',ship,cell,{energy=10},{}, {4,8,1},{activated=true})
end
function NutrientDispenser:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  local t = math.min(dt,self.ship.level.food.value)
  agent.inventory.food = agent.inventory.food + t
  self.ship.level.food:sub(t)
  return res
end
----------
MedicalBay = class("MedicalBay", Device)
function MedicalBay:initialize(ship,cell)
  self.class.super.initialize(self,"Medical Bay",'M',ship,cell,{energy=100},{}, {4,8,1},{activated=true})
  self.health.electronic = 0.5
  self.health.mechanical = 0.5
  self.health.quantum = 0.5
end
----------
WasteReclamation = class("WasteReclamation", Device)
function WasteReclamation:initialize(ship,cell)
  self.class.super.initialize(self,"Waste Reclamation",'W',ship,cell,{energy=1,waste=1},{slurry=1/2}, {4,8,1})
end
----------
WeaponSystem = class("WeaponSystem", Device)
function WeaponSystem:initialize(ship,cell)
  self.class.super.initialize(self,"Weapon System",'w',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
SensorSystem = class("SensorSystem", Device)
function SensorSystem:initialize(ship,cell)
  self.class.super.initialize(self,"Sensor System",'e',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
NavigationSystem = class("NavigationSystem", Device)
function NavigationSystem:initialize(ship,cell)
  self.class.super.initialize(self,"Navigation System",'n',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
PropulsionSystem = class("PropulsionSystem", Device)
function PropulsionSystem:initialize(ship,cell)
  self.class.super.initialize(self,"Propulsion System",'p',ship,cell,{energy=10},{}, {2,4,4})
end
----------
CommunicationSystem = class("CommunicationSystem", Device)
function CommunicationSystem:initialize(ship,cell)
  self.class.super.initialize(self,"Communication System",'c',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
FTLJumpSystem = class("FTLJumpSystem", Device)
function FTLJumpSystem:initialize(ship,cell)
  self.class.super.initialize(self,"FTL Jump Drive",'j',ship,cell,{energy=10},{}, {2,4,8},{manned=true})
end


DEVICES = {
  b=Bed,
  c=CommunicationSystem,
  e=SensorSystem,
  F=FoodSynthesizer,
  f=NutrientDispenser,
  j=FTLJumpSystem,
  M=MedicalBay,
  n=NavigationSystem,
  O=O2Reprocessor,
  p=PropulsionSystem,
  R=ReactorCore,
  S=Co2Scrubber,
  s=ShieldSystem,
  T=ThermalRegulator,
  t=Toilet,
  W=WasteReclamation,
  w=WeaponSystem,
  z=Table,
}


