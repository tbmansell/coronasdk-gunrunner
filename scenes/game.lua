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
    player.currentSection = levelGenerator:getSectionAtPosition(player:y())

    level:updateBehaviours()
    hud:updateMapSection()

    if globalDebugGame then
        hud:updateDebugData()
    end
end


-- Called when the scene's view does not exist:
function scene:create(event)
    draw:displayLoader()

    -- cerate delay to allow loader to display
    after(1, function()
        self:initPhysics()
        self:loadLevel()
        self:loadPlayer()
        self:loadInterface()
        particles:preLoadEmitters()

        self.musicChannel = 1

        draw:hideLoader()

        -- these top and bottom borders ensure that devices where the length is greater than 960 (ipad retina) the game doesnt show under or above the background size limits
        local topBorder = display.newRect(globalCenterX, -50, globalWidth, 100)
        local botBorder = display.newRect(globalCenterX, globalHeight+50, globalWidth, 100)
        topBorder:setFillColor(0,0,0)
        botBorder:setFillColor(0,0,0)

        self:startLevelSequence()
    end)
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
    local environment = {}
    local bgr         = display.newImage(self.view, "images/background.jpg", globalCenterX, globalCenterY)
    bgr:scale(2,2)
    
    -- Build up tile engine
    tileEngine:init("images/tiles.png")
    levelGenerator:setup()
    level:new(tileEngine)

    -- generate the level content
    for i=1, globalMaxSections do
        local isCustom = (i % globalLoadSections == 0)
        local isLast   = (i == globalMaxSections)
        local env      = levelGenerator:newEnvironment(isCustom, isLast)

        environment[#environment+1] = env
        levelGenerator:fillEnvironment()

        if not isCustom then
            levelGenerator:setEnvironmentFloor(env)
        end
    end

    -- tile engine renders sections in reverse, so feed them in backward
    for i=globalMaxSections, 1, -1 do
        tileEngine:loadEnvironment(environment[i])
    end

    -- Create the tile map
    tileEngine:buildLayers()
    --tileEngine.map.setCameraBounds({xMin=400, xMax=1200, yMin=false, yMax=false})
    tileEngine.map.setTrackingLevel(0.1)

    self:loadEntities(1)
end


function scene:loadEntities(fromSection)
    -- remove last batch of entities
    if fromSection > 1 then
        level:cullElements(fromSection-3)
    end

    -- generate next batch of entities
    local toSection = fromSection + globalLoadSections

    if toSection >= globalMaxSections then
        toSection = globalMaxSections
    end

    for i=fromSection, toSection do
        local section = levelGenerator:getSection(i)
        level:createElements(section.entities, levelGenerator)
    end
end


function scene:loadPlayer()
    player = level:createPlayer({xpos=11.5, ypos=-5.5}, hud)
    player:setWeapon(Weapons.laserGun)
    
    -- Create Game Over callbacks
    player.failedCallback = function()
        hud:forceMoving(false)

        after(2000, function(sound)
            scene:pauseLevel()
            sounds:voice("betterLuckNextTime")

            globalGameMode = GameMode.over
            hud:displayGameOver()
        end)
    end

    player.completedCallback = function()
        hud:forceMoving(false)

        after(2000, function(sound)
            scene:pauseLevel()
            sounds:general("mapComplete")

            globalGameMode = GameMode.over
            hud:displayGameOver(true)
        end)
    end

    function player:addPoints(points)
        stats:addPoints(points)
        hud:updatePoints()
    end
end


function scene:loadInterface()
    hud:create(tileEngine, player, scene.pauseLevel, scene.resumeLevel, scene.changeMusic, scene.loadEntities)
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
    audio.reserveChannels(self.musicChannel)
    sounds:play(sounds.music.rollingGame, {channel=self.musicChannel, volume=0.3, fadein=8000, loops=-1}, true)
end


function scene:changeMusic(newMusic, fadeIn)
    audio.fadeOut({channel=scene.musicChannel, time=1000})

    after(1100, function()
        sounds:play(newMusic, {channel=scene.musicChannel, volume=0.3, fadein=(fadeIn or 2000), loops=-1})
    end)
end


function scene:pauseMusic()
    audio.pause(self.musicChannel)
end


function scene:resumeMusic()
    audio.resume(self.musicChannel)
end


function scene:startPlaying()
    math.randomseed(os.time())

    globalGameMode = GameMode.playing

    stats:init(player:y())
    physics:start()
    -- runs the game loop and allows it to start. We allow some delay before this to allow everything to load
    self:createEventHandlers()

    sounds:voice("goodLuck")
end


function scene:pauseLevel()
    globalGameMode = GameMode.paused

    Runtime:removeEventListener("enterFrame", eventUpdateFrame)
    timer.pause(scene.gameLoopHandle)

    scene:pauseMusic()
    track:pauseEventHandles()
    level:pauseElements()
    player:pause()

    physics:pause()
    anim:pause()
    particles:pause()
end


function scene:resumeLevel(resumeGameState)
    globalGameMode = resumeGameState or GameMode.playing

    Runtime:addEventListener("enterFrame", eventUpdateFrame)
    timer.resume(scene.gameLoopHandle)

    scene:resumeMusic()
    particles:resume()
    anim:resume()
    physics:start()

    player:resume()
    level:resumeElements()
    track:resumeEventHandles()
end


function scene:unloadLevel()
    Runtime:removeEventListener("enterFrame", eventUpdateFrame)

    audio.stop()
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