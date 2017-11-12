-- Define global constants & functions
require("constants.globals")

-- Global label used for buld version
globalBuildVersion     = "0.4"
globalDebugGame        = false
globalGameMode         = GameMode.loading
globalFPS              = 0
globalCenterX          = display.contentCenterX
globalCenterY          = display.contentCenterY
globalWidth            = display.contentWidth
globalHeight           = display.contentHeight
globalBackgroundWidth  = 640
globalBackgroundHeight = 1300
globalCamera           = nil

-- Define global objects
stats   = require("core.stats")
track   = require("core.track")
draw    = require("core.draw")
sounds  = require("core.sounds")
level   = require("core.level")
builder = require("elements.builders.builder")

math.randomseed(os.time())
system.activate("multitouch")
display.setStatusBar(display.HiddenStatusBar)
sounds:preload()

-- Global debug game logic
if globalDebugGame then
    timer.performWithDelay(1000, draw.displayPerformance, 0)
end

-- for debug spacing
print("")

-- Fire off the start scene
local composer = require("composer")
composer.gotoScene("scenes.game")
--composer:gotoScene("scenes.tiles-grid")
