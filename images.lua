
IMAGES = {}
ANIMATIONS = {}
TILES = {}

----------------------------------------
local function make_background(w,h,z)
  local XD = {10/255,10/255,20/255}
  local XA = {255/255/4,228/255/4,225/255/4}
  local XE = {109/255,155/255,195/255} -- cerulean_frost = Color::rgb(0x6D,0x9B,0xC3)
  local XB = {10/255,17/255,149/255} -- cadmium_blue = Color::rgb(0x0A,0x11,0x95)
  local XC = {150/255,1/255,69/255} -- rose_garnet = Color::rgb(0x96,0x01,0x45)
  local XF = {255/255,228/255,225/255} -- misty_rose = Color::rgb(0xFF,0xE4,0xE1)
  local nx,ny = w/z,h/z
  local function box(x,y)
    local t = math.sqrt(x^2+y^2)/math.sqrt(nx^2+ny^2)
    love.graphics.setColor((XA[1]*t+XD[1]*(1-t)), (XA[2]*t+XD[2]*(1-t)), (XA[3]*t+XD[3]*(1-t)))
    love.graphics.rectangle('fill',x*z,y*z,z,z)
  end
  local old_canvas = love.graphics.getCanvas()
  local canvas = love.graphics.newCanvas(w,h)
  love.graphics.setCanvas(canvas)
  for x=0,nx do
    for y=0,ny do
      box(x,y)
    end
  end
  love.graphics.setCanvas(old_canvas)
  return canvas
end

----------------------------------------
function load_images()
  IMAGES = {}
  ANIMATIONS = {}
  TILES = {}

  IMAGES.icon = love.graphics.newImage('art/icon.png')
  IMAGES.ship_frame = love.graphics.newImage('art/ship-frame.png')

  IMAGES.button_operate = {
    up=love.graphics.newImage('art/button_operate-up.png'),
    down=love.graphics.newImage('art/button_operate-down.png')}
  IMAGES.button_repair = {
    up=love.graphics.newImage('art/button_repair-up.png'),
    down=love.graphics.newImage('art/button_repair-down.png')}

  IMAGES.crew = love.graphics.newImage('art/crew.png')
  ANIMATIONS.crew = {
    idle    = Anim(4,IMAGES.crew,4,1, 24,24, 0, 0, 0),
    sleep   = Anim(4,IMAGES.crew,4,1, 24,24, 0, 0, 0),
    walk    = Anim(1,IMAGES.crew,4,1, 24,24, 0,24, 0),
    operate = Anim(1,IMAGES.crew,4,1, 24,24, 0,48, 0),
    repair  = Anim(1,IMAGES.crew,4,1, 24,24, 0,48, 0),
  }

  IMAGES.decoration_1 = love.graphics.newImage('art/decoration_1-tile.png')
  TILES.decoration_1 = IMAGES.decoration_1
  IMAGES.decoration_2 = love.graphics.newImage('art/decoration_2-tile.png')
  TILES.decoration_2 = IMAGES.decoration_2
  IMAGES.decoration_3 = love.graphics.newImage('art/decoration_3-tile.png')
  TILES.decoration_3 = IMAGES.decoration_3

  IMAGES.bed = love.graphics.newImage('art/bed-tile.png')
  TILES.bed = IMAGES.bed
  IMAGES.toilet = love.graphics.newImage('art/toilet-tile.png')
  TILES.toilet = IMAGES.toilet
  IMAGES.corpse = love.graphics.newImage('art/corpse-tile.png')
  TILES.corpse = IMAGES.corpse

  IMAGES.planet_asteroids = love.graphics.newImage('art/planet_asteroids-tile.png')
  TILES.planet_asteroids = IMAGES.planet_asteroids
  IMAGES.planet_earth = love.graphics.newImage('art/planet_earth-tile.png')
  TILES.planet_earth = IMAGES.planet_earth
  IMAGES.planet_dagon = love.graphics.newImage('art/planet_dagon-tile.png')
  TILES.planet_dagon = IMAGES.planet_dagon

  IMAGES.damage_electronic = love.graphics.newImage('art/damage_electronic-anim-5.png')
  ANIMATIONS.damage_electronic = {
    Anim(3.6,IMAGES.damage_electronic,5,1,24,24,0,0,0),
    Anim(4.1,IMAGES.damage_electronic,5,1,24,24,0,24,0),
    Anim(4.6,IMAGES.damage_electronic,5,1,24,24,0,48,0)}
  IMAGES.damage_mechanical = love.graphics.newImage('art/damage_mechanical-anim-5.png')
  ANIMATIONS.damage_mechanical = {
    Anim(3.6,IMAGES.damage_mechanical,5,1,24,24,0,0,0),
    Anim(4.0,IMAGES.damage_mechanical,5,1,24,24,0,24,0),
    Anim(4.4,IMAGES.damage_mechanical,5,1,24,24,0,48,0)}
  IMAGES.damage_quantum = love.graphics.newImage('art/damage_quantum-anim-5.png')
  ANIMATIONS.damage_quantum = {
    Anim(3.5,IMAGES.damage_quantum,5,1,24,24,0,0,0),
    Anim(4.0,IMAGES.damage_quantum,5,1,24,24,0,24,0),
    Anim(4.5,IMAGES.damage_quantum,5,1,24,24,0,48,0)}

  IMAGES.co2_scrubber = love.graphics.newImage('art/co2_scrubber-anim_2-4.png')
  ANIMATIONS.co2_scrubber = {
    Anim(3,IMAGES.co2_scrubber,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.co2_scrubber,1,4,24,24,24,0,0)}
  IMAGES.food_synthesizer = love.graphics.newImage('art/food_synthesizer-anim_2-4.png')
  ANIMATIONS.food_synthesizer = {
    Anim(3,IMAGES.food_synthesizer,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.food_synthesizer,1,4,24,24,24,0,0)}
  IMAGES.o2_reprocessor = love.graphics.newImage('art/o2_reprocessor-anim_2-4.png')
  ANIMATIONS.o2_reprocessor = {
    Anim(3,IMAGES.o2_reprocessor,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.o2_reprocessor,1,4,24,24,24,0,0)}
  IMAGES.thermal_regulator = love.graphics.newImage('art/thermal_regulator-anim_2-4.png')
  ANIMATIONS.thermal_regulator = {
    Anim(3,IMAGES.thermal_regulator,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.thermal_regulator,1,4,24,24,24,0,0)}
  IMAGES.waste_reclamation = love.graphics.newImage('art/waste_reclamation-anim_2-4.png')
  ANIMATIONS.waste_reclamation = {
    Anim(3,IMAGES.waste_reclamation,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.waste_reclamation,1,4,24,24,24,0,0)}

  IMAGES.medical_bay = love.graphics.newImage('art/medical_bay-anim_3-4.png')
  ANIMATIONS.medical_bay = {
    Anim(4,IMAGES.medical_bay,1,4,24,24, 0,0,0),
    Anim(4,IMAGES.medical_bay,1,4,24,24,24,0,0),
    Anim(4,IMAGES.medical_bay,1,4,24,24,48,0,0)}
  IMAGES.nutrient_dispenser = love.graphics.newImage('art/nutrient_dispenser-anim_4-4.png')
  ANIMATIONS.nutrient_dispenser = {
    Anim(4,IMAGES.nutrient_dispenser,1,4,24,24, 0,0,0),
    Anim(4,IMAGES.nutrient_dispenser,1,4,24,24,24,0,0),
    Anim(4,IMAGES.nutrient_dispenser,1,4,24,24,48,0,0),
    Anim(4,IMAGES.nutrient_dispenser,1,4,24,24,72,0,0)}

  IMAGES.navigation_system = love.graphics.newImage('art/navigation_system-anim_2-4.png')
  ANIMATIONS.navigation_system = {
    Anim(3,IMAGES.navigation_system,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.navigation_system,1,4,24,24,24,0,0)}
  IMAGES.shield_system = love.graphics.newImage('art/shield_system-anim_2-4.png')
  ANIMATIONS.shield_system = {
    Anim(3,IMAGES.shield_system,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.shield_system,1,4,24,24,24,0,0)}
  IMAGES.sensor_system = love.graphics.newImage('art/sensor_system-anim_2-4.png')
  ANIMATIONS.sensor_system = {
    Anim(3,IMAGES.sensor_system,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.sensor_system,1,4,24,24,24,0,0)}
  IMAGES.weapons_system = love.graphics.newImage('art/weapons_system-anim_2-4.png')
  ANIMATIONS.weapons_system = {
    Anim(3,IMAGES.weapons_system,1,4,24,24, 0,0,0),
    Anim(3,IMAGES.weapons_system,1,4,24,24,24,0,0)}

  IMAGES.propulsion_system = love.graphics.newImage('art/propulsion_system-anim_3-5.png')
  ANIMATIONS.propulsion_system = {
    Anim(7,IMAGES.propulsion_system,1,5,24,24, 0,0,0),
    Anim(7,IMAGES.propulsion_system,1,5,24,24,24,0,0),
    Anim(7,IMAGES.propulsion_system,1,5,24,24,48,0,0)}

  IMAGES.defense_console = love.graphics.newImage('art/defense_console-anim-4.png')
  ANIMATIONS.defense_console = Anim(3,IMAGES.defense_console,1,4,24,24, 0,0,0)
  IMAGES.flight_console = love.graphics.newImage('art/flight_console-anim-4.png')
  ANIMATIONS.flight_console = Anim(3,IMAGES.flight_console,1,4,24,24, 0,0,0)
  IMAGES.ftl_console = love.graphics.newImage('art/ftl_console-anim-4.png')
  ANIMATIONS.ftl_console = Anim(3,IMAGES.ftl_console,1,4,24,24, 0,0,0)

  IMAGES.reactor = love.graphics.newImage('art/reactor-anim_3-5.png')
  ANIMATIONS.reactor = {
    Anim(7.5,IMAGES.reactor,1,5,24,24, 0,0,0),
    Anim(7.5,IMAGES.reactor,1,5,24,24,24,0,0),
    Anim(7.5,IMAGES.reactor,1,5,24,24,48,0,0)}

  IMAGES.ftl_drive = love.graphics.newImage('art/ftl_drive-anim_4-8.png')
  ANIMATIONS.ftl_drive = {
    Anim(3,IMAGES.ftl_drive,1,8,24,24, 0,0,0),
    Anim(3,IMAGES.ftl_drive,1,8,24,24,24,0,0),
    Anim(3,IMAGES.ftl_drive,1,8,24,24,48,0,0),
    Anim(3,IMAGES.ftl_drive,1,8,24,24,72,0,0)}

  IMAGES.background = make_background(1080,912,24)
end
