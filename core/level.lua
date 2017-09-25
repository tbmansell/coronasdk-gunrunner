local anim      = require("core.animations")
local particles = require("core.particles")

-- Class
local Level = {}

-- Local vars (for this file only)
local FPS                   = display.fps
local lastTime              = 0
local camera                = nil
local mainPlayer            = nil
local spineCollection       = nil
local movingCollection      = nil
local enemyCollection       = nil
local particleCollection    = nil
local collectableCollection = nil
local obstacleCollection    = nil

-- Aliases
local random = math.random

-- Aliases to functions for enterframe event
local check_background_movement  = function()end
local check_spine_animation      = function()end
local check_moving_objects       = function()end


-- Useful for level generation debugging
local function debugPrint(orig)
    local orig_type = type(orig)
    local copy
    
    if orig_type == 'table' then
        copy = "{"
        for orig_key, orig_value in next, orig, nil do
            copy = copy..orig_key.."="..debugPrint(orig_value).." "
        end
        copy = copy.."}"
    elseif orig_type == 'string' then
        copy = "\""..orig.."\""
    else
        copy = tostring(orig)
    end
    return copy
end


function Level:new(cameraRef)
    -- create object collections:
    spineCollection       = builder:newSpineCollection()
    movingCollection      = builder:newMovementCollection()
    particleCollection    = builder:newParticleEmitterCollection()
    enemyCollection       = builder:newMasterCollection("enemySet",       spineCollection, movingCollection, particleCollection)
    collectableCollection = builder:newMasterCollection("collectableSet", spineCollection, movingCollection, particleCollection)
    obstacleCollection    = builder:newMasterCollection("obstacleSet",    spineCollection, movingCollection, particleCollection)

    -- local aliases:
    camera = cameraRef

    -- global reference for tricky cases where camera is not passed around
    globalCamera = cameraRef

    -- set level vars:
end


function Level:createEventHandlers()
    check_spine_animation     = spineCollection.animateEach
    check_moving_objects      = movingCollection.moveEach
    --check_background_movement = self.checkBackgroundMovement
end


function Level:destroy()
    spineCollection:destroy()
    movingCollection:destroy()
    particleCollection:destroy()
    enemyCollection:destroy()
    collectableCollection:destroy()
    obstacleCollection:destroy()

    spineCollection, movingCollection, particleCollection, enemyCollection, collectableCollection, obstacleCollection = nil, nil, nil, nil, nil, nil
    mainPlayer, camera = nil, nil
end


function Level:reset(player)
end


function Level:createElements(levelElements)
    self:createElementsFromData(levelElements)
    --self:createBackgrounds(camera)
    self:createEventHandlers()
end


function Level:appendElements(levelElements)
    return self:createElementsFromData(levelElements)
end


function Level:createElementsFromData(levelElements)
    for _,item in pairs(levelElements) do
        local object = item.object

        if     object == "enemy"    then self:createEnemy(item)
        elseif object == "weapon"   then self:createCollectable(item) 
        elseif object == "obstacle" then self:createObstacle(item)
        end
    end
end


function Level:createEnemy(item)
    local enemy = enemyBuilder:newEnemy(camera, item)

    enemyCollection:add(enemy)
end


function Level:createCollectable(item)
    local collectable = collectableBuilder:newItem(camera, item)

    collectableCollection:add(collectable)
end


function Level:createObstacle(item)
    -- 50% chance non rotated item will be randomly rotated
    if item.rotation == nil and random(100) < 50 then
        item.rotation = random(360)
    end

    local obstacle = obstacleBuilder:newItem(camera, item)

    obstacleCollection:add(obstacle)
end


function Level:createPlayer(item, hud)
    mainPlayer = playerBuilder:newPlayer(camera, item, hud)
    mainPlayer:visible()
    return mainPlayer
end


function Level:pauseElements()
end


function Level:resumeElements()
end


function Level:updateBehaviours()
    particleCollection:checkEach()
    enemyCollection:checkBehaviour(camera, mainPlayer)

    --[[
    -- Might as well be done here, as it's the only non-level thing needing updating
    soundEngine:updateSounds()
    ]]
end


function Level:eventUpdateFrame(event)
    globalFPS = globalFPS + 1

    -- Compute time in seconds since last frame.
    local currentTime = event.time / 1000  --(1000 / FPS)
    local delta       = currentTime - lastTime
    lastTime          = currentTime

    mainPlayer:updateSpine(delta)

    check_background_movement(delta)
    check_spine_animation(spineCollection, delta, true)
    check_moving_objects(movingCollection, delta, camera)
end


function Level:eventUpdateFrameFrozen(event)
    globalFPS = globalFPS + 1

    -- Compute time in seconds since last frame.
    local currentTime = event.time / (1000 / FPS)
    local delta       = currentTime - lastTime
    lastTime          = currentTime

    check_background_movement(delta)
    check_spine_animation(spineCollection, event, true)
end


return Level