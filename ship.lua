
local class = class or require "middleclass"
local path = path or require "path"

--------------------------------------------------------------------------------
MAP = {
  "#q#h#h#h#h#h#h#h#h#h#w",
  "#ver  nd      wd  sl#v",
  "#vcr                #v",
  "#vjr              pl#v",
  "#r#h#h#w+h#h#d#h#h#h#l",
  "#v    #v    #vbdbdbd#v",
  "#vMr  +v    +v      #v",
  "#v    #v    #vbububu#v",
  "#r#h#h#l    #r#h#h#h#l",
  "#vfr  #v    +v    tl#v",
  "#v    +v    #r#h#h#h#l",
  "#vzr  #v    #v    Wl#v",
  "#vzr  #v    +v      #v",
  "#vzr  #v    #v    Fl#v",
  "#r#h#h#l+h#h#u#d#h#h#l",
  "#v    #v      #v  Ol#v",
  "#vRr  +v      +v  Tl#v",
  "#v    #v      #v  Sl#v",
  "#a#h#h#u#h*h#h#u#h#h#s",
}

--------------------------------------------------------------------------------

CELL_CHARS = {
  door={h='─',v='│'},
  airlock='*',
  empty=' ',
  --ox hv udlr qwas
  --┼╬ ═║ ╩╦╣╠ ╔╗╚╝
  wall={o='┼',x='╬ ',h='═',v='║ ',u='╩',d='╦',l='╣',r='╠ ',q='╔',w='╗',a='╚',s='╝'},
  bed='=',
  table='^',
}


Cell = class("Cell")
function Cell:initialize(idx,x,y,device,char,passable,args)
  self.device = device
  self.char = char
  self.passable = passable
  self.neighbors = {}
  self.cost = 1.0
  self.idx = idx
  self.x = x
  self.y = y
  if args then for k,v in pairs(args) do self[k]=v end end
end
function Cell:__tostring()
  return string.format("[%s:%s(%i,%i)]", self.char, self.passable, self.x, self.y)
end

function EmptyCell(code,idx,x,y)
  local c = Cell(idx,x,y,nil,' ', true)
  return c
end
function AirlockCell(code,idx,x,y)
  local c = Cell(idx,x,y,nil,'*', false)
  return c
end
function WallCell(code,idx,x,y)
  local ch = CELL_CHARS.wall[code] or '#'
  local c = Cell(idx,x,y,nil,ch, false)
  return c
end
-- TODO: clean this up
function DoorCell(code,idx,x,y)
  local ch = CELL_CHARS.door[code] or '+'
  local c = Cell(idx,x,y,nil,ch, true,{is_locked=false,cost=1.5})
  c.device = Door(ship,c)
  return c
end

--------------------------------------------------------------------------------
Ship = class("Ship")

function Ship:initialize(map)
  self.devices = {}

  self.level = {
    co2=Level('co2',50.0, 0,1000, 0),
    energy=Level('energy',500.0, 0,1000, 0),
    o2=Level('o2',50.0, 0,100, 0),
    radiation=Level('radiation',1.0, 0,1e6, 0),
    food=Level('food',100.0, 0,200, 0),
    slurry=Level('slurry',200.0, 0,1000, 0),
    temp=Level('temp',98.0, 0,1000, 0),
    waste=Level('waste',10.0, 0,1000, 0),
    --[[
    hull_integrity
    navigation_data
    sensor_data
    communications_data
    shield_power
    weapon_power
    propulsion_power
    --]]
    }

  self.x_size = #map[1]/2
  self.y_size = #map
  self.cells = {}
  for y,row in ipairs(map) do
    for x=1,#row/2 do
      local idx = self:idx(x,y)
      local ch = row:sub(2*x-1,2*x-1)
      local code = row:sub(2*x,2*x)
      local c
      if ch==' ' then
        c = EmptyCell(code,idx,x,y)
      elseif ch=='#' then
        c = WallCell(code,idx,x,y)
      elseif ch=='+' then
        c = DoorCell(code,idx,x,y)
      elseif ch=='*' then
        c = AirlockCell(code,idx,x,y)
      else
        -- TODO: device emplacement
        c = EmptyCell(code,idx,x,y)
        c.char = ch
        if DEVICES[ch] then
          local d = DEVICES[ch](self,c)
          self.devices[#self.devices+1] = d
          c.device = d
        end
      end
      self.cells[idx] = c
    end
  end

  -- setup edges
  for i,c in ipairs(self.cells) do
    local x0,y0 = self:xy(i)
    if self:cell(x0,y0).passable then
      local n = c.neighbors
      if x0>1             and self:cell(x0-1,y0).passable then n[#n+1] = self:idx(x0-1,y0) end
      if x0<self.x_size-1 and self:cell(x0+1,y0).passable then n[#n+1] = self:idx(x0+1,y0) end
      if y0>1             and self:cell(x0,y0-1).passable then n[#n+1] = self:idx(x0,y0-1) end
      if y0<self.y_size-1 and self:cell(x0,y0+1).passable then n[#n+1] = self:idx(x0,y0+1) end
    end
  end

  self.devices_by_name = {}
  for _,d in ipairs(self.devices) do
    local n = d.class.name
    if not self.devices_by_name[n] then self.devices_by_name[n] = {} end
    local a = self.devices_by_name[n]
    a[#a+1] = d
  end
end

function Ship:path(c0,c1)
  local function edges(e,i)
    local n = self.cells[i].neighbors
    for j=1,4 do e[j]=n[j] end
    return e
  end
  local function step_cost_fn(i)
    return self.cells[i].cost -- + love.math.random()/1024
  end
  local function estimate(i0,i1)
    local x0,y0 = self:xy(i0)
    local x1,y1 = self:xy(i1)
    return math.sqrt((x1-x0)^2+(y1-y0)^2)
  end
  local foundit,the_path,result = path.astar(c0.idx,c1.idx,step_cost_fn,edges,estimate,true)
  if foundit then
    for i,pi in ipairs(the_path) do
      the_path[i] = {self:xy(pi)}
    end
  end
  return foundit,the_path
end

-- TODO: should use path-distance, not metric
-- this will break if there is no path at all...
-- (should probably compute "dijkstra maps" for all devices...
function Ship:locate_device(name,x,y)
  local best_device = nil
  local best_dist = 1e10
  for i,d in ipairs(self.devices_by_name[name]) do
    local c = d.cell
    local dist = math.abs(c.x-x) + math.abs(c.y-y)
    if dist < best_dist then
      best_device = d
      best_dist = dist
    end
  end
  return best_device
end

function Ship:xy(i)
  local i = i-1
  return 1+(i%self.x_size), 1+math.floor(i/self.x_size)
end

function Ship:idx(x,y)
  x,y = math.floor(x),math.floor(y)
  return 1 + (x-1) + (y-1)*self.x_size
end

function Ship:cell(x,y)
  local x,y = math.floor(x),math.floor(y)
  if x<1 or x>self.x_size or y<1 or y>self.y_size then
    return nil
  end
  return self.cells[1 + (x-1) + (y-1)*self.x_size]
end


function Ship:update(dt)
  for _,d in ipairs(self.devices) do
    d:update(dt)
  end
  for _,l in pairs(self.level) do
    l:update(dt)
  end
end

function Ship:slow_update(dt)
  for _,d in ipairs(self.devices) do
    d:slow_update(dt)
  end
  for _,l in pairs(self.level) do
    l:slow_update(dt)
  end
end

function Ship:draw_map()
  for y=1,self.y_size do
    for x=1,self.x_size do
      local cl = self:cell(x,y)
      local c = cl.char
      if cl.device=='wall' then
        love.graphics.setColor(0.5,0.5,0.5)
      elseif c=='*' then
        love.graphics.setColor(0.3,0.4,0.5)
      elseif cl.device=='door' then
        love.graphics.setColor(0.5,0.4,0.3)
      else
        love.graphics.setColor(0.7,0.7,0.8)
      end
      love.graphics.rectangle('fill', (x-1)*24, (y-1)*24, 24, 24)

      love.graphics.setColor(0.1,0.1,0.5,0.25)
      love.graphics.rectangle('line', (x-1)*24, (y-1)*24, 24, 24)

      if cl.device and cl.device.draw then
        love.graphics.push()
          love.graphics.translate((x-1)*24, (y-1)*24)
          cl.device:draw()
        love.graphics.pop()
      else
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(c, FONT_1, 6+(x-1)*24, 4+(y-1)*24)
      end
    end
  end

  --love.graphics.setColor(0.2,0.3,0.4,0.8)
  --love.graphics.rectangle('line',0.5,0.5, 24*19-1,24*19-1)
end


