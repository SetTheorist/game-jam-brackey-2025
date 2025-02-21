

local start_node = 'omicron_persei_8'
local end_node = 'earth'
current_node = 'omicron_persei_8'
current_progress = 0

local nodes = {
  omicron_persei_8 = {
    name="Omicron Persei",
    description="A ghastly planetary system",
    events={},
    image='',
    next={asteroid_belt=2,
          long_way=2},
  },
  asteroid_belt = {
    name="Asteroid belt",
    description="",
    events={'asteroid_storm'},
    image='',
    next={midway=2},
  },
  long_way = {
    name="long_way",
    description="",
    events={},
    image='',
    next={long_way_2=3},
  },
  long_way_2 = {
    name="long_way_2",
    description="",
    events={},
    image='',
    next={midway=3},
  },
  midway = {
    name="Midway",
    description="",
    events={},
    image='',
    next={earth=2},
  },
  earth = {
    name="Earth",
    description="Your final destination.",
    events={},
    image='',
    next={},
  },
}
