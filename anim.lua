
local class = class or require "middleclass"

--------------------------------------------------------------------------------

local Anim = class("Anim")

function Anim:initialize(fps,image,nx,ny,frame_w,frame_h,frame_x,frame_y,frame_gap)
  print(fps,image,'nx',nx,'ny',ny,frame_w,frame_h,'fx',frame_x,'fy',frame_y,frame_gap)
  self.fps = fps
  self.fps_scale = 1.0
  self.frame = 0
  self.spf = 1/fps
  self.t = 0
  self.x = 0
  self.y = 0
  self.rotation = 0
  self.image = image
  local image_w,image_h = image:getDimensions()
  self.image_w,self.image_h = image_w,image_h
  self.frame_w,self.frame_h = frame_w,frame_h
  self.frame_x,self.frame_y,self.frame_gap = frame_x,frame_y,frame_gap
  self.quads = {}
  self.nx = nx
  self.ny = ny
  self.n = nx*ny
  for y=1,ny do
    for x=1,nx do
      local t = frame_y + (y-1)*(frame_h+frame_gap)
      local l = frame_x + (x-1)*(frame_w+frame_gap)
      local q = love.graphics.newQuad(l,t,frame_w,frame_h,image_w,image_h)
      self.quads[#self.quads+1] = q
    end
  end
end

function Anim:clone(args)
  local res = Anim(self.fps,self.image,self.nx,self.ny,self.frame_w,self.frame_h,self.frame_x,self.frame_y,self.frame_gap)
  if args then
    for k,v in pairs(args) do
      res[k] = v
    end
  end
  return res
end

function Anim:set_fps_scale(fps_scale)
  self.fps_scale = fps_scale
  self.spf = 1/(self.fps*fps_scale)
end

function Anim:set_fps(fps)
  self.fps = fps
  self.spf = 1/(fps*self.fps_scale)
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
  love.graphics.draw(self.image, self.quads[self.frame+1],
    self.x, self.y, self.rotation, 1, 1, self.frame_w/2, self.frame_h/2)
end

return Anim
