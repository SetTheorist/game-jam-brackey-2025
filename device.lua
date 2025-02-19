
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
  self.activation_time = 2.0 --default
  self.activation_elapsed = 0.0
  self.claim = nil
  self.repair_job = nil
  self.operate_job = nil
  if args then for k,v in pairs(args) do self[k] = v end end
end

function Device:start_operate(agent)
  if self.claim~=agent then
    print("ERROR: Device:start_operate() but self.claim~=agent",self,agent)
    return
  end
  self.activation_elapsed = 0.0
end
function Device:operate(agent,dt)
  if self.claim~=agent then
    print("ERROR: Device:operate() but self.claim~=agent",self,agent)
    return
  end
  -- TODO: skill
  self.activation_elapsed = self.activation_elapsed + dt
  if self.activation_elapsed >= self.activation_time then
    self:on_success(agent)
    return 'done'
  else
    return 'in-progress'
  end
end
function Device:stop_operate(agent)
  if self.claim~=agent then
    print("ERROR: Device:stop_operate() but self.claim~=agent",self,agent)
    return
  end
  self.activation_elapsed = 0.0
end
function Device:on_success(agent)
end
function Device:on_abort(agent)
end
function Device:on_failure(agent)
end

function Device:__tostring()
  return string.format("[%s]%s(%.01f|%.01f,%.01f,%.01f)", self.char, self.name, self.efficiency,
    self.health.electronic, self.health.mechanical, self.health.quantum)
end

function Device:slow_update(dt)
  local scale = 1.0
  -- TODO: greater decay for manned/activated devices when being used
  if self.manned or self.activated then scale = 1/8 end
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
end

function Device:update(dt)
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
  self.class.super.initialize(self,"ReactorCore",'R',ship,cell,{},{energy=1000,radiation=1/8},{1,4,8})
end
----------
O2Reprocessor = class("O2Reprocessor", Device)
function O2Reprocessor:initialize(ship,cell)
  self.class.super.initialize(self,"O2Reprocessor",'O',ship,cell,{energy=10},{o2=32},{4,8,1})
end
----------
ShieldSystem = class("ShieldSystem", Device)
function ShieldSystem:initialize(ship,cell)
  self.class.super.initialize(self,"ShieldSystem",'s',ship,cell,{energy=100},{},{2,4,4})
end
----------
ThermalRegulator = class("ThermalRegulator", Device)
function ThermalRegulator:initialize(ship,cell)
  self.class.super.initialize(self,"ThermalRegulator",'T',ship,cell,{energy=10},{temp=2}, {4,8,1})
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
  self.class.super.initialize(self,"Co2Scrubber",'S',ship,cell,{energy=10,co2=20},{o2=10}, {4,8,1})
end
----------
FoodSynthesizer = class("FoodSynthesizer", Device)
function FoodSynthesizer:initialize(ship,cell)
  self.class.super.initialize(self,"FoodSynthesizer",'F',ship,cell,{slurry=1},{food=1}, {4,8,1})
end
----------
Toilet = class("Toilet", Device)
function Toilet:initialize(ship,cell)
  self.class.super.initialize(self,"Toilet",'t',ship,cell,{},{}, {2,16,1},{activated=true})
end
----------
Bed = class("Bed", Device)
function Bed:initialize(ship,cell)
  self.class.super.initialize(self,"Bed",'b',ship,cell,{},{}, {1/8,1,1/256},{activated=true})
end
----------
NutrientDispenser = class("NutrientDispenser", Device)
function NutrientDispenser:initialize(ship,cell)
  self.class.super.initialize(self,"NutrientDispenser",'f',ship,cell,{},{}, {4,8,1},{activated=true})
end
function NutrientDispenser:on_success(agent)
  local f = self.ship.level.food.sub(1)
  agent.inventory.food = agent.inventory.food + f
end
----------
MedicalBay = class("MedicalBay", Device)
function MedicalBay:initialize(ship,cell)
  self.class.super.initialize(self,"MedicalBay",'M',ship,cell,{},{}, {4,8,1},{activated=true})
  self.health.electronic = 0.5
  self.health.mechanical = 0.5
  self.health.quantum = 0.5
end
----------
WasteReclamation = class("WasteReclamation", Device)
function WasteReclamation:initialize(ship,cell)
  self.class.super.initialize(self,"WasteReclamation",'W',ship,cell,{waste=1},{slurry=1/2}, {4,8,1})
end
----------
WeaponSystem = class("WeaponSystem", Device)
function WeaponSystem:initialize(ship,cell)
  self.class.super.initialize(self,"WeaponSystem",'w',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
SensorSystem = class("SensorSystem", Device)
function SensorSystem:initialize(ship,cell)
  self.class.super.initialize(self,"SensorSystem",'e',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
NavigationSystem = class("NavigationSystem", Device)
function NavigationSystem:initialize(ship,cell)
  self.class.super.initialize(self,"NavigationSystem",'n',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
PropulsionSystem = class("PropulsionSystem", Device)
function PropulsionSystem:initialize(ship,cell)
  self.class.super.initialize(self,"PropulsionSystem",'p',ship,cell,{energy=10},{}, {2,4,4})
end
----------
CommunicationSystem = class("CommunicationSystem", Device)
function CommunicationSystem:initialize(ship,cell)
  self.class.super.initialize(self,"CommunicationSystem",'c',ship,cell,{energy=10},{}, {2,4,4},{manned=true})
end
----------
FTLJumpSystem = class("FTLJumpSystem", Device)
function FTLJumpSystem:initialize(ship,cell)
  self.class.super.initialize(self,"FTLJumpSystem",'j',ship,cell,{energy=10},{}, {2,4,8},{manned=true})
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
}


