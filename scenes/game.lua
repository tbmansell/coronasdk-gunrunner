local composer      = require("composer")
local physics       = require("physics")
local anim          = require("core.animations")
local particles     = require("core.particles")
local tileEngine    = require("core.tileEngine")
local cameraLoader  = require("core.camera")
local level         = require("core.level")
local hud           = require("core.hud")
local builder       = require("elements.builders.builder")
local playerBuilder = require("elements.builders.playerBuilder")

-- local variables for performance
local scene         = composer.newScene()


-- Aliases:
local math_abs   = math.abs
local math_round = math.round



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
    tileEngine:eventUpdateFrame(event, player.image)
    level:eventUpdateFrame(event)
    hud:eventUpdateFrame(event)
end


-- Called when the scene's view does not exist:
function scene:create(event)
    self:initPhysics()
    self:loadLevel()
    self:loadPlayer()
    self:loadInterface()
    self:createEventHandlers()
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


function scene:loadLevel()
    --camera = cameraLoader.createView()

    tileEngine:create(self.view, "images/tiles-extrude.png", player,  self:getEnvironment())

    level:new(tileEngine)
    level:createElements(self:getElements()) 
end


function scene:loadPlayer()
    player = level:createPlayer({xpos=globalCenterX, ypos=globalHeight-250})
    player:setWeapon(Weapons.rifle)
    
    -- Create Game Over callback
    player.failedCallback = function()
        scene:pauseLevel()
        globalGameMode = GameMode.over
        hud:displayMessage("game over man")
        sounds:general("gameOver")
        after(4000, function() composer.gotoScene("scenes.game", {effect="fade", time=3000}) end)
    end

    -- Create callback to update player health
    player.updateHudHealth = function()
        if player.health <= 0 then
            hud.healthCounter.alpha = 0
        else
            hud.healthCounter.width = hud.healthCounter.widthPerHealth * player.health
        end
    end
end


function scene:loadInterface()
    hud:create(tileEngine, player, scene.pauseLevel, scene.resumeLevel)
end


function scene:getEnvironment()
    return {
        {0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0},
        {0,0,5,6,0,0,0,0,3,0,0,0,0,0,0,0},
        {0,0,7,8,0,0,0,0,2,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,5,4,6,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,3,0,3,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,7,4,8,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
        
    }
end


function scene:getElements()
    return {
        --{object="enemy",  xpos=250, ypos=250, type="melee",   rank=1},
        --{object="enemy",  xpos=500, ypos=250, type="shooter", rank=1},
        --{object="enemy",  xpos=400, ypos=150, type="shooter", rank=2},
        --{object="enemy",  xpos=200, ypos=150, type="shooter", rank=3},
        --{object="wall",   xpos=450, ypos=600, type="blue",    rotation=90},
        --{object="weapon", xpos=250, ypos=300, type="launcher"},
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
    tileEngine:destroy()

    camera:destroy()
    cameraHolder, camera, player = nil, nil, nil

    player = nil
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