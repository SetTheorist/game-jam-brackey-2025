
local class = class or require "middleclass"

--------------------------------------------------------------------------------

local Anim = class("Anim")

function Anim:initialize(fps,image,n,frame_w,frame_h,frame_x,frame_y,frame_gap)
  self.fps = fps
  self.frame = 0
  self.spf = 1/fps
  self.t = 0
  self.x = 0
  self.y = 0
  self.rotation = 0
  self.image = image
  self.image_w,self.image_h = image:getDimensions()
  self.frame_w,self.frame_h = frame_w,frame_h
  self.quads = {}
  self.n = n
  for i=1,n do
    local t = frame_y
    local l = frame_x + (i-1)*(frame_w+frame_gap)
    local q = love.graphics.newQuad(l,t,frame_w,frame_h,self.image_w,self.image_h)
    self.quads[i] = q
  end
end

function Anim:set_fps(fps)
  self.fps = fps
  self.spf = 1/fps
end

function Anim:update(dt)
  self.t = self.t + dt
  if self.t > self.spf then
    self.frame = (self.frame + 1)%self.n
    self.t = self.t - self.spf
  end
end

function Anim:draw()
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(self.image, self.quads[self.frame+1], self.x, self.y, self.rotation, 1, 1, self.frame_w/2, self.frame_h/2)
end

return Anim
