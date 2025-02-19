local class = class or require "middleclass"
local xcolors = xcolors or require "xcolors"

--------------------------------------------------------------------------------

local UI = {}

--local default_font = love.graphics.newFont('Gellisto.ttf', 40)
--local default_font = love.graphics.newFont('Mystician.ttf', 40) --XXX missing numerals

----------------------------------------
local UIElement = class("UIElement")
UI.UIElement = UIElement
function UIElement:initialize(parent,args)
  self.parent = parent
  self.x,self.y = args.x,args.y
  self.w,self.h = args.w,args.h
end
function UIElement:load() end
function UIElement:update(dt) end
function UIElement:draw() end
function UIElement:rect() return self.x,self.y,self.w,self.h end
function UIElement:recalculate() end

function UIElement:mousemoved(x,y,dx,dy,istouch) return false end
function UIElement:mousepressed(x,y,button,istouch,presses) return false end
function UIElement:mousereleased(x,y,button,istouch,presses) return false end
function UIElement:wheelmoved(x,y,button) return false end
function UIElement:keypressed(key,scancode,isrepeat) return false end
function UIElement:keyreleased(key,scancode) return false end
function UIElement:forwardtochildren(f,...)
  for _,w in ipairs(self.children) do
    if w[f](w,...) then
      return true
    end
  end
  return false
end 
function UIElement:forward_mousemoved(x,y,dx,dy,istouch)
  return self:forwardtochildren('mousemoved',x-self.x,y-self.y,dx,dy,istouch)
end
function UIElement:forward_mousepressed(x,y,button,istouch,presses)
  return self:forwardtochildren('mousepressed',x-self.x,y-self.y,button,istouch,presses)
end
function UIElement:forward_mousereleased(x,y,button,istouch,presses)
  return self:forwardtochildren('mousereleased',x-self.x,y-self.y,button,istouch,presses)
end
function UIElement:forward_wheelmoved(...) return self:forwardtochildren('wheelmoved',...) end
function UIElement:forward_keypressed(...) return self:forwardtochildren('keypressed',...) end
function UIElement:forward_keyreleased(...) return self:forwardtochildren('keyreleased',...) end
function UIElement:isin(x,y)
  return (
    ((x - self.x) < self.w)
    and (x >= self.x)
    and ((y - self.y) < self.h)
    and (y >= self.y)
    )
end


----------------------------------------
local UIVerticalGrid = class("UIVerticalGrid", UIElement)
UI.UIVerticalGrid = UIVerticalGrid

function UIVerticalGrid:initialize(parent,args,children)
  self.class.super.initialize(self,parent,args)
  self.justification = args.justification or 'center'
  self.children = children
end

function UIVerticalGrid:load()
  for _,w in ipairs(self.children) do
    w.parent = self
    w:load()
  end
  self:recalculate()
end

function UIVerticalGrid:recalculate()
  local n = #self.children
  local child_h = 0 for _,w in ipairs(self.children) do
    child_h = child_h + w.h
  end
  local gap_h = (self.h - child_h)/(n+1)
  local child_h = 0
  for i,w in ipairs(self.children) do
    w.x = (self.w - w.w)/2
    w.y = gap_h*i + child_h
    child_h = child_h + w.h
  end
end

function UIVerticalGrid:update(dt)
  for _,w in ipairs(self.children) do
    w:update(dt)
  end
end
function UIVerticalGrid:draw()
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.1,0.1,0.1,0.1)
  love.graphics.rectangle('fill',self:rect())
  love.graphics.setColor(0.2,0.2,0.2,0.2)
  love.graphics.rectangle('line',self:rect())

  love.graphics.push()
  love.graphics.translate(self.x,self.y)
    for _,w in ipairs(self.children) do
      w:draw()
    end
  love.graphics.pop()
end

UIVerticalGrid.mousemoved = UIElement.forward_mousemoved
UIVerticalGrid.mousepressed = UIElement.forward_mousepressed
UIVerticalGrid.mousereleased = UIElement.forward_mousereleased
UIVerticalGrid.wheelmoved = UIElement.forward_wheelmoved
UIVerticalGrid.keypressed = UIElement.forward_keypressed
UIVerticalGrid.keyreleased = UIElement.forward_keyreleased

----------------------------------------
local UIHorizontalGrid = class("UIHorizontalGrid", UIElement)
UI.UIHorizontalGrid = UIHorizontalGrid

function UIHorizontalGrid:initialize(parent,args,children)
  self.class.super.initialize(self,parent,args)
  self.justification = args.justification or 'center'
  self.children = children
end

function UIHorizontalGrid:load()
  for _,w in ipairs(self.children) do
    w.parent = self
    w:load()
  end
  self:recalculate()
end

function UIHorizontalGrid:recalculate()
  local n = #self.children
  local child_w = 0
  for _,w in ipairs(self.children) do
    child_w = child_w + w.w
  end
  local gap_w = (self.w - child_w)/(n+1)
  local child_w = 0
  for i,w in ipairs(self.children) do
    w.x = gap_w*i + child_w
    w.y = (self.h - w.h)/2
    child_w = child_w + w.w
  end
end

function UIHorizontalGrid:update(dt)
  for _,w in ipairs(self.children) do
    w:update(dt)
  end
end
function UIHorizontalGrid:draw()
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.1,0.1,0.1,0.1)
  love.graphics.rectangle('fill',self:rect())
  love.graphics.setColor(0.2,0.2,0.2,0.2)
  love.graphics.rectangle('line',self:rect())

  love.graphics.push()
  love.graphics.translate(self.x,self.y)
    for _,w in ipairs(self.children) do
      w:draw()
    end
  love.graphics.pop()
end

UIHorizontalGrid.mousemoved = UIElement.forward_mousemoved
UIHorizontalGrid.mousepressed = UIElement.forward_mousepressed
UIHorizontalGrid.mousereleased = UIElement.forward_mousereleased
UIHorizontalGrid.wheelmoved = UIElement.forward_wheelmoved
UIHorizontalGrid.keypressed = UIElement.forward_keypressed
UIHorizontalGrid.keyreleased = UIElement.forward_keyreleased

----------------------------------------
local UITextLabel = class("UITextLabel", UIElement)
UI.UITextLabel = UITextLabel

function UITextLabel:initialize(parent,args)
  self.class.super.initialize(self,parent,args)
  self.color = args.color or color.white
  self.font = args.font or DEFAULT_FONT
  self.raw_text = args.text
  self.text = love.graphics.newText(self.font, args.text)
  self.text_height = self.text:getHeight()
  self.text_width = self.text:getWidth()
  self.justification = args.justification or 'center'
  self.h_justification = args.h_justification or self.justification
  self.v_justification = args.v_justification or self.justification
  self:recalc()
end

function UITextLabel:recalc()
  if self.h_justification=='left' then
    self.tx = 0
  elseif self.h_justification=='right' then
    self.tx = (self.w - self.text_width)
  else
    self.tx = (self.w - self.text_width)/2
  end
  if self.v_justification=='top' then
    self.ty = 0
  elseif self.v_justification=='bottom' then
    self.ty = (self.h - self.text_height)
  else
    self.ty = (self.h - self.text_height)/2
  end
end

function UITextLabel:setfont(font)
  self.font = font or DEFAULT_FONT
  self.text = love.graphics.newText(self.font, self.raw_text)
  self.text_height = self.text:getHeight()
  self.text_width = self.text:getWidth()
  self:recalc()
end

function UITextLabel:settext(text)
  self.text = self.text.set(text)
  self.text_height = self.text:getHeight()
  self.text_width = self.text:getWidth()
  self:recalc()
end

function UITextLabel:draw()
  love.graphics.setColor(self.color:rgb())
  love.graphics.draw(self.text, self.x+self.tx, self.y+self.ty)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(0.5,0,0,0.5)
  love.graphics.rectangle('line',self:rect())
end


----------------------------------------
local UIButton = class("UIButton", UIElement)
UI.UIButton = UIButton

UIButton.colors = {
  disabled = {
    fill=color.mistyrose4/3,
    line=color.mistyrose/3,
    text=color.yellow/3,
  },
  enabled = {
    fill=color.mistyrose4,
    line=color.mistyrose,
    text=color.yellow,
  },
  pressed = {
    fill=color.mistyrose4/2,
    line=color.mistyrose,
    text=color.yellow,
  },
}

function UIButton:initialize(parent,args,callback,...)
  self.class.super.initialize(self,parent,args)
  self.font = args.font or DEFAULT_FONT
  self.raw_text = args.text
  self.text = love.graphics.newText(self.font, args.text)
  self.text_height = self.text:getHeight()
  self.text_width = self.text:getWidth()
  self.state = 'enabled'
  self.hover = false
  self.callback = callback
  self.callback_args = {...}
  self.hotkey = args.hotkey
  self.mx,self.my = nil,nil
end

function UIButton:setfont(font)
  self.font = font or DEFAULT_FONT
  self.text = love.graphics.newText(self.font, self.raw_text)
  self.text_height = self.text:getHeight()
  self.text_width = self.text:getWidth()
end

function UIButton:settext(text)
  self.text = self.text.set(text)
  self.text_height = self.text:getHeight()
  self.text_width = self.text:getWidth()
end

function UIButton:setcolors(fill,line,text)
  self.colors= {
    disabled={fill=fill/3, line=line/3, text=text/3},
    enabled={fill=fill, line=line, text=text},
    pressed={fill=fill/2, line=line, text=text},
  }
end

function UIButton:disable()
  self.state = 'disabled'
end

function UIButton:enable()
  self.state = 'enabled'
end

function UIButton:update(dt)
  if self.mx==nil or self.my==nil then return end
  local old_hover = self.hover
  self.hover = self:isin(self.mx,self.my)
  if self.hover and not old_hover then
    love.audio.play(AUDIO.click)
  end
end

function UIButton:draw()
  local c_fill = self.colors[self.state].fill
  local c_line = self.colors[self.state].line
  local c_text = self.colors[self.state].text

  if self.hover then
    love.graphics.push()
    love.graphics.translate(5,-5)
  end

  love.graphics.setColor(c_fill:rgb())
  love.graphics.rectangle('fill', self.x,self.y,self.w,self.h)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(c_line)
  love.graphics.rectangle('line', self.x,self.y,self.w,self.h)

  love.graphics.setColor(c_text:rgb())
  love.graphics.draw(self.text,
    self.x+(self.w-self.text_width)/2,
    self.y+(self.h-self.text_height)/2)

  if self.hover and self.state~='disabled' then
    love.graphics.setLineWidth(5)
    love.graphics.setColor(c_line:rgba(0.5))
    love.graphics.rectangle('line', self.x,self.y,self.w,self.h)
  end

  love.graphics.setColor(1,1,1,1)
  if self.hover then
    love.graphics.pop()
  end
end

function UIButton:mousemoved(x, y, dx, dy, istouch)
  self.mx,self.my = x,y
end

function UIButton:mousepressed(x, y, button, istouch, presses)
  if self.state=='disabled' then return end
  if button==1 and self:isin(x,y) then
    self.state = 'pressed'
    return true
  end
end

function UIButton:mousereleased(x, y, button, istouch, presses)
  if self.state=='disabled' then return end
  if button==1 then
    if self.state=='pressed' then
      if self:isin(x,y) then
        -- TODO: audio
        if self.callback then
          self.callback(unpack(self.callback_args))
        end
        return true
      end
    end
    self.state = 'enabled'
  end
end

function UIButton:keypressed(key, scancode, isrepeat)
  if self.state=='disabled' then return end
  if self.hotkey and self.hotkey==key then
    -- TODO: audio
    self.callback(unpack(self.callback_args))
    self.state = 'enabled'
    return true
  end
end

----------------------------------------
local UISlider = class("UISlider", UIElement)
UI.UISlider = UISlider

function UISlider:initialize(parent,args,callback,...)
  self.class.super.initialize(self,parent,args)
  self.state = 'enabled'
  self.hover = false
  self.max_value = args.max_value
  self.min_value = args.min_value
  self.current_value = args.current_value
  self.steps = args.steps
  self.callback = callback
  self.callback_args = {...}
  self.mx,self.my = nil,nil

  -- assumes l/r gap=10, bar-height=10
  local gapy = (self.h-10)/2
  self.bar_rect = {x=10,y=gapy,w=self.w-20,h=10}
end

function UISlider:update_value(x)
  local prop = (x - self.x - 10) / (self.w-20)
  if self.steps then
    prop = math.floor(0.5 + prop*self.steps)/self.steps
  end
  self.current_value = self.min_value + (self.max_value - self.min_value) * math.max(0,math.min(1,prop))
  if self.callback then
    self.callback(unpack(self.callback_args))
  end
end

function UISlider:knob_location()
  local t = (self.w-20) * (self.current_value-self.min_value)/(self.max_value-self.min_value)
  return self.x+10+t, self.y+self.h/2
end

function UISlider:enable()
  self.state = 'enabled'
end

function UISlider:disable()
  self.state = 'disabled'
end

function UISlider:mousepressed(x, y, button, istouch, presses)
  if self.state=='disabled' then return end
  if button==1 and self:isin(x,y) then
    --local kx,ky = self:knob_location()
    --if (x-kx)^2+(y-ky)^2 < 10^2 then
      self.state = 'dragging'
    --end
    self:update_value(x)
    return true
  end
end

function UISlider:mousereleased(x, y, button, istouch, presses)
  if self.state=='disabled' then return end
  if button==1 then
    if self.state=='dragging' then
      if self:isin(x,y) then
        -- TODO: audio
        self:update_value(x)
      end
    end
    self.state = 'enabled'
  end
end

function UISlider:mousemoved(x, y, dx, dy, istouch)
  self.mx,self.my = x,y
  if self.state == 'dragging' then
    self:update_value(x)
  end
end

function UISlider:update(dt)
  if self.mx==nil or self.my==nil then return end
  local old_hover = self.hover
  self.hover = self:isin(self.mx,self.my)
  if self.hover and not old_hover then
    love.audio.play(AUDIO.click)
  end
end

function UISlider:draw()
  local c = color.navajowhite
  local c4 = color.navajowhite4/3

  if self.hover then
    love.graphics.push()
    love.graphics.translate(5,-5)
  end

  love.graphics.setLineWidth(1)
  love.graphics.setColor(c4:rgb())
  love.graphics.rectangle('fill',self.x,self.y,self.w,self.h)
  love.graphics.setColor(c:rgb())
  love.graphics.rectangle('line',self.x,self.y,self.w,self.h)

  love.graphics.setColor((c/2):rgb())
  love.graphics.rectangle('fill',self.x+self.bar_rect.x,self.y+self.bar_rect.y,self.bar_rect.w,self.bar_rect.h)

  love.graphics.setColor(c:rgb())
  local kx,ky = self:knob_location()
  love.graphics.circle('fill', kx, ky, 10)

  if self.hover and self.state~='disabled' then
    love.graphics.setLineWidth(5)
    love.graphics.setColor((c/2):rgba(0.5))
    love.graphics.rectangle('line', self.x,self.y,self.w,self.h)
  end

  if self.hover then
    love.graphics.pop()
  end
end

--------------------------------------------------------------------------------

return UI

