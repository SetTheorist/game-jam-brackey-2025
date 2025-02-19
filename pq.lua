
local class = class or require "middleclass"

-- min-heap function
local function bubble_up(arr, i)
  while i>1 do
    local par = 1+math.floor((i-1)/2)
    if arr[par][1] > arr[i][1] then
      arr[par],arr[i] = arr[i],arr[par]
      i = par
    else
      break
    end
  end
end

-- min-heap function
local function bubble_down(arr, i)
  local n = #arr
  while 2*i<=n do
    local li = 2*i
    local ri = 2*i+1
    if ri>n then ri=n end
    local xi = ((arr[li][1]<arr[ri][1]) and li) or ri
    if arr[xi][1] < arr[i][1] then
      arr[xi],arr[i] = arr[i],arr[xi]
      i = xi
    else
      break
    end
  end
end

local function heapify(arr)
  for i=1,#arr do
    bubble_up(arr, i)
  end
end

PQ = class("PQ")

function PQ:push(x)
  self[#self+1] = x
  bubble_up(self, #self)
end

function PQ:peek()
  return self[1]
end

function PQ:pop()
  local res = self[1]
  self[1] = self[#self]
  self[#self] = nil
  bubble_down(self, 1)
  return res
end

return PQ


