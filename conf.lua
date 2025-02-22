
function love.conf(t)
  t.gammacorrect = true
  t.identity = "usss-ohio"
  t.modules.audio = true 
  t.modules.font = true 
  t.modules.joystick = false 
  t.modules.physics = false 
  t.modules.sound = true 
  t.modules.touch = false 
  t.modules.video = false 
  t.version = "11.5"
  t.window.borderless = false
  t.window.display = 1
  t.window.fullscreen = false
  t.window.fullscreentype = 'desktop'
  t.window.height = 912
  t.window.icon = "art/icon.png"
  t.window.resizable = false
  t.window.title = "USSS Ohio"
  t.window.vsync = 1
  t.window.width = 1080
  t.window.x = 100
  t.window.y = 100
end

