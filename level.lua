--------------------------------------------------------------------------------

Level = class("Level")

function Level:initialize(name,value,min,max,decay,history_len)
  self.name = name
  self.value = value
  self.min = min
  self.max = max
  self.decay = decay
  self.history = {}
  for i=1,(history_len or 8) do self.history[i] = value end
  self.history_idx = 1
end

function Level:__tostring()
  return string.format("%s=%.01f[%.01f,%.01f](%.02f)", self.name, self.value, self.min, self.max, self.decay)
end

function Level:update(dt)
  self.value = math.max(self.min, math.min(self.max, self.value + dt*self.decay))
end

function Level:slow_update(dt)
  self.history[self.history_idx] = self.value
  self.history_idx = 1 + (self.history_idx % #self.history)
end

function Level:add(dvalue)
  local old_value = self.value
  self.value = math.max(self.min, math.min(self.max, old_value + dvalue))
  return self.value - old_value
end

function Level:sub(dvalue)
  local old_value = self.value
  self.value = math.max(self.min, math.min(self.max, old_value - dvalue))
  return old_value - self.value
end

function Level:set(value)
  local old_value = self.value
  self.value = math.max(self.min, math.min(self.max, value))
  return self.value - old_value
end


