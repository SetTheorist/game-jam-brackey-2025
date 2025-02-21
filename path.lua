local pq = pq or require "pq"

local mod = {}

local function reverse(arr)
  local n = #arr
  local n2 = math.floor(n/2)
  for i=1,n2 do
    arr[i],arr[n+1-i] = arr[n+1-i],arr[i]
  end
end

function mod.astar(start,goal,step_cost,edges,estimate,reversed)
  local result = {[start]=0}
  local e = {nil,nil,nil,nil}
  local q = pq()
  q:push({0,start})
  while #q > 0 do
    local z = q:pop()[2]
    if z==goal then break end
    local r_z = result[z]

    for _,nz in ipairs(edges(e,z)) do
      local r_nz = r_z + step_cost(z, nz)
      local est_nz = r_nz + estimate(nz, goal)
      local or_nz = result[nz]
      if not or_nz or (r_nz < or_nz) then
        result[nz] = r_nz
        q:push({est_nz, nz})
      end
    end
  end

  local path = {}
  path[#path+1] = goal
  local x = goal
  local foundit = true
  while x~=start do
    local min_res = 1e100
    local px = x
    for _,pz in ipairs(edges(e,x)) do
      local res_pz = result[pz]
      if res_pz then
        if res_pz < min_res then
          px = pz
          min_res = res_pz
        end
      end
    end
    if not min_res then foundit=false; break end
    x = px
    path[#path+1] = x
  end
  if not reversed then
    reverse(path)
  end
  return foundit,path,result
end

return mod
