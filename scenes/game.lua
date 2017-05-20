local composer      = require("composer")
local physics       = require("physics")
local anim          = require("core.animations")
local particles     = require("core.particles")
local cameraLoader  = require("core.camera")
local level         = require("core.level")
local hud           = require("core.hud")
local builder       = require("elements.builders.builder")
local playerBuilder = require("elements.builders.player-builder")

-- local variables for performance
local scene  = composer.newScene()
local player = nil
local camera = nil

-- Aliases:
local math_abs   = math.abs
local math_round = math.round

-- Local Event Handlers

-- Treat phone back button same as back game button
local function sceneKeyEvent(event)
    if event.keyName == "back" and event.phase == "up" then
        if hud and hud.eventPauseGame then
            if globalGameMode == GameMode.paused then
                hud:eventResumeGame()
            else
                hud:eventPauseGame()
            end
        end
        return true
    end
end


local function eventUpdateFrame(event)
    level:eventUpdateFrame(event)
    hud:eventUpdateFrame(event)
end


-- Called when the scene's view does not exist:
function scene:create(event)
    scene:initPhysics()
    scene:loadGame()
    scene:createEventHandlers()
    particles:preLoadEmitters()

    -- these top and bottom borders ensure that devices where the length is greater than 960 (ipad retina) the game doesnt show under or above the background size limits
    local topBorder = display.newRect(globalCenterX, -50, globalWidth, 100)
    local botBorder = display.newRect(globalCenterX, globalHeight+50, globalWidth, 100)
    topBorder:setFillColor(0,0,0)
    botBorder:setFillColor(0,0,0)

    self:startLevelSequence()
end


-- Called immediately after scene has moved onscreen:
function scene:show(event)
    globalGameMode = GameMode.loading

    if event.phase == "did" then
        draw:clearSceneTransition()
    end
end


-- Called when scene is about to move offscreen:
function scene:hide(event)
    if event.phase == "will" then
        self:unloadLevel()
    elseif event.phase == "did" then
        composer.removeScene("scenes.game", true)
    end
end


function scene:initPhysics()
    physics.start(false)
    physics.pause()
    physics.setDebugErrorsEnabled()
    physics.setTimeStep(1/display.fps)
    physics.setGravity(0, 0)
end


function scene:loadGame()
    camera = cameraLoader.createView()

    display.newImage(self.view, "images/backgrounds/canyon.jpg", globalCenterX, globalCenterY)

    level:new(camera)
    level:createElements(self:getElements())

    camera:setParallax(1.1, 1, 1, 1, 0.2, 0.15, 0.1, 0.05)
    --camera:setBounds(-300, level.endXPos, level.data.floor+100, level.data.ceiling)
    camera:setBounds(0, globalWidth, 0, globalHeight)
    camera:setFocusOffset(0, 0)

    player = level:createPlayer({xpos=globalCenterX, ypos=globalHeight-250})
    player:setWeapon(Weapons.rifle)
    
    player.failedCallback = function()
        scene:pauseLevel()
        globalGameMode = GameMode.over
        hud:displayMessage("game over man")
        after(4000, function() composer.gotoScene("scenes.game", {effect="fade", time=3000}) end)
    end

    player.updateHudHealth = function()
        if player.health <= 0 then
            hud.healthCounter.alpha = 0
        else
            hud.healthCounter.width = hud.healthCounter.widthPerHealth * player.health
        end
    end
    
    hud:create(camera, player, scene.pauseLevel, scene.resumeLevel)
end


function scene:getElements()
    return {
        {object="enemy", xpos=250, ypos=250, weapon=Weapons.rifle, angle=180, aggression=70},
        {object="enemy", xpos=500, ypos=250, weapon=Weapons.rifle, angle=180, aggression=30},
    }
end


function scene:createEventHandlers()
    Runtime:addEventListener("enterFrame", eventUpdateFrame)

    scene.gameLoopHandle = timer.performWithDelay(250, level.updateBehaviours, 0)
end


function scene:startLevelSequence()
    globalGameMode = GameMode.started

    hud:startLevelSequence(level, player)
    player:startLevelSequence()

    after(2000, function() scene:startPlaying() end)
end


function scene:startPlaying(player)
    math.randomseed(os.time())

    globalGameMode = GameMode.playing

    physics:start()
    --camera:track()
end


function scene:pauseLevel()
    globalGameMode = GameMode.paused

    Runtime:removeEventListener("enterFrame", eventUpdateFrame)

    track:pauseEventHandles()
    level:pauseElements()

    physics:pause()
    anim:pause()
    particles:pause()
end


function scene:resumeLevel(resumeGameState)
    globalGameMode = resumeGameState or GameMode.playing
    Runtime:addEventListener("enterFrame", eventUpdateFrame)

    particles:resume()
    anim:resume()
    physics:start()

    level:resumeElements()
    track:resumeEventHandles()
end



function scene:unloadLevel()
    Runtime:removeEventListener("enterFrame", eventUpdateFrame)

    timer.cancel(scene.gameLoopHandle)
    track:cancelEventHandles()

    physics.stop()
    anim:destroy()
    particles:destroy()
    level:destroy()
    hud:destroy()
    camera:destroy()

    cameraHolder, camera, player = nil, nil, nil
    collectgarbage("collect")
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroy(event)
end


---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene