local anim        = require("core.animations")
local spine       = require("core.spine")
--local soundEngine = require("core.sound-engine")

-- Class
local Player = {

    isPlayer          = true,
    class             = "Player",
    intHeight         = 25,
    intWidth          = 25,
    intMaxHealth      = 20,
    verticalSpeed     = 4,--8,--4,
    strafeSpeed       = 4,--8,--4,
    powerupDuration   = 15000,

    mode              = PlayerMode.ready,
    health            = 20,
    shieldHealth      = 0,
    weapon            = nil,
    ammo              = 0,
    boneBarrel        = nil,
    gear              = {},  -- array have to be set by the builder due to deep copy problems
    powerups          = {},  -- collection of timer handles per powerup active or nil if one is not active
    
    flagShootAllowed  = true,
    prevX             = 0,
    prevY             = 0,
}

-- Aliases:
local cos    = math.cos
local sin    = math.sin
local rad    = math.rad
local random = math.random
local round  = math.round


function Player.eventCollision(self, event) 
    local other = event.other.object or event.other
    local self  = self.object

    if other and other.isHole and event.phase == "began" then
        self:fallToDeath(other)
    end
end


function Player:updateSpine(delta)
    self.state:update(delta)
    self.state:apply(self.skeleton)

    self.boneRoot.rotation = -(self.angle + 30)

    self.skeleton:updateWorldTransform()
    
    self.legs:updateSpine(delta)
end


function Player:updateLegs(anim)
    local y  = self:y()
    local dy = round(self.prevY - y)

    if dy == 0 then
        if not self.hudMovement and self.legAnimation ~= "stationary" then
            self:loopLegs("stationary")
        end
    elseif anim and self.legAnimation ~= anim then
        self:loopLegs(anim)
    end

    self.prevY = y
end


function Player:verticalMovement()
    return round(self.prevY - self:y())
end


function Player:loopLegs(anim)
    self.legAnimation = anim
    self.legs:loop(anim)
end


function Player:topEdge()
    return self.image.y - self.intHeight
end


function Player:bottomEdge()
    return self.image.y
end


function Player:width()
    return self.intWidth
end


function Player:height()
    return self.intHeight
end


function Player:midHeight()
    return self.image.y - (self.intHeight/2)
end


function Player:isDead()
    return self.mode == PlayerMode.dead
end


function Player:canMove()
    return self.mode ~= PlayerMode.dead
end


function Player:canJump()
    return self.mode ~= PlayerMode.dead
end


function Player:canAim()
    return self.mode ~= PlayerMode.dead and not self.shootingLocked
end


function Player:canShoot()
    return self.mode ~= PlayerMode.dead and self.flagShootAllowed and self.ammo > 0
end


function Player:shoot(camera, ammoCounter)
    if self:canShoot() then
        self:shootProjectile(projectileBuilder, camera, Filters.playerShot, function() self:hookAmmoCounter() end)
        self:hookAmmoCounter()
        
        stats:addShot(self.weapon)
    end
end



---- override
function Player:rotate(rotation, event)
    if self.image then
        self.angle = rotation
    end
end


function Player:setMode(mode, aliveOnly)
    -- aliveOnly to be used so we dont accidentally overwrite status if currently dead
    if not aliveOnly or not self:isDead() then
        self.mode = mode
    end
end


function Player:setPhysics()
    physics.addBody(self.image, (self.physicsBody or "dynamic"), {radius=self.intWidth, density=1, friction=1, bounce=0--[[, filter=Filters.player]]})
   
    self.image.isFixedRotation   = true
    self.image.isSleepingAllowed = false

    self.image.collision = Player.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Player:startLevelSequence()
    self:pose()
    self:loop("run_"..self.weapon.name)
end


----------------- FUNCTIONS TO HANDLE BEING KILLED -------------------


function Player:heal(health)
    if not self:isDead() then
        self.health = self.health + health

        if self.health > self.intMaxHealth then
            self.health = self.intMaxHealth
        end

        self:updateHudHealth()
    end
end


function Player:hit(shot)
    if not self:isDead() then
        local damage = shot.weapon.damage

        if shot.getDamge then
            damage = shot:getDamage()
        end

        if self.shieldEntity then
            self.shieldEntity.health = self.shieldEntity.health - damage
            sounds:projectile("laserHit")

            if self.shieldEntity.health <= 0 then
                self.shieldEntity:destroy()
                self.shieldEntity = nil
            end
        else
            self.health = self.health - damage
            
            sounds:player("hurt")
            self:animate("hit_1")
            self:updateHudHealth()

            if self.health < 0 then
                self:explode()
            end
        end 
    end
end


function Player:explode(sound, message)
    if not self:isDead() then
        self.mode = PlayerMode.dead

        sounds:player(sound or "killed")

        self:destroyEmitter()
        self:stopMomentum(true)
        self:animate(animation or "death_"..random(2))

        local seq = anim:chainSeq("die", self.image)
        seq:tran({time=1000, alpha=0})
        seq.onComplete = function()
            self:hide()
            self:failedCallback() 
        end
        seq:start()
    end
end


function Player:fallToDeath(hole)
    if not self:isDead() then
        self.mode = PlayerMode.dead

        sounds:player("killed")

        self:destroyEmitter()
        self:stopMomentum(true)
        self:animate("falling")

        local seq = anim:chainSeq("die", self.image)
        seq:tran({time=1000, x=hole.x, y=hole.y, xScale=0.01, yScale=0.01, alpha=0})
        seq.onComplete = function()
            self:hide()
            self:failedCallback()
        end
        seq:start()
    end
end


function Player:destroy(camera, destroyBoundItems)
    self:spineObjectDestroy(camera, destroyBoundItems)

    for _,handle in pairs(self.powerups) do
        if handle then 
            timer.cancel(handle) 
            handle = nil
        end
    end
end


----------------- FUNCTIONS TO HANDLE GEAR & POWERUPS ------------------- 


function Player:setWeapon(weapon)
    self.weapon            = weapon
    self.ammo              = weapon.ammo
    self.flagShootAllowed  = true
    self.gear["weapon"]    = {slot=weapon.slot, skin=weapon.skin}
    
    self:loadGear()
    self:setWeaponBones(weapon)
    self:loop("run_"..weapon.name)
    self:hookAmmoCounter()
end


function Player:setGear(item)
    self.gear[item.name] = {slot=item.slot, skin=item.skin}
    self:loadGear()
end


function Player:removeGear(item)
    self.gear[item.name] = nil
    self:loadGear()
end


function Player:pose()
    self.skeleton:setToSetupPose()
    self:loadGear()
end


function Player:loadGear()
    for name, item in pairs(self.gear) do
        if item then
            self.skeleton:setAttachment(item.slot, item.skin)
        else
            self.skeleton:setAttachment(item.slot, nil)
        end
    end
end


function Player:pause()
    for _,handle in pairs(self.powerups) do
        if handle then timer.pause(handle) end
    end
end



function Player:resume()
    for _,handle in pairs(self.powerups) do
        if handle then timer.resume(handle) end
    end
end


function Player:startPowerup(power, onComplete)
    local existing = self.powerups[power]

    if existing then
        timer.cancel(existing)
    end

    local action = function()
        onComplete(self)
        self.powerups[power] = nil
    end

    self.powerups[power] = timer.performWithDelay(self.powerupDuration, action)
end


function Player:hasPowerup(power)
    return (self.powerups[power] ~= nil)
end


function Player:hasExtraDamage()
    if self.powerups[Powerups.damage] then
        return 2
    else
        return nil
    end
end


function Player:hasExtraAmmo()
    return (self.powerups[Powerups.extraAmmo] ~= nil)
end


function Player:hasFastMove()
    return (self.powerups[Powerups.fastMove] ~= nil)
end


function Player:hasFastShoot()
    return (self.powerups[Powerups.fastShoot] ~= nil)
end


function Player:hasLaserSight()
    return (self.powerups[Powerups.laserSight] ~= nil)
end


function Player:extraDamage()
    if not self:isDead() then
        self:startPowerup(Powerups.damage, function()end)
    end
end


function Player:fastMove()
    if not self:isDead() then
        self.verticalSpeed = 6
        self.strafeSpeed   = 6
        self:updateHudSpeed(true)

        self:startPowerup(Powerups.fastMove, function()
            self.verticalSpeed   = 4
            self.strafeSpeed     = 4
            self:updateHudSpeed(false)
        end)
    end
end


function Player:fastShoot()
    if not self:isDead() then
        self:startPowerup(Powerups.fastShoot, function()end)
    end
end


function Player:extraAmmo()
    if not self:isDead() then
        self.ammo = self.weapon.ammo * 2
        self:startPowerup(Powerups.extraAmmo, function()end)
    end
end


function Player:shield()
    if not self:isDead() then
        if self.shieldEntity then
            self.shieldEntity.health = 10
        else
            local shield = level:createSpineObject({type="gearshield"}, {jsonName="shield", imagePath="collectables", animation="Rotate"})
            shield.image:scale(0.5, 0.5)
            shield.health = 10

            shield:loop("Rotate")
            shield:visible(0.6)
            
            globalCamera:addCollectable(shield)
            self.shieldEntity = shield
        end
    end
end


function Player:laserSight()
    if not self:isDead() then
        self:startPowerup(Powerups.laserSight, function()
            self:removeLaserSight()
        end)
    end
end


function Player:drawLaserSight()
    local angle  = (self.angle or 0)
    local x      = self:x() + self.boneBarrel.worldX
    local y      = self:y() - self.boneBarrel.worldY
    local ex     = x + 1000 * sin(rad(angle))
    local ey     = y + 1000 * -cos(rad(angle))

    -- Check if anything in its path
    local hits = physics.rayCast(x, y, ex, ey)

    if hits then
        for i,v in ipairs(hits) do
            ex, ey = v.position.x, v.position.y
        end
    end

    self:removeLaserSight()
    
    local sight = display.newLine(x, y, ex, ey)
    sight.strokeWidth = 4
    sight:setStrokeColor(1, 0, 0, 0.2)

    self.laserSightEntity = sight
    globalCamera:addCollectable(sight)
end


function Player:removeLaserSight()
    if self.laserSightEntity then
        self.laserSightEntity:removeSelf()
        self.laserSightEntity = nil
    end
end


function Player:lockShooting(lock)
    self.shootingLocked = lock
end


return Player