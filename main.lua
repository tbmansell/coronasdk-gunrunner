-- Define global constants & functions
require("constants.globals")

-- Global label used for buld version
globalBuildVersion     = "0.1"
globalDebugGame        = true
globalGameMode         = GameMode.loading
globalFPS              = 0
globalCenterX          = display.contentCenterX
globalCenterY          = display.contentCenterY
globalWidth            = display.contentWidth
globalHeight           = display.contentHeight
globalBackgroundWidth  = 640
globalBackgroundHeight = 1300

-- Define global objects
track  = require("core.track")
draw   = require("core.draw")
sounds = require("core.sounds")

-- Generate the random number seed
math.randomseed(os.time())
-- activate multitouch
system.activate("multitouch")

-- turn off phone display status
display.setStatusBar(display.HiddenStatusBar)
-- load sounds
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
