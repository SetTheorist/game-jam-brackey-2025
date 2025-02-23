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
scene_credits = require "scene_credits"
scene_lose = require "scene_lose"
scene_play = require "scene_play"
scene_start = require "scene_start"
scene_win = require "scene_win"

VERSION = 1.0
FONTS = {}
AUDIO = {}
EVENT_MANAGER = nil
SCENE_MANAGER = nil

DEBUG_ENABLED = false
MUSIC_ENABLED = true

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
local function load_audio()
  AUDIO.applause = love.audio.newSource('audio/applause-sound-effect-240470.mp3', 'static')
  AUDIO.applause:setVolume(0.25)
  AUDIO.beeping = love.audio.newSource('audio/beeping-robot-or-machine-102595.mp3', 'static')
  AUDIO.beeping:setVolume(0.50)
  AUDIO.bleep = love.audio.newSource('audio/198414__divinux__infobleep.wav', 'static')
  AUDIO.breaking = love.audio.newSource('audio/breaking-glass-83809.mp3', 'static')
  AUDIO.click = love.audio.newSource('audio/click.wav', 'static')
  AUDIO.lasershot = love.audio.newSource('audio/131432__senitiel__lasershot.wav', 'static')
  AUDIO.shoot_plasma = love.audio.newSource('audio/sci-fi-weapon-shoot-firing-plasma-pp-05-233829.mp3', 'static')
  AUDIO.trombone = love.audio.newSource('audio/cartoon-trombone-sound-effect-241387.mp3', 'static')
  AUDIO.underwater_explosion = love.audio.newSource('audio/large-underwater-explosion-190270.mp3', 'static')
  AUDIO.wooden = love.audio.newSource('audio/321082__benjaminnelan__wooden-hover.wav', 'static')
  AUDIO.wooden:setVolume(0.50)

  AUDIO.cyberpunk = love.audio.newSource('audio/cyberpunk-beat-64649.mp3', 'stream')
  AUDIO.cyberpunk:setLooping(true)
  AUDIO.cyberpunk:setVolume(0.50)

  AUDIO.motivational = love.audio.newSource('audio/701089__universfield__motivational-day.mp3', 'stream')
  AUDIO.motivational:setLooping(true)
  AUDIO.motivational:setVolume(0.10)

  AUDIO.elevator = love.audio.newSource('audio/467240__jay_you__music-elevator-ext.wav', 'stream')
  AUDIO.elevator:setLooping(true)
  AUDIO.elevator:setVolume(0.25)

  AUDIO.crime = love.audio.newSource('audio/750627__nancy_sinclair__tense-crime-atmosphere-for-films-and-media.mp3', 'stream')
  AUDIO.crime:setLooping(true)
  AUDIO.crime:setVolume(0.50)

  AUDIO.hope = love.audio.newSource('audio/726343__denkyschuk__future-of-hope-bpm-85-loop.wav', 'stream')
  AUDIO.hope:setLooping(true)
  AUDIO.hope:setVolume(0.10)

  AUDIO.celestial = love.audio.newSource('audio/759643__nancy_sinclair__celestial-voices.mp3', 'stream')
  AUDIO.celestial:setLooping(true)
  AUDIO.celestial:setVolume(0.25)
end

--------------------------------------------------------------------------------
function love.load()
  collectgarbage('setpause',200)
  love.keyboard.setKeyRepeat(false)

  FONTS.torek_16 = love.graphics.newFont('font/ToreksRegular.otf',16,'light')
  FONTS.torek_42 = love.graphics.newFont('font/ToreksRegular.otf',42,'light')
  FONTS.malefissent_20 = love.graphics.newFont('font/PentaGrams Malefissent.ttf',20,'light')

  load_audio()
  load_images()

  EVENT_MANAGER = EventManager()

  SCENE_MANAGER = SceneManager({scene_start, scene_play, scene_win, scene_lose, scene_confirm, scene_credits})
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
  if key=='f12' then
    DEBUG_ENABLED = not DEBUG_ENABLED
  end
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

