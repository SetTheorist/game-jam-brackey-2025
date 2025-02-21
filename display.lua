
----------------------------------------
function draw_crew_panel(crew)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle('line',0.5,0.5, 199,199)

  if not crew then return end

  love.graphics.setColor(crew.color[1],crew.color[2],crew.color[3],1.0)
  --love.graphics.print(tostring(crew),1.5,1.5)
  love.graphics.print(crew.name,1.5,1.5)

  love.graphics.setColor(1,1,1,1)
  love.graphics.print(string.format("Health:%3i", crew.level.health), 1.5,23.5)
  love.graphics.print(string.format("Food:%3i",   crew.level.food),   1.5,35.5)
  love.graphics.print(string.format("Rest:%3i",   crew.level.rest),   1.5,47.5)
  love.graphics.print(string.format("Waste:%3i",  crew.level.waste),  1.5,59.5)
  love.graphics.print(string.format("Stress:%3i", crew.level.stress), 1.5,71.5)
  love.graphics.print(string.format("O2:%3i",     crew.level.o2),     1.5,83.5)

  if crew.current_action then
    love.graphics.print(tostring(crew.current_action), 1.5,107.5)
  end
  for i,a in ipairs(crew.action_stack) do
    love.graphics.print(tostring(a), 1.5,107.5+12+12*i)
  end

  -- TODO: actual UI buttons, etc.
  love.graphics.print("<EAT>",  10.5,199.5-20)
  love.graphics.print("<SLP>",  50.5,199.5-20)
  love.graphics.print("<WAS>",  90.5,199.5-20)
  love.graphics.print("<MED>", 130.5,199.5-20)
end

----------------------------------------
function draw_ship_stats_panel(ship)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle('line',0.5,0.5, 199,199)
  love.graphics.print(string.format("co2:%3i", ship.level.co2.value), 1.5,1.5)
  love.graphics.print(string.format("energy:%3i", ship.level.energy.value), 1.5,13.5)
  love.graphics.print(string.format("o2:%3i", ship.level.o2.value), 1.5,25.5)
  love.graphics.print(string.format("radiation:%3i", ship.level.radiation.value), 1.5,37.5)
  love.graphics.print(string.format("food:%3i", ship.level.food.value), 1.5,49.5)
  love.graphics.print(string.format("slurry:%3i", ship.level.slurry.value), 1.5,61.5)
  love.graphics.print(string.format("temp:%3i", ship.level.temp.value), 1.5,73.5)
  love.graphics.print(string.format("waste:%3i", ship.level.waste.value), 1.5,85.5)
end

----------------------------------------
function draw_ship_map_panel(ship,chosen_cell,chosen_crew)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(IMAGES.ship_frame,0-24,0-24) -- XXX - using 0.5 here gives aliasing
  ship:draw_map()
  love.graphics.setColor(1,1,1,1)
  for i,c in ipairs(ship.the_crew) do
    c:draw()
    if c == chosen_crew then
      love.graphics.setColor(1,0,1,0.8)
      love.graphics.circle('line',(c.location.x-1)*24,(c.location.y-1)*24,12)
      love.graphics.setColor(1,1,1,1)
    end
  end
  if chosen_cell then
    love.graphics.setColor(1,0,1,0.8)
    love.graphics.rectangle('line',(chosen_cell.x-1)*24,(chosen_cell.y-1)*24,24,24)
  end
end

----------------------------------------
function draw_cell_panel(cell)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle('line',0.5,0.5, 199,199)

  if not cell then return end
  love.graphics.print(string.format("%02i-%02i",cell.x,cell.y), 1.5,1.5)
  love.graphics.print(cell.char, 199.5-12,1.5)

  local d = cell.device
  if not d then return end

  love.graphics.print(d.name, 1.5,13.5)
  if d.enabled   then love.graphics.print('e', 199.5-12*3,13.5) end
  if d.activated then love.graphics.print('a', 199.5-12*2,13.5) end
  if d.manned    then love.graphics.print('m', 199.5-12*1,13.5) end
  love.graphics.print(string.format("Efficiency:%3i", (d.efficiency*100)), 1.5,25.5)

  if d.owner then
    love.graphics.print(d.owner, 13.5,13.5)
  end

  -- TODO: move health to "Level" and plot historical chart
  love.graphics.print(string.format("Electronic:%3i (-%.04f%%)",
    (d.health.electronic*100), (d.decay.electronic*100)), 13.5, 37.5)
  love.graphics.print(string.format("Mechanical:%3i (-%.04f%%)",
    (d.health.mechanical*100), (d.decay.mechanical*100)), 13.5, 49.5)
  love.graphics.print(string.format("Quantum:%3i (-%.04f%%)",
    (d.health.quantum*100), (d.decay.quantum*100)), 13.5, 61.5)

  if d.activation_elapsed>0 then
    love.graphics.print(string.format("Accrued:%0.01f/%0.01f",
      d.activation_elapsed, d.activation_time), 13.5, 85.5)
  end

  local i = 100.5
  for k,v in pairs(d.inputs) do
    love.graphics.print(k, 1.5, i)
    love.graphics.print(v, 51.5, i)
    i = i + 12
  end

  local i = 100.5
  for k,v in pairs(d.outputs) do
    love.graphics.print(k, 100+1.5, i)
    love.graphics.print(v, 100+51.5, i)
    i = i + 12
  end

  -- TODO: actual UI buttons, etc.
  if not d.repair_job then
    love.graphics.setColor(1,1,1)
  else
    love.graphics.setColor(1,1,0)
  end
  love.graphics.print("<REP>",  10.5,199.5-20)

  if d.enabled and d.manned then
    love.graphics.setColor(1,1,1)
  else
    love.graphics.setColor(0.5,0.5,0.6)
  end
  love.graphics.print("<MAN>", 60.5,199.5-20)

end


