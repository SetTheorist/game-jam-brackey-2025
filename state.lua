
local class = class or require "middleclass"


State = class("State")

function State:initialize()
  self.the_ship = Ship()
  self.the_crew = {}

  -- TODO: only 1 crew and the rest in cryopods...
  for i,name in ipairs({'pat','chris','terry','dana','francis','jean','jo','jordan','cameron','casey','kelly','ollie'}) do
    self.the_crew[#self.the_crew+1] = Crew(name,self.the_ship)
  end

  self.chosen_cell = nil
  self.chosen_crew_idx = nil
  self.chosen_crew = nil

  self.the_score = 100
  self.elapsed_time = 0

  self.current_node = start_node
  self.current_progress = 0

  self.paused = false
end
