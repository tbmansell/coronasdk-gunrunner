local anim               = require("core.animations")
local particles          = require("core.particles")
local builder            = require("elements.builders.builder")
local playerBuilder      = require("elements.builders.playerBuilder")
local enemyBuilder       = require("elements.builders.enemyBuilder")
local projectileBuilder  = require("elements.builders.projectileBuilder")

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

-- Aliases
local math_abs    = math.abs
local math_floor  = math.floor
local math_random = math.random

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
    spineCollection    = builder:newSpineCollection()
    movingCollection   = builder:newMovementCollection()
    particleCollection = builder:newParticleEmitterCollection()
    enemyCollection    = builder:newMasterCollection("enemySet", spineCollection, movingCollection, particleCollection)

    -- local aliases:
    camera = cameraRef

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

    spineCollection, movingCollection, particleCollection, enemyCollection, mainPlayer, camera = nil, nil, nil, nil, nil, nil
end


function Level:reset(player)
end


function Level:createElements(levelElements)
    self:createElementsFromData(levelElements)
    --self:createBackgrounds(camera)
    self:createEventHandlers()

    -- set boundaries to normal (unscaled) mode
    builder:setCollectionBoundaries()
end


function Level:appendElements(levelElements)
    return self:createElementsFromData(levelElements)
end


function Level:createElementsFromData(levelElements)
    for _,item in pairs(levelElements) do
        local object = item.object

        if     object == "scenery"     then self:createScenery(item)
        elseif object == "obstacle"    then self:createObstacle(item)
        elseif object == "enemy"       then self:createEnemy(item)
        elseif object == "emitter"     then self:createEmitter(item)
        elseif object == "collectable" then self:createCollectable(item) end
    end
end


function Level:createObstacle(item)
end


function Level:createEnemy(item)
    local enemy = enemyBuilder:newEnemy(camera, item)

    --spineCollection:add(enemy)
    enemyCollection:add(enemy)
end


function Level:createCollectable(item)
end


function Level:createScenery(item)
end


function Level:createEmitter(item)
end


function Level:createPlayer(item)
    mainPlayer = playerBuilder:newPlayer(camera, item)
    return mainPlayer
end


function Level:pauseElements()
end


function Level:resumeElements()
end


function Level:updateBehaviours()
    particleCollection:checkEach()
    enemyCollection:checkBehaviour(mainPlayer)

    --[[
    if hasEmitters then
        emitterCollection:checkEmittedOutOfPlay(camera)
    end

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