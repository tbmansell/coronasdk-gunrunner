local anim               = require("core.animations")
local particles          = require("core.particles")
local utils              = require("core.utils")
local builder            = require("elements.builders.builder")
local playerBuilder      = require("elements.builders.playerBuilder")
local enemyBuilder       = require("elements.builders.enemyBuilder")
local collectableBuilder = require("elements.builders.collectableBuilder")
local obstacleBuilder    = require("elements.builders.obstacleBuilder")
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
local collectableCollection = nil
local obstacleCollection    = nil
local projectileCollection  = nil

-- Aliases
local random  = math.random
local percent = utils.percent

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
    projectileCollection  = builder:newMasterCollection("projectileSet",  spineCollection, movingCollection, particleCollection)

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
    projectileCollection:destroy()

    spineCollection, movingCollection, particleCollection, enemyCollection, collectableCollection, obstacleCollection, projectileCollection = nil, nil, nil, nil, nil, nil, nil
    mainPlayer, camera = nil, nil
end


function Level:getNumberEntities()
    return enemyCollection:sizeInGame() + obstacleCollection:sizeInGame() + collectableCollection:sizeInGame() + projectileCollection:sizeInGame()
end


function Level:getSizeEntities()
    return enemyCollection:size() + obstacleCollection:size() + collectableCollection:size() + projectileCollection:size()
end


function Level:getNumberEnemies()
    return enemyCollection:sizeInGame()
end


function Level:getNumberObstacles()
    return obstacleCollection:sizeInGame()
end


function Level:getNumberCollectables()
    return collectableCollection:sizeInGame()
end


function Level:getNumberProjectiles()
    return projectileCollection:sizeInGame()
end


function Level:getNumberParticles()
    return particles:size()
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

        if     object == "enemy"       then self:createEnemy(item)
        elseif object == "obstacle"    then self:createObstacle(item)
        elseif object == "weapon" or object == "jewel" or object == "powerup" then self:createCollectable(item)
        end
    end
end


function Level:createPlayer(item, hud)
    mainPlayer = playerBuilder:newPlayer(camera, item, hud)
    mainPlayer:visible()
    return mainPlayer
end


function Level:createEnemy(item)
    local enemy = enemyBuilder:newEnemy(camera, item)
    enemyCollection:add(enemy)
end


function Level:createCollectable(item)
    local collectable = collectableBuilder:newItem(camera, item)
    collectableCollection:add(collectable)
end


function Level:createPowerup(powerup, xpos, ypos)
    after(50, function()
        self:createCollectable({object="powerup", type=powerup, health=5, xpos=xpos, ypos=ypos, dontReposition=true})
    end)
end


function Level:createObstacle(item)
    -- 50% chance non rotated item will be randomly rotated
    if item.rotation == nil and percent(50) then
        if percent(50) then
            item.rotation = random(10)
        else
            item.rotation = 350 + random(10)
        end
    end

    local obstacle = obstacleBuilder:newItem(camera, item)
    obstacleCollection:add(obstacle)
end


function Level:createProjectile(item, weapon)
    local shot = projectileBuilder:newShot(camera, item, weapon)
    projectileCollection:add(shot)
    shot:fire()
end


function Level:createAreaOfEffect(item)
    projectileBuilder:newAreaOfEffect(camera, item) 
end


function Level:createSpineObject(item, spineParams)
    local object = builder:newSpineObject(item, spineParams)
    spineCollection:add(object)
    return object
end


function Level:pauseElements()
end


function Level:resumeElements()
end


function Level:updateBehaviours()
    particleCollection:checkEach()
    enemyCollection:checkBehaviour(camera, mainPlayer)

    stats:setDistance(mainPlayer:y())

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
    check_spine_animation(spineCollection, delta, true, mainPlayer)
    --check_moving_objects(movingCollection, delta, camera)
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