local class = class or require "middleclass"

----------------------------------------
Device = class("Device")

function Device:initialize(name,description,char,priority,ship,cell,variant,inputs,outputs,decay,args)
  self.ship = ship
  --self.name = (variant and (name..'-'..tostring(variant))) or name
  self.name = name
  self.description = description
  self.char = char
  self.priority = priority
  self.efficiency = 1.0
  self.integrity = 1.0
  self.inputs = inputs or {}
  self.outputs = outputs or {}
  self.cell = cell
  self.variant = variant
  self.mode = nil
  self.facing = 0
  self.enabled = true
  self.health = { 
    electronic = 1.0-love.math.random(64)/64/4 - (DIFFICULTY_LEVEL-1)/8,
    mechanical = 1.0-love.math.random(64)/64/4 - (DIFFICULTY_LEVEL-1)/8,
    quantum = 1.0-love.math.random(64)/64/4 - (DIFFICULTY_LEVEL-1)/8}
  self.total_health = math.min(self.health.electronic,self.health.mechanical,self.health.quantum)
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
    damage_electronic = {
      ANIMATIONS.damage_electronic[1]:clone({x=12,y=12}),
      ANIMATIONS.damage_electronic[2]:clone({x=12,y=12}),
      ANIMATIONS.damage_electronic[3]:clone({x=12,y=12}),
    },
    damage_mechanical = {
      ANIMATIONS.damage_mechanical[1]:clone({x=12,y=12}),
      ANIMATIONS.damage_mechanical[2]:clone({x=12,y=12}),
      ANIMATIONS.damage_mechanical[3]:clone({x=12,y=12}),
    },
    damage_quantum = {
      ANIMATIONS.damage_quantum[1]:clone({x=12,y=12}),
      ANIMATIONS.damage_quantum[2]:clone({x=12,y=12}),
      ANIMATIONS.damage_quantum[3]:clone({x=12,y=12}),
    },
  }
  for _,an in pairs(self.animations) do
    for _,a in ipairs(an) do
      a:set_fps_scale(1 + (love.math.random(65)-32)/128)
    end
  end
    
  -- tile, electronic, mechanical, quantum
  self.active_animations = {nil,nil,nil,nil}
  self.tile = nil
  if args then for k,v in pairs(args) do self[k] = v end end
end

function Device:draw()
  if not self.cell then print("Attempt to draw device with nil cell", self); return end
  if self.tile then
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.tile)
  end
  for i=1,4 do
    if self.active_animations[i] then
      if i==1 then
        love.graphics.setColor(1,1,1,1)
      else
        love.graphics.setColor(1,1,1,0.5)
      end
      self.active_animations[i]:draw()
    end
  end
  love.graphics.setColor(1,1,1,1)
  if self.repair_job then love.graphics.draw(TILES.icon_hammer) end
  if self.operate_job then love.graphics.draw(TILES.icon_hand) end
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
  self:process_inout(dt)
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

function Device:process_inout(dt)
  local t = 1.0
  for l,c in pairs(self.inputs) do
    t = math.min(t, self.ship.level[l].value/math.abs(c*dt))
  end
  for l,c in pairs(self.inputs) do
    self.ship.level[l]:add(-t*c*dt)
  end
  for l,c in pairs(self.outputs) do
    self.ship.level[l]:add(self.efficiency*t*c*dt)
  end
end

function Device:__tostring()
  return string.format("[%s]%s(%.01f|%.01f,%.01f,%.01f)", self.char, self.name, self.efficiency,
    self.health.electronic, self.health.mechanical, self.health.quantum)
end

function Device:slow_update(dt)
  local was_ok = (self.total_health > 0)
  local scale = 1.0 * GLOBAL_DECAY_FACTOR
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
    if was_ok then
      self.integrity = self.integrity - love.math.random(64)/64/32
      EVENT_MANAGER:emit('score:sub', dt, 'broken['..self.name..']')
      EVENT_MANAGER:emit('message', string.format("Breakdown of %s (%i,%i)", self.name, self.cell.x, self.cell.y), {1,0.7,0.5})
      AUDIO.breaking:stop()
      AUDIO.breaking:play()
    end
  else
    self.enabled = true
    self.efficiency = self.integrity*math.min(1.0,math.ceil(self.total_health*16)/16)
  end

  if self.active_animations[1] then
    self.active_animations[1]:set_fps_scale(self.efficiency)
  end

  self.active_animations[2] = self.animations.damage_electronic[3-math.floor(self.health.electronic*4)]
  self.active_animations[3] = self.animations.damage_mechanical[3-math.floor(self.health.mechanical*4)]
  self.active_animations[4] = self.animations.damage_quantum[3-math.floor(self.health.quantum*4)]
end

function Device:update(dt)
  for i=1,4 do
    if self.active_animations[i] then
      self.active_animations[i]:update(dt)
    end
  end
  if not self.enabled then return end
  if self.manned or self.activated then return end
  self:process_inout(dt)
end

----------
ReactorCore = class("ReactorCore", Device)
function ReactorCore:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Reactor Core","Generates energy",'R',0,ship,cell,variant,{},{energy=250,radiation=1/8},{1,4,8})
  self.active_animations[1] = ANIMATIONS.reactor[variant]:clone({x=12,y=12})
end
----------
O2Reprocessor = class("O2Reprocessor", Device)
function O2Reprocessor:initialize(ship,cell,variant)
  self.class.super.initialize(self,"O2 Reprocessor","Generates O2",'O',1,ship,cell,variant,{energy=10},{o2=20},{4,8,1})
  self.active_animations[1] = ANIMATIONS.o2_reprocessor[variant]:clone({x=12,y=12})
end
----------
ThermalRegulator = class("ThermalRegulator", Device)
function ThermalRegulator:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Thermal Regulator","Regulates temperature",'T',2,ship,cell,variant,
      {energy=0},{temperature=0}, {4,8,1}, {mode=''})
  self.active_animations[1] = ANIMATIONS.thermal_regulator[variant]:clone({x=12,y=12})
  if ship.level.temperature.value >= 80 then
    self.mode = 'cool'
    self.outputs.temperature = -25
    self.inputs.energy = 50
  else
    self.mode = 'heat'
    self.outputs.temperature = 25
    self.inputs.energy = 50
  end
end
function ThermalRegulator:slow_update(dt)
  Device.slow_update(self, dt)
  self.outputs.temperature = math.max(-100,math.min(100,(80 - self.ship.level.temperature.value)))*(1+dt)/self.efficiency
  self.inputs.energy = self.outputs.temperature*2
  if self.outputs.temperature>0 then
    self.mode = 'heat'
  else
    self.mode = 'cool'
  end
end
----------
Co2Scrubber = class("Co2Scrubber", Device)
function Co2Scrubber:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Co2 Scrubber","Cleans CO2 from air",'C',4,ship,cell,variant,{energy=10},{co2=-5,o2=2}, {4,8,1})
  self.active_animations[1] = ANIMATIONS.co2_scrubber[variant]:clone({x=12,y=12})
end
----------
FoodSynthesizer = class("FoodSynthesizer", Device)
function FoodSynthesizer:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Food Synthesizer","Converts slurry to food",'F',10,ship,cell,variant,{energy=10,slurry=10},{food=10}, {4,8,1})
  self.active_animations[1] = ANIMATIONS.food_synthesizer[variant]:clone({x=12,y=12})
end
----------
Toilet = class("Toilet", Device)
function Toilet:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Toilet","Crew uses for waste",'t',17,ship,cell,variant,{energy=1},{}, {2,16,1},{activated=true})
  self.tile = TILES.toilet
end
function Toilet:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  local t = math.min(2*dt,agent.level.waste)
  agent.level.waste = agent.level.waste - t
  --agent.level.stress = math.max(0, agent.level.stress - t/2*agent.skills.zen)
  agent.level.stress = math.max(0, agent.level.stress - t/2*self.efficiency)
  self.ship.level.waste:add(t)
  if agent.level.waste<=0 then res='done' end
  return res
end
----------
Bed = class("Bed", Device)
function Bed:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Bed","Crew uses for rest",'b',18,ship,cell,variant,{energy=1},{}, {1/8,1,1/256},
    {activated=true,activation_time=10.0})
  self.tile = TILES.bed
end
function Bed:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  agent.level.rest = math.min(128, agent.level.rest + 4*dt*(0.5 + self.efficiency/2)) -- bed gives _some_ rest even if broken
  if agent.level.rest>=128 then res='done' end
  return res
end
----------
NutrientDispenser = class("NutrientDispenser", Device)
function NutrientDispenser:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Nutrient Dispenser","Crew uses for food",'n',11,ship,cell,variant,{energy=10},{}, {4,8,1},{activated=true})
  self.active_animations[1] = ANIMATIONS.nutrient_dispenser[variant]:clone({x=12,y=12})
end
function NutrientDispenser:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  local t = math.min(20*dt,self.ship.level.food.value)*self.efficiency
  self.ship.level.food:sub(t)
  agent.level.food = math.min(256, agent.level.food + t)
  --agent.level.stress = math.max(0, agent.level.stress - t*agent.skills.zen)
  agent.level.stress = math.max(0, agent.level.stress - t)
  if agent.level.food==256 then res='done' end
  return res
end
----------
MedicalBay = class("MedicalBay", Device)
function MedicalBay:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Medical Bay","Crew uses for health",'m',3,ship,cell,variant,{energy=100},{}, {4,8,1},{activated=true})
  self.active_animations[1] = ANIMATIONS.medical_bay[variant]:clone({x=12,y=12})
  self.health.electronic = 0.5
  self.health.mechanical = 0.5
  self.health.quantum = 0.5
end
function MedicalBay:operate(agent,dt)
  local res = self.class.super.operate(self,agent,dt)
  local t = math.min(5*dt,100-agent.level.health)
  agent.level.health = math.min(100, agent.level.health + t*self.efficiency)
  if agent.level.health>=100 then res='done' end
  return res
end
----------
WasteReclamation = class("WasteReclamation", Device)
function WasteReclamation:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Waste Reclamation","Converts waste to slurry",'L',9,ship,cell,variant,{energy=1,waste=5},{slurry=2}, {4,8,1})
  self.active_animations[1] = ANIMATIONS.waste_reclamation[variant]:clone({x=12,y=12})
end
----------
ShieldSystem = class("ShieldSystem", Device)
function ShieldSystem:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Shield System","Generates shield-power from defence-command",'S',5,ship,cell,variant,
      {energy=100,defence_command=1},{shield_power=1},{2,4,4},{manned=true})
  self.active_animations[1] = ANIMATIONS.shield_system[variant]:clone({x=12,y=12})
end
----------
WeaponsSystem = class("WeaponsSystem", Device)
function WeaponsSystem:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Weapons System","Generates weapons-power from defence-command",'W',7,ship,cell,variant,
      {energy=100,defence_command=1},{weapons_power=1}, {2,4,4},{manned=true})
  self.active_animations[1] = ANIMATIONS.weapons_system[variant]:clone({x=12,y=12})
end
----------
SensorSystem = class("SensorSystem", Device)
function SensorSystem:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Sensor System","Generates sensor-data",'E',6,ship,cell,variant,
    {energy=100},{sensor_data=5}, {2,4,4},{manned=true})
  self.active_animations[1] = ANIMATIONS.sensor_system[variant]:clone({x=12,y=12})
end
----------
NavigationSystem = class("NavigationSystem", Device)
function NavigationSystem:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Navigation System","Generates navigation-data from sensor-data",'N',12,ship,cell,variant,
      {energy=100,sensor_data=1},{navigation_data=5}, {2,4,4},{manned=true})
  self.active_animations[1] = ANIMATIONS.navigation_system[variant]:clone({x=12,y=12})
end
----------
PropulsionSystem = class("PropulsionSystem", Device)
function PropulsionSystem:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Propulsion System","Generates propulsion power from flight-command",'P',13,ship,cell,variant,
    {energy=100,flight_command=1},{propulsion_power=1}, {2,4,4})
  self.active_animations[1] = ANIMATIONS.propulsion_system[variant]:clone({x=12,y=12})
end
----------
FTLDrive = class("FTLDrive", Device)
function FTLDrive:initialize(ship,cell,variant)
  self.class.super.initialize(self,"FTL Drive","Generates progress-power from propulsion-power and ftl-command",'J',15,ship,cell,variant,
      {energy=10,propulsion_power=1,ftl_command=1},{progress_power=1}, {2,4,8},{operated=true})
  self.active_animations[1] = ANIMATIONS.ftl_drive[variant]:clone({x=12,y=12})
end
----------
FlightConsole = class("FlightConsole", Device)
function FlightConsole:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Flight Console","Generates flight-command from sensor-data",'B',14,ship,cell,variant,
      {energy=5,sensor_data=1},{flight_command=10}, {2,4,8},{manned=true})
  self.active_animations[1] = ANIMATIONS.flight_console:clone({x=12,y=12})
end
----------
DefenceConsole = class("DefenceConsole", Device)
function DefenceConsole:initialize(ship,cell,variant)
  self.class.super.initialize(self,"Defence Console","Generates defence-command",'D',8,ship,cell,variant,
      {energy=5},{defence_command=10}, {2,4,8},{manned=true})
  self.active_animations[1] = ANIMATIONS.defence_console:clone({x=12,y=12})
end
----------
FTLConsole = class("FTLConsole", Device)
function FTLConsole:initialize(ship,cell,variant)
  self.class.super.initialize(self,"FTL Console","Generates ftl-command from navigation-data",'Z',16,ship,cell,variant,
      {energy=5,navigation_data=1},{ftl_command=10}, {2,4,8},{manned=true})
  self.active_animations[1] = ANIMATIONS.ftl_console:clone({x=12,y=12})
end

