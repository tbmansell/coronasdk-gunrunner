local json       = require "json"
local tileEngine = require("engines.duskWrapper")

-- Class
local Particles       = {}

local emitterData     = {}
local createdEmitters = {}


function Particles:preLoadEmitters()
    self:loadEmitter("bulletImpact")
    self:loadEmitter("bulletShot")
    self:loadEmitter("rocketBlast")
    self:loadEmitter("laserBolt")
    self:loadEmitter("explosion")
    self:loadEmitter("explosionLarge")
    self:loadEmitter("explosionCrate")
    self:loadEmitter("explosionGas")
    self:loadEmitter("smoke")
    self:loadEmitter("smokeLarge")
    self:loadEmitter("smokeCrate")
    self:loadEmitter("enemyDie1")
    self:loadEmitter("enemyDie2")
    self:loadEmitter("enemyDie-chainGun1")
    self:loadEmitter("enemyDie-chainGun2")
    self:loadEmitter("enemyDie-laserCannon1")
    self:loadEmitter("enemyDie-laserCannon2")
    self:loadEmitter("enemyDie-laserGun1")
    self:loadEmitter("enemyDie-laserGun2")
    self:loadEmitter("plasmaImpact")
    self:loadEmitter("collectable")
    self:loadEmitter("collectFlash-left")
    self:loadEmitter("collectFlash-right")
    self:loadEmitter("flamer")
end


function Particles:loadEmitter(name)
    local filePath = system.pathForFile("json/particles/"..name..".json")
    local f        = io.open(filePath, "r")
    local fileData = f:read("*a")
    f:close()

    local emitterParams, _, errorMessage = json.decode(fileData)

    if errorMessage then
        print(errorMessage)
    end

    emitterData[name] = emitterParams
end


function Particles:destroy()
    for _,data in pairs(createdEmitters) do
        if data and data.removeSelf then
            data:removeSelf()
        end
    end
    createdEmitters = {}
    emitterData     = {}
end


function Particles:pause()
    for _,data in pairs(createdEmitters) do
        if data and data.pause then
            data:pause()
        end
    end
end


function Particles:resume()
    for _,data in pairs(createdEmitters) do
        if data and data.start then
            data:start()
        end
    end
end


function Particles:size()
    local count = 0

    for _,item in pairs(createdEmitters) do
        if item then count = count + 1 end
    end
    return count
end


function Particles:showEmitter(name, x, y, duration, alpha, angle)
    -- Typically we preload them all, but if called without pre-loading then check if loaded before calling
    if emitterData[name] == nil then
        self:loadEmitter(name)
    end

    -- Create the emitter with the decoded parameters
    local emitter = display.newEmitter(emitterData[name])
    emitter.x                = x
    emitter.y                = y
    emitter.id               = #createdEmitters + 1
    emitter.alpha            = alpha or 1
    emitter.rotationStart    = angle
    emitter.rotationEnd      = angle
    emitter.absolutePosition = false

    createdEmitters[emitter.id] = emitter

    tileEngine:addParticle(emitter)

    function emitter:destroy()
        if self and self.removeSelf then
            if createdEmitters[self.id] then
                createdEmitters[self.id] = nil
            end
            
            self:removeSelf()
            self = nil
        end
    end

    if duration ~= "forever" then
        after(duration, function()
            if emitter and emitter.removeSelf then
                emitter:destroy()
            end
        end)
    end

    return emitter
end


function Particles:scale(camera)
    for _,emitter in pairs(createdEmitters) do
        if emitter then
            local scale = camera.scalePosition

            emitter.x = emitter.x * scale
            emitter.y = emitter.y * scale

            -- Doesnt work for emitters:
            --emitter.xScale = scale
            --emitter.yScale = scale

            emitter.startParticleSize  = emitter.startParticleSize  * scale
            emitter.finishParticleSize = emitter.finishParticleSize * scale

            emitter.startParticleSizeVariance  = emitter.startParticleSizeVariance  * scale
            emitter.finishParticleSizeVariance = emitter.finishParticleSizeVariance * scale
        end
    end
end


return Particles