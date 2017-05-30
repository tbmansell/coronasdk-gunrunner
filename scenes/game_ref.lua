local composer      = require("composer")
local physics       = require("physics")
local TileEngine    = require("plugin.wattageTileEngine")
local spriteSheetInfo = require("core.tiles")
local anim          = require("core.animations")
local particles     = require("core.particles")
--local cameraLoader  = require("core.camera")
local level         = require("core.level")
local hud           = require("core.hud")
local builder       = require("elements.builders.builder")
local playerBuilder = require("elements.builders.playerBuilder")

-- local variables for performance
local scene         = composer.newScene()
local player        = nil
local tileEngine    = nil
local viewControl   = nil
local lightingModel = nil
local spriteSheet   = nil
local spriteResolver = {}
local stateMachine  = {}
local lineOfSightModel
--local camera        = nil
local lastTime      = 0
local cameraDirection = "right"           -- Tracks the direction of the camera
local topLightId
local bottomLightId                         -- Will track the ID of the bottom light
local leftLightId                           -- Will track the ID of the left light
local rightLightId
local movingLightId                         -- Will track the ID of the moving light
local movingLightDirection                  -- Tracks the direction of the moving light
local movingLightXPos                       -- Tracks the continous position of the moving light
local entityId                              -- Will track the ID of the entity
local entityDirection = "down"              -- Tracks the direction of the moving entity
local entityLayer                           -- Reference to the entity layer
local playerTokenId 

--[[
local ENVIRONMENT = {
    {2,2,2,2,2,1,1,1,1,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {1,1,1,1,1,1,0,0,0,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,0,0,0,1,1,1,1,1,1},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,0,0,0,1,2,2,2,2,2},
    {2,2,2,2,2,1,1,1,1,1,2,2,2,2,2},
}]]
local ENVIRONMENT = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,1,1,0,0,0,1,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

local ROW_COUNT         = #ENVIRONMENT      -- Row count of the environment
local COLUMN_COUNT      = #ENVIRONMENT[1]   -- Column count of the environment
local CAMERA_SPEED      = 4 / 1000          -- Camera speed, 4 tiles per second
local WALL_LAYER_COUNT  = 4                 -- The number of extruded wall layers
local SCALING_DELTA     = 0.04              -- The scaling delta between wall layers
local MOVING_LIGHT_SPEED= 4 / 1000
local ENTITY_SPEED      = 4 / 1000          -- Speed of the entity, 4 tiles per second

-- Aliases:
local math_abs   = math.abs
local math_round = math.round


------------------------- TILE ENGINE FUNCTIONS --------------------------------

local function addFloorToLayer(layer)
    for row=1,ROW_COUNT do
        for col=1,COLUMN_COUNT do
            local value = ENVIRONMENT[row][col]
            if value == 0 then
                layer.updateTile(
                    row,
                    col,
                    TileEngine.Tile.new({
                        resourceKey="tiles_0"
                    })
                )
            elseif value == 1 then
                layer.updateTile(
                    row,
                    col,
                    TileEngine.Tile.new({
                        resourceKey="tiles_1"
                    })
                )
            end
        end
    end
end


local function addWallsToLayer(layer)
    for row=1,ROW_COUNT do
        for col=1,COLUMN_COUNT do
            local value = ENVIRONMENT[row][col]
            if value == 1 then
                layer.updateTile(
                    row,
                    col,
                    TileEngine.Tile.new({
                        resourceKey="tiles_1"
                    }))
            end
        end
    end
end


local function isTileTransparent(column, row)
    local rowTable = ENVIRONMENT[row]
    if rowTable == nil then
        return true
    end
    local value = rowTable[column]
    return value == nil or value == 0
end


local function allTilesAffectedByAmbient(row, column)
    return true
end


--[[
stateMachine.init = function()
    -- Set initial state
    stateMachine.curState = 1

    -- Add a light at the top part of the room.
    topLightId = lightingModel.addLight({
        row=5,column=8,r=1,g=1,b=0.7,intensity=0.75,radius=9
    })

    -- Set the initial position and direction of the moving light
    movingLightDirection = "left"
    movingLightXPos = 14.5
end

stateMachine.nextState = function()
    stateMachine.curState = stateMachine.curState + 1
    if stateMachine.curState > 5 then
        stateMachine.curState = 1
    end

    if stateMachine.curState == 1 then
        lightingModel.removeLight(movingLightId)
        movingLightId = nil
        topLightId = lightingModel.addLight({
            row=5,column=8,r=1,g=1,b=0.7,intensity=0.75,radius=9
        })
        lightingModel.setUseTransitioners(false)
    end

    if stateMachine.curState == 2 then
        lightingModel.removeLight(topLightId)
        topLightId = nil
        rightLightId = lightingModel.addLight({
            row=8,column=11,r=0,g=0,b=1,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 3 then
        lightingModel.removeLight(rightLightId)
        rightLightId = nil
        bottomLightId = lightingModel.addLight({
            row=11,column=8,r=0,g=1,b=0,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 4 then
        lightingModel.removeLight(bottomLightId)
        bottomLightId = nil
        leftLightId = lightingModel.addLight({
            row=8,column=5,r=1,g=0,b=0,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 5 then
        lightingModel.removeLight(leftLightId)
        leftLightId = nil
        movingLightId = lightingModel.addLight({
            row=8,
            column=math.floor(movingLightXPos + 0.5),
            r=1,g=1,b=0.7,intensity=0.75,radius=9
        })
        lightingModel.setUseTransitioners(true)
    end
end

stateMachine.update = function(deltaTime)
    local xDelta = MOVING_LIGHT_SPEED * deltaTime
    if movingLightDirection == "right" then
        movingLightXPos = movingLightXPos + xDelta
        if movingLightXPos > 14.5 then
            movingLightDirection = "left"
            movingLightXPos = 14.5 - (movingLightXPos - 14.5)
        end
    else
        movingLightXPos = movingLightXPos - xDelta
        if movingLightXPos < 0.5 then
            movingLightDirection = "right"
            movingLightXPos = 0.5 + (0.5 - movingLightXPos)
        end
    end
    if movingLightId ~= nil then
        lightingModel.updateLight({
            lightId = movingLightId,
            newRow = 8,
            newColumn = math.floor(movingLightXPos + 0.5)
        })
    end
end
]]

stateMachine.init = function()
    -- Set initial state
    stateMachine.curState = 0

    -- Set the initial position and direction of the moving light
    movingLightDirection = "right"
    movingLightXPos = 1.5

    -- Set up for state 0
    movingLightId = lightingModel.addLight({
        row=8,
        column=math.floor(movingLightXPos + 0.5),
        r=1,g=1,b=0.7,intensity=0.75,radius=9
    })
    lightingModel.setUseTransitioners(true)
    lightingModel.setAmbientLight(1,1,1,0.15)
end
stateMachine.update = function(deltaTime)
    local xDelta = MOVING_LIGHT_SPEED * deltaTime
    if movingLightDirection == "right" then
        movingLightXPos = movingLightXPos + xDelta
        if movingLightXPos > 13.5 then
            movingLightDirection = "left"
            movingLightXPos = 13.5 - (movingLightXPos - 13.5)
        end
    else
        movingLightXPos = movingLightXPos - xDelta
        if movingLightXPos < 1.5 then
            movingLightDirection = "right"
            movingLightXPos = 1.5 + (1.5 - movingLightXPos)
        end
    end
    if movingLightId ~= nil then
        lightingModel.updateLight({
            lightId = movingLightId,
            newRow = 8,
            newColumn = math.floor(movingLightXPos + 0.5)
        })
    end
end
stateMachine.nextState = function()
    stateMachine.curState = stateMachine.curState + 1
    if stateMachine.curState > 5 then
        stateMachine.curState = 0
    end

    if stateMachine.curState == 0 then
        movingLightId = lightingModel.addLight({
            row=8,
            column=math.floor(movingLightXPos + 0.5),
            r=1,g=1,b=0.7,intensity=0.75,radius=9
        })
        lightingModel.setUseTransitioners(true)
        lightingModel.setAmbientLight(1,1,1,0.15)
    end

    if stateMachine.curState == 1 then
        lightingModel.removeLight(movingLightId)
        movingLightId = nil
        topLightId = lightingModel.addLight({
            row=5,column=8,r=1,g=1,b=0.7,intensity=0.75,radius=9
        })
        lightingModel.setUseTransitioners(false)
    end

    if stateMachine.curState == 2 then
        lightingModel.removeLight(topLightId)
        topLightId = nil
        rightLightId = lightingModel.addLight({
            row=8,column=11,r=0,g=0,b=1,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 3 then
        lightingModel.removeLight(rightLightId)
        rightLightId = nil
        bottomLightId = lightingModel.addLight({
            row=11,column=8,r=0,g=1,b=0,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 4 then
        lightingModel.removeLight(bottomLightId)
        bottomLightId = nil
        leftLightId = lightingModel.addLight({
            row=8,column=5,r=1,g=0,b=0,intensity=0.75,radius=9
        })
    end

    if stateMachine.curState == 5 then
        lightingModel.removeLight(leftLightId)
        leftLightId = nil
        lightingModel.setAmbientLight(1,1,1,0.75)
    end
end


local function onFrame(event)
    local camera        = viewControl.getCamera()
    local lightingModel = tileEngine.getActiveModule().lightingModel

    if lastTime ~= 0 then
        -- Determine the amount of time that has passed since the last frame and
        -- record the current time in the lastTime variable to be used in the next
        -- frame.
        local curTime   = event.time
        local deltaTime = curTime - lastTime
        lastTime = curTime

        -- Update the state machine
        stateMachine.update(deltaTime)

        --[[
        -- Update the position of the camera
        local curXPos = camera.getX()
        local xDelta = CAMERA_SPEED * deltaTime
        if cameraDirection == "right" then
            curXPos = curXPos + xDelta
            if curXPos > 14.5 then
                cameraDirection = "left"
                curXPos = 14.5 - (curXPos - 14.5)
            end
        else
            curXPos = curXPos - xDelta
            if curXPos < 0.5 then
                cameraDirection = "right"
                curXPos = 0.5 + (0.5 - curXPos)
            end
        end
        camera.setLocation(curXPos, camera.getY())
        ]]
        -- Update the position of the camera
        local curXPos = camera.getX()
        local xDelta = CAMERA_SPEED * deltaTime
        if cameraDirection == "right" then
            curXPos = curXPos + xDelta
            if curXPos > 13.5 then
                cameraDirection = "left"
                curXPos = 13.5 - (curXPos - 13.5)
            end
        else
            curXPos = curXPos - xDelta
            if curXPos < 1.5 then
                cameraDirection = "right"
                curXPos = 1.5 + (1.5 - curXPos)
            end
        end
        camera.setLocation(curXPos, camera.getY())


        -- Update the line of sight model passing the row and column for the current
        -- point of view nad the amount of time that has passed
        -- since the last frame.
        lineOfSightModel.update(8, math.floor(curXPos + 0.5), deltaTime)

        -- Update the lighting model passing the amount of time that has passed since
        -- the last frame.
        lightingModel.update(deltaTime)


        -- Update the position of the entity
        local entityRow, entityCol = entityLayer.getEntityTilePosition(entityId)
        local yDelta = ENTITY_SPEED * deltaTime
        if entityDirection == "down" then
            entityRow = entityRow + yDelta
            if entityRow > 12.5 then
                entityDirection = "up"
                entityRow = 12.5 - (entityRow - 12.5)
            end
        else
            entityRow = entityRow - yDelta
            if entityRow < 2.5 then
                entityDirection = "down"
                entityRow = 2.5 + (2.5 - entityRow)
            end
        end
        entityLayer.setEntityTilePosition(entityId, entityRow, entityCol)

        -- Set the entity position
        entityLayer.setEntityTilePosition(playerTokenId, camera.getY(), curXPos)

        -- The line of sight model also tracks changes to the player position.
        -- It is necessary to reset the change tracking to provide a clean
        -- slate for the next frame.
        lineOfSightModel.resetDirtyFlags()

    else
        -- This is the first call to onFrame, so lastTime needs to be initialized.
        lastTime = event.time

        -- This is the initial position of the camera
        --camera.setLocation(7.5, 7.5)
        --camera.setLocation(0.5, 7.5)
        camera.setLocation(1.5, 7.5)
        
        -- Since a time delta cannot be calculated on the first frame, 1 is passed
        -- in here as a placeholder.
        lightingModel.update(1)

        -- Set the initial position of the entity
        entityLayer.centerEntityOnTile(entityId, 3, 8)

        -- Set the initial position of the player token
        entityLayer.centerEntityOnTile(playerTokenId, 8, 2)

        -- Set the initial position of the player to match the
        -- position of the camera.  Pass in a time delta of 1 since this is
        -- the first frame.
        lineOfSightModel.update(8, 3, 1)
    end

    -- Render the tiles visible to the passed in camera.
    tileEngine.render(camera)

    -- The lighting model tracks changes, then acts on all accumulated changes in
    -- the lightingModel.update() function.  This call resets the change tracking
    -- and must be called after lightingModel.update().
    lightingModel.resetDirtyFlags()
end


local function tapListener()
    stateMachine.nextState()
end


--------------------------------------------------------------------------------


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


--[[local function eventUpdateFrame(event)
    level:eventUpdateFrame(event)
    hud:eventUpdateFrame(event)
end]]


-- Called when the scene's view does not exist:
function scene:create(event)
    scene:initTileEngine()
    --scene:initPhysics()
    --scene:loadGame()
    scene:createEventHandlers()
    --particles:preLoadEmitters()

    -- these top and bottom borders ensure that devices where the length is greater than 960 (ipad retina) the game doesnt show under or above the background size limits
    local topBorder = display.newRect(globalCenterX, -50, globalWidth, 100)
    local botBorder = display.newRect(globalCenterX, globalHeight+50, globalWidth, 100)
    topBorder:setFillColor(0,0,0)
    botBorder:setFillColor(0,0,0)

    --self:startLevelSequence()
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


function scene:initTileEngine()
    local tileEngineLayer = display.newGroup()

    spriteSheet = graphics.newImageSheet("images/tiles.png", spriteSheetInfo:getSheet())

    spriteResolver.resolveForKey = function(key)
        local frameIndex    = spriteSheetInfo:getFrameIndex(key)
        local frame         = spriteSheetInfo.sheet.frames[frameIndex]
        local displayObject = display.newImageRect(spriteSheet, frameIndex, frame.width, frame.height)
        
        return TileEngine.SpriteInfo.new({
            imageRect = displayObject,
            width = frame.width,
            height = frame.height
        })
    end

    tileEngine = TileEngine.Engine.new({
        parentGroup                          = tileEngineLayer,
        tileSize                             = 50,
        spriteResolver                       = spriteResolver,
        compensateLightingForViewingPosition = true,
        hideOutOfSightElements               = true
    })

    lightingModel = TileEngine.LightingModel.new({
        isTransparent                        = isTileTransparent,
        isTileAffectedByAmbient              = allTilesAffectedByAmbient,
        useTransitioners                     = false,
        compensateLightingForViewingPosition = true
    })

    -- An instance of LineOfSightModel is created for the module to
    -- track which tiles are visible.
    --local lineOfSightModel = TileEngine.LineOfSightModel.new({
    lineOfSightModel = TileEngine.LineOfSightModel.new({
        radius = 20,
        isTransparent = isTileTransparent
    })

    lineOfSightModel.setTransitionTime(225)

    local module = TileEngine.Module.new({
        name            = "moduleMain",
        rows            = ROW_COUNT,
        columns         = COLUMN_COUNT,
        lightingModel   = lightingModel,
        losModel        = lineOfSightModel --TileEngine.LineOfSightModel.ALL_VISIBLE
    })

    local floorLayer = TileEngine.TileLayer.new({
        rows    = ROW_COUNT,
        columns = COLUMN_COUNT
    })

    addFloorToLayer(floorLayer)
    
    floorLayer.resetDirtyTileCollection()
    
    module.insertLayerAtIndex(floorLayer, 1, 0)
    
    tileEngine.addModule({module = module})

    tileEngine.setActiveModule({
        moduleName = "moduleMain"
    })

    viewControl = TileEngine.ViewControl.new({
        parentGroup         = self.view,
        centerX             = globalCenterX,
        centerY             = globalCenterY,
        pixelWidth          = display.actualContentWidth,
        pixelHeight         = display.actualContentHeight,
        tileEngineInstance  = tileEngine
    })

    lightingModel.setAmbientLight(1,1,1,0.7)

    -- Create extruded wall layers
    for i=1,WALL_LAYER_COUNT do
        local wallLayer = TileEngine.TileLayer.new({
            rows = ROW_COUNT,
            columns = COLUMN_COUNT
        })
        addWallsToLayer(wallLayer)
        wallLayer.resetDirtyTileCollection()
        module.insertLayerAtIndex(wallLayer, i + 1, SCALING_DELTA)
    end

    -- Add a light at the top part of the room.
    topLightId = lightingModel.addLight({
        row=5,column=8,r=1,g=1,b=0.7,intensity=0.75,radius=9
    })

    -- Finally, set the ambient light to white light with medium-high intensity.
    lightingModel.setAmbientLight(1,1,1,0.15)

    stateMachine.init()

    entityLayer = TileEngine.EntityLayer.new({
        tileSize = 32,
        spriteResolver = spriteResolver
    })
    module.insertLayerAtIndex(entityLayer, 2, 0)
    entityId = entityLayer.addEntity("tiles_2")

    playerTokenId = entityLayer.addEntity("tiles_3")
end


function scene:initPhysics()
    physics.start(false)
    physics.pause()
    physics.setDebugErrorsEnabled()
    physics.setTimeStep(1/display.fps)
    physics.setGravity(0, 0)
end


function scene:loadGame()
    --camera = cameraLoader.createView()

    display.newImage(self.view, "images/backgrounds/canyon.jpg", globalCenterX, globalCenterY)

    level:new(camera)
    level:createElements(self:getElements())

    camera:setParallax(1.1, 1, 1, 1, 0.2, 0.15, 0.1, 0.05)
    --camera:setBounds(-300, level.endXPos, level.data.floor+100, level.data.ceiling)
    camera:setBounds(0, globalWidth, 0, globalHeight)
    camera:setFocusOffset(0, 0)

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
    
    hud:create(camera, player, scene.pauseLevel, scene.resumeLevel)
end


function scene:getElements()
    return {
        {object="enemy",  xpos=250, ypos=250, type="melee",   rank=1},
        {object="enemy",  xpos=500, ypos=250, type="shooter", rank=1},
        {object="enemy",  xpos=400, ypos=150, type="shooter", rank=2},
        {object="enemy",  xpos=200, ypos=150, type="shooter", rank=3},
        {object="wall",   xpos=450, ypos=600, type="blue",    rotation=90},
        {object="weapon", xpos=250, ypos=300, type="launcher"},
    }
end


function scene:createEventHandlers()
    Runtime:addEventListener("enterFrame", onFrame)
    Runtime:addEventListener("tap", tapListener)

    --Runtime:addEventListener("enterFrame", eventUpdateFrame)
    --scene.gameLoopHandle = timer.performWithDelay(250, level.updateBehaviours, 0)
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
    camera:track()
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

    tileEngine.destroy()
    tileEngineViewControl.destroy()
    tileEngine, tileEngineViewControl, lightingModel = nil, nil, nil

    physics.stop()
    anim:destroy()
    particles:destroy()
    level:destroy()
    hud:destroy()

    --camera:destroy()
    --cameraHolder, camera, player = nil, nil, nil

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