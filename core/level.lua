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


function Level:getNumberEnemies(section)
    if section then
        return enemyCollection:sizeInSection(section)
    else
        return enemyCollection:sizeInGame()
    end
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


function Level:createElements(levelElements, levelGenerator)
    self:createElementsFromData(levelElements, levelGenerator)
    self:createEventHandlers()
end


function Level:createEventHandlers()
    check_spine_animation = spineCollection.animateEach
    check_moving_objects  = movingCollection.moveEach
end


function Level:createElementsFromData(levelElements, levelGenerator)
    for _,item in pairs(levelElements) do
        local object = item.object

        if object == "weapon" or object == "jewel" or object == "powerup" then 
            self:createCollectable(item)
        elseif object == "enemy" then 
            self:createEnemy(item)
        elseif object == "obstacle" then 
            self:createObstacle(item, levelGenerator)
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


function Level:createObstacle(item, levelGenerator)
    -- 50% chance non rotated item will be randomly rotated
    if item.rotation == nil and not item.dontRotate and percent(50) then
        if percent(50) then
            item.rotation = random(10)
        else
            item.rotation = 350 + random(10)
        end
    end

    local obstacle = obstacleBuilder:newItem(camera, item)
    obstacleCollection:add(obstacle)

    -- For custom map security doors, we need a reference to them so we can triger actions on them from game activity
    if obstacle.type == "securityDoor" and obstacle.guards == "exit" then
        levelGenerator:assignEntityRef("securityDoorExit", obstacle)

    elseif obstacle.type == "securityDoor" and obstacle.guards == "entrance" then
        levelGenerator:assignEntityRef("securityDoorEntrance", obstacle)

    end
end


function Level:createPowerup(powerup, xpos, ypos, mapSection)
    after(50, function()
        self:createCollectable({object="powerup", type=powerup, health=5, xpos=xpos, ypos=ypos, dontReposition=true, mapSection=mapSection})
    end)
end


function Level:createProjectile(item, weapon)
    local shot = projectileBuilder:newShot(camera, item, weapon)
    projectileCollection:add(shot)
    shot:fire()
end


function Level:createFlame(item, weapon)
    local shot = projectileBuilder:newShot(camera, item, weapon)
    projectileCollection:add(shot)
    shot:fire()

    return shot
end


function Level:createAreaOfEffect(item)
    projectileBuilder:newAreaOfEffect(camera, item) 
end


function Level:createSpineObject(item, spineParams)
    local object = builder:newSpineObject(item, spineParams)
    spineCollection:add(object)
    return object
end


function Level:addScorchMark(x, y, scale)
    local scorch = display.newImage("images/obstacles/scorchMark"..random(4)..".png", x, y)

    if scale then
        scorch:scale(scale, scale)
    end

    camera:addCollectable(scorch)
end


function Level:cullElements(fromSection)
    --particleCollection:cull(fromSection)
    enemyCollection:cull(fromSection)
    obstacleCollection:cull(fromSection)
    collectableCollection:cull(fromSection)
    projectileCollection:cull(fromSection)
end


function Level:pauseElements()
end


function Level:resumeElements()
end


function Level:updateBehaviours()
    particleCollection:checkEach()
    enemyCollection:checkDistancedBehaviour(camera, mainPlayer, 1000, 1500)

    mainPlayer:updateLegs()
    stats:setDistance(mainPlayer:y())
end


function Level:eventUpdateFrame(event)
    globalFPS = globalFPS + 1

    -- Compute time in seconds since last frame.
    local currentTime = event.time / 1000
    local delta       = currentTime - lastTime
    lastTime          = currentTime

    mainPlayer:updateSpine(delta)

    check_background_movement(delta)
    check_spine_animation(spineCollection, delta, true, mainPlayer)
end


function Level:debugInfo(show)
    enemyCollection:debugInfo(show)
end



return Level