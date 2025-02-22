local class = class or require "middleclass"

--------------------------------------------------------------------------------

local SceneManager = class("SceneManager")

function SceneManager:__tostring()
  local x = {'SceneManager:', tostring(self.active_scene),'['}
  for i=#self.stack,1,-1 do
    x[#x+1] = tostring(self.stack[i])
  end
  x[#x+1] = ']'
  return table.concat(x,' ')
end

function SceneManager:initialize(scenes)
  self.active_scene = nil
  self.scenes = {}
  for _,s in ipairs(scenes) do
    self.scenes[s.name] = s
    s.manager = self
  end
  self.stack = {}
  --for k,v in pairs(self.scenes) do print(k,v) end
end

function SceneManager:load()
  for _,s in pairs(self.scenes) do
    s:load()
  end
end

function SceneManager:add(scene)
  self.scenes[scene.name] = scene
  scene.manager = self
end

function SceneManager:update(dt)
  if self.active_scene then
    self.active_scene:update(dt)
  end
end

function SceneManager:draw()
  for _,s in ipairs(self.stack) do
    s:draw(false)
  end
  if self.active_scene then
    self.active_scene:draw(true)
  end
end

function SceneManager:quit()
  if self.active_scene then
    return self.active_scene:quit()
  end
end

function SceneManager:set(scene_id,...)
  local next_scene = self.scenes[scene_id]
  --print(string.format("SceneManager:set(%s) %s active=%s next=%s", scene_id, self, self.active_scene, next_scene))
  if next_scene == self.active_scene then return end
  local prev_scene = self.active_scene
  if prev_scene then
    prev_scene:exit(next_scene,...)
  end
  self.active_scene = next_scene
  if self.active_scene then
    self.active_scene:enter(prev_scene,...)
  else
    print(("Unable to find scene with id `%s`").format(scene_id))
  end
  collectgarbage('collect')
end

function SceneManager:push(scene_id,...)
  --print(string.format("SceneManager:push(%s) %s", scene_id, self))
  local next_scene = self.scenes[scene_id]
  local prev_scene = self.active_scene
  if prev_scene then
    self.stack[#self.stack + 1] = prev_scene
    prev_scene:pause(next_scene,...)
  end
  self.active_scene = next_scene
  if self.active_scene then
    self.active_scene:enter(prev_scene,...)
  else
    print(("Unable to find scene with id `%s`").format(scene_id))
  end
  collectgarbage('collect')
end

function SceneManager:pop(...)
  --print(string.format("SceneManager:pop(%s) %s", scene_id, self))
  local prev_scene = self.active_scene
  local next_scene = self.stack[#self.stack]
  if prev_scene then
    prev_scene:exit(next_scene,...)
  end
  self.active_scene = next_scene
  table.remove(self.stack, #self.stack)
  if self.active_scene then
    self.active_scene:resume(prev_scene,...)
  end
  collectgarbage('collect')
end

function SceneManager:keypressed(key,scancode,isrepeat)
  if self.active_scene and self.active_scene.keypressed then
    self.active_scene:keypressed(key,scancode,isrepeat)
  end
end

function SceneManager:keyreleased(key,scancode)
  if self.active_scene and self.active_scene.keyreleased then
    self.active_scene:keyreleased(key,scancode)
  end
end

function SceneManager:mousemoved(x,y,dx,dy,istouch)
  if self.active_scene and self.active_scene.mousemoved then
    self.active_scene:mousemoved(x,y,dx,dy,istouch)
  end
end

function SceneManager:wheelmoved(x,y)
  if self.active_scene and self.active_scene.wheelmoved then
    self.active_scene:wheelmoved(x,y)
  end
end

function SceneManager:mousepressed(x,y,button,istouch,presses)
  if self.active_scene and self.active_scene.mousepressed then
    self.active_scene:mousepressed(x,y,button,istouch,presses)
  end
end

function SceneManager:mousereleased(x,y,button,istouch,presses)
  if self.active_scene and self.active_scene.mousereleased then
    self.active_scene:mousereleased(x,y,button,istouch,presses)
  end
end

--------------------------------------------------------------------------------

return SceneManager



