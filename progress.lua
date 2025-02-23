
local SQ2 = math.sqrt(2)
local ISQ2 = math.sqrt(0.5)

NODES = {
  dagon_fomalhaut = {
    name="Dagon Fomalhaut A",
    description="A ghastly planetary system",
    events={},
    tile='planet_dagon',
    next='asteroid_belt',
    time=8.5,
    start_position={2,2},
    end_position={8,8},
    dir={ISQ2,ISQ2},
  },
  asteroid_belt = {
    name="Asteroid belt",
    description="A region of space filled with rocky and metallic space debris",
    events={asteroid_storm=1/16}, -- about 1/"day"
    tile='planet_asteroids',
    next='earth',
    time=6,
    start_position={8,8},
    end_position={14,8},
    dir={1.0,0.0},
  },
  earth = {
    name="Earth",
    description="Your final destination",
    events={pirate_attack=1/32}, -- about 1/2"days"
    tile='planet_earth',
    next={},
    time=8.5,
    start_position={14,8},
    end_position={20,2},
    dir={ISQ2,-ISQ2},
  },
}

START_NODE = NODES.dagon_fomalhaut
FINAL_NODE = NODES.earth

