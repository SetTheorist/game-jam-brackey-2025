class = require "middleclass"
pq = require "pq"
EventManager = require "event"
Anim = require "anim"
Scene = require "scene"
SceneManager = require "scene_manager"

images = require "images"
level = require "level"
action = require "action"
device = require "device"
ship = require "ship"
crew = require "crew"
display = require "display"
progress = require "progress"

scene_confirm = require "scene_confirm"
scene_lose = require "scene_lose"
scene_play = require "scene_play"
scene_start = require "scene_start"
scene_win = require "scene_win"

VERSION = 1.0
FONTS = {}
AUDIO = {}
EVENT_MANAGER = nil
SCENE_MANAGER = nil


-- TODO: make these adjustable in-game...
-- (game difficulties: decay factor, crew speed factors)
GLOBAL_DECAY_FACTOR = 1.0
AUTO_REPAIR_THRESHOLD = 0.01

--------------------------------------------------------------------------------

-- compacts all entries 1..n removing nils, returns count of non-nil entries
function compact(arr,n)
  local t=0
  for i=1,n do
    if arr[i]~=nil then
      t = t+1
      if t ~= i then
        arr[t],arr[i] = arr[i],nil
      end
    end
  end
  return t
end

--------------------------------------------------------------------------------
--love.keyboard.getKeyFromScancode('w')
--love.window.setMode(1024, 768, {resizable=false, centered=true, fullscreen=true})
function love.load()
  collectgarbage('setpause',200)
  love.keyboard.setKeyRepeat(false)

  FONTS.torek_16 = love.graphics.newFont('font/ToreksRegular.otf',16,'light')
  FONTS.torek_42 = love.graphics.newFont('font/ToreksRegular.otf',42,'light')
  FONTS.malefissent_20 = love.graphics.newFont('font/PentaGrams Malefissent.ttf',20,'light')

  AUDIO.click = love.audio.newSource('audio/click.wav', 'static')
  AUDIO.trombone = love.audio.newSource('audio/cartoon-trombone-sound-effect-241387.mp3', 'static')
  AUDIO.motivational = love.audio.newSource('audio/701089__universfield__motivational-day.mp3', 'stream')
  AUDIO.motivational:setLooping(true)
  AUDIO.motivational:setVolume(0.25)

  load_images()

  EVENT_MANAGER = EventManager()

  SCENE_MANAGER = SceneManager({scene_start, scene_play, scene_win, scene_lose, scene_confirm})
  SCENE_MANAGER:load()
  SCENE_MANAGER:set('start')
end

--------------------------------------------------------------------------------
function love.quit()
  return SCENE_MANAGER:quit()
end

--------------------------------------------------------------------------------
function love.mousepressed(x,y,button,istouch,presses)
  SCENE_MANAGER:mousepressed(x,y,button,istouch,presses)
end

--------------------------------------------------------------------------------
function love.mousereleased(x,y,button,istouch,presses)
  SCENE_MANAGER:mousereleased(x,y,button,istouch,presses)
end

--------------------------------------------------------------------------------
function love.mousemoved(x,y,dx,dy,istouch)
  SCENE_MANAGER:mousemoved(x,y,dx,dy,istouch)
end

--------------------------------------------------------------------------------
function love.wheelmoved(x,y,button)
  SCENE_MANAGER:wheelmoved(x,y,button)
end

--------------------------------------------------------------------------------
function love.keypressed(key,scancode,isrepeat)
  SCENE_MANAGER:keypressed(key,scancode,isrepeat)
end

function love.keyreleased(key,scancode)
  SCENE_MANAGER:keyreleased(key,scancode)
end

--------------------------------------------------------------------------------
function love.update(dt)
  SCENE_MANAGER:update(dt)
end

--------------------------------------------------------------------------------
function love.draw()
  love.graphics.reset()
  love.graphics.setLineStyle('rough')
  love.graphics.setDefaultFilter('nearest', 'nearest')
  SCENE_MANAGER:draw()
end

--------------------------------------------------------------------------------

