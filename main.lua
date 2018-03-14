-- Define global constants & functions
require("constants.globals")

-- Global label used for buld version
globalBuildVersion     = "0.5"
globalDebugGame        = false
globalGameMode         = GameMode.loading
globalFPS              = 0
globalCenterX          = display.contentCenterX
globalCenterY          = display.contentCenterY
globalWidth            = display.contentWidth
globalHeight           = display.contentHeight
globalTop              = -((display.actualContentHeight - display.contentHeight) / 2)
globalBottom           = globalHeight + ((display.actualContentHeight - display.contentHeight) / 2)
globalBackgroundWidth  = 640
globalBackgroundHeight = 1300
globalCamera           = nil
globalMaxSections      = 51
globalLoadSections     = 10
globalLoadingDisplay   = nil

--print("ContentWidth: "..display.contentWidth.." ContentHeight: "..display.contentHeight.." ratio: "..(display.contentWidth / display.contentHeight))
--print("PixelWidth:   "..display.pixelWidth.." PixelHeight:   "..display.pixelHeight.." ratio: "..(display.pixelWidth / display.pixelHeight))
--print("ActualWidth:  "..display.actualContentWidth.." ActualHeight:  "..display.actualContentHeight.." ratio: "..(display.actualContentWidth / display.actualContentHeight))
--print("Width  diff: "..(display.contentWidth  / display.pixelWidth))
--print("Height diff: "..(display.contentHeight / display.pixelHeight))

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
