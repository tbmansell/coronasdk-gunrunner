local composer       = require("composer")
local physics        = require("physics")
local tileEngine     = require("engines.duskWrapper")
local anim           = require("core.animations")
local particles      = require("core.particles")
local levelGenerator = require("core.levelGenerator")
local hud            = require("core.hud")

-- local variables for performance
local scene = composer.newScene()

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
    tileEngine.map.updateView()
    level:eventUpdateFrame(event)
    hud:eventUpdateFrame(event)
end


local function eventUpdateGameLogic()
    player.currentSection = levelGenerator:getSection(player:y())

    level:updateBehaviours()

    if globalDebugGame then
        hud:updateDebugData()
    end
end


-- Called when the scene's view does not exist:
function scene:create(event)
    self:initPhysics()
    self:loadLevel()
    self:loadPlayer()
    self:loadInterface()
    --self:createEventHandlers()
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
    local bgr = display.newImage(self.view, "images/background2.jpg", globalCenterX, globalCenterY)
    bgr:scale(2,2)

    local sections    = 10
    local environment = {}
    local entities    = {}

    -- Build up tile engine
    tileEngine:init("images/tiles.png")
    levelGenerator:setup()
    level:new(tileEngine)

    -- generate the level content
    for i=1,sections do
        local env = levelGenerator:newEnvironment()

        environment[#environment+1] = env
        entities[#entities+1]       = levelGenerator:fillEnvironment()

        if not env.ownMap then
            levelGenerator:setEnvironmentFloor(env)
        end
    end

    -- tile engine renders sections in reverse, so feed them in backward
    for i=sections, 1, -1 do
        tileEngine:loadEnvironment(environment[i])
    end

    -- Create the tile map
    tileEngine:buildLayers()

    -- Build entities into the level
    for i=1, sections do
        level:createElements(entities[i])
    end
end


function scene:loadPlayer()
    player = level:createPlayer({xpos=9.5, ypos=-5.5}, hud)
    --player = level:createPlayer({xpos=12.5, ypos=-1.5}, hud)
    player:setWeapon(Weapons.rifle)
    
    -- Create Game Over callback
    player.failedCallback = function()
        after(2000, function()
            scene:pauseLevel()
            sounds:general("gameOver")

            globalGameMode = GameMode.over
            hud:displayGameOver()
        end)
    end

    function player:addPoints(points)
        stats:addPoints(points)
        hud:updatePoints()
    end
end


function scene:loadInterface()
    hud:create(tileEngine, player, scene.pauseLevel, scene.resumeLevel)
end


function scene:createEventHandlers()
    Runtime:addEventListener("enterFrame", eventUpdateFrame)
    scene.gameLoopHandle = timer.performWithDelay(250, eventUpdateGameLogic, 0)
end


function scene:startLevelSequence()
    globalGameMode = GameMode.started

    self:startMusic()
    hud:startLevelSequence(level, player)
    player:startLevelSequence()

    after(500, function() scene:startPlaying() end)
end


function scene:startMusic()
    self.musicChannel = audio.findFreeChannel()
    sounds:play(sounds.music.cyborgNinja, {channel=self.musicChannel, volume=0.3, fadein=8000, loops=-1})
end


function scene:pauseMusic()
    audio.pause(self.musicChannel)
end


function scene:resumeMusic()
    audio.resume(self.musicChannel)
end


function scene:endMusic()
    audio.fadeOut({channel=self.musicChannel, time=1000})
end


function scene:startPlaying()
    math.randomseed(os.time())

    globalGameMode = GameMode.playing

    stats:init(player:y())
    physics:start()
    -- runs the game loop and allows it to start. We allow some delay before this to allow everything to load
    self:createEventHandlers()
end


function scene:pauseLevel()
    globalGameMode = GameMode.paused

    Runtime:removeEventListener("enterFrame", eventUpdateFrame)

    scene:pauseMusic()
    track:pauseEventHandles()
    level:pauseElements()

    physics:pause()
    anim:pause()
    particles:pause()
end


function scene:resumeLevel(resumeGameState)
    globalGameMode = resumeGameState or GameMode.playing
    Runtime:addEventListener("enterFrame", eventUpdateFrame)

    scene:resumeMusic()
    particles:resume()
    anim:resume()
    physics:start()

    level:resumeElements()
    track:resumeEventHandles()
end


function scene:unloadLevel()
    Runtime:removeEventListener("enterFrame", eventUpdateFrame)

    self:endMusic()
    timer.cancel(scene.gameLoopHandle)
    track:cancelEventHandles()

    physics.stop()
    anim:destroy()
    particles:destroy()
    levelGenerator:destroy()
    level:destroy()
    hud:destroy()
    tileEngine:destroy()

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