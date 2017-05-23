local utils             = require("core.utils")
local projectileBuilder = require("elements.builders.projectileBuilder")

-- Class
local Enemy = {
    
    isEnemy       = true,
    class         = "Enemy",
    intHeight     = 30,
    intWidth      = 30,

    mode          = EnemyMode.ready,
    health        = 0,
    decisionDelay = 0,  -- waiting time for enemy between decisions
    aggression    = 0,  -- % chance enemy will trigger attack after wait period
    fidgit        = 0,  -- % chance enemy will move after wait period
    roaming       = 0,  -- max duration will walk for
    speed         = 0,  -- movement force

    weapon        = nil,
    melee         = false,
    shielded      = false,
    ammo          = 0,

    flagShootAllowed  = true,
    flagMoveAllowed   = true,
    flagChargeAllowed = true,
    waitingToShoot    = false,
    waitingToMove     = false,
    waitingToCharge   = false,
}

-- Aliases
local PI    = 180 / math.pi
local abs   = math.abs
local cos   = math.cos
local sin   = math.sin
local rad   = math.rad
local atan2 = math.atan2
local round = math.round
local random= math.random

local Melee = {weapon=Weapons.melee}


function Enemy.eventCollision(self, event)
    local other = event.other.object
    local self  = self.object

    if other and other.isPlayer then 
        if event.phase == "began" then
            sounds:enemy("melee")
            other:hit(Melee)
        end
    end
end


function Enemy:updateSpine(delta)
    self.state:update(delta)
    self.state:apply(self.skeleton)
    self.skeleton:updateWorldTransform()

    self.legs:updateSpine(delta)
end


function Enemy:rotate(rotation)
    if self.image then
        self.image.rotation = rotation
        self.angle = rotation

        self.legs:rotate(rotation)
    end
end


function Enemy:setMode(mode, aliveOnly)
    -- aliveOnly to be used so we dont accidentally overwrite status if currently dead
    if not aliveOnly or not self:isDead() then
        self.mode = mode
    end
end


function Enemy:setPhysics()
    local w, h  = self.intWidth, self.intHeight
    local shape = {-w,-h, w,-h, w,h, -w,h}

    physics.addBody(self.image, (self.physicsBody or "dynamic"), {shape=shape, density=1, friction=1, bounce=0, filter=Filters.enemy})
   
    self.image.isFixedRotation   = true
    self.image.isSleepingAllowed = false

    self.image.collision = Enemy.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Enemy:isDead()
    return self.mode == EnemyMode.dead
end


function Enemy:canShoot()
    return self.mode ~= EnemyMode.dead and self.flagShootAllowed and self.ammo > 0
end


function Enemy:canMove()
    return self.mode ~= EnemyMode.dead and self.mode ~= EnemyMode.charge and self.flagMoveAllowed
end


function Enemy:canCharge()
    return self.mode ~= EnemyMode.dead and self.mode ~= EnemyMode.walk and self.flagChargeAllowed
end


function Enemy:lineOfSight(player)
    return true
end


function Enemy:checkBehaviour(camera, player)
    if self:lineOfSight(player) then
        -- Face player if not charging
        if self.mode ~= EnemyMode.charge then
            local angle = round(90 + atan2(player:y()- self:y(), player:x() - self:x()) * PI)
            
            if angle ~= self.angle then
                self:rotate(angle)
            end
        end

        -- Check if should shoot player
        if self.weapon then
            if self:decideToShoot() then
                self:shoot(camera)
            end
        -- Check if should chrge and attack
        elseif self.melee then
            if self:decideToCharge() then
                self:charge(player)
            end
        end
    end

    if self:decideToMove() then
        self:move()
    end
end


function Enemy:decideToShoot()
    if self:canShoot() and not self.waitingToShoot then
        if random(100) < self.aggression then
            -- Go and shoot, (note repeat call allow repeat true returns)
            return true
        else
            -- Decide to think about it
            self.waitingToShoot = true
            after(self.decisionDelay, function() self.waitingToShoot = false end)
            return false
        end
    end
end


function Enemy:decideToMove()
    if self:canMove() and not self.waitingToMove then
        -- always have to wait to decide again
        self.waitingToMove = true
        after(self.decisionDelay, function() self.waitingToMove = false end)
        
        return (random(100) < self.fidgit)
    end
end


function Enemy:decideToCharge()
    if self:canCharge() and not self.waitingToCharge then
        -- always have to wait to decide again
        self.waitingToCharge = true
        after(self.decisionDelay, function() self.waitingToCharge = false end)

        return (random(100) < self.aggression)
    end
end


function Enemy:shoot(camera)
    self.flagShootAllowed = false
    self.ammo = self.ammo - 1

    -- Enable more firing after ROF period ending
    after(self.weapon.rof, function() 
        self.flagShootAllowed = true 
    end)

    -- If run out of ammo reload
    if self.ammo <= 0 then
        sounds:projectile("reload")

        after(1500, function() self.ammo = self.weapon.ammo end)
    end

    local shot = projectileBuilder:newShot(camera, self.weapon, {xpos=self:x(), ypos=self:y(), angle=self.angle+90, filter=Filters.enemyShot})
    shot:fire()
end


function Enemy:move()
    self.flagMoveAllowed = false
    self.mode = EnemyMode.walk

    local duration  = utils.randomRange(250, self.roaming)
    local direction = utils.randomRange(1, 360)
    local forceX    = self.speed * -cos(rad(direction))
    local forceY    = self.speed * -sin(rad(direction))

    self:applyForce(forceX, forceY)

    after(duration, function()
        self:stopMomentum()
        self.flagMoveAllowed = true
        self.mode = EnemyMode.ready
    end)
end


function Enemy:charge(player)
    self.flagChargeAllowed = false
    self.mode = EnemyMode.charge

    local runSpeed  = self.speed * 2
    local duration  = 2000
    local direction = atan2(self:y() - player:y(), self:x() - player:x()) * PI
    local forceX    = runSpeed * -cos(rad(direction))
    local forceY    = runSpeed * -sin(rad(direction))

    sounds:enemy("charge")
    self:stopMomentum()
    self:applyForce(forceX, forceY)

    after(duration, function()
        self:stopMomentum()
        self.flagChargeAllowed = true
        self.mode = EnemyMode.ready
    end)
end


function Enemy:hit(shot)
    if not self:isDead() then
        if not self.shielded or shot.weapon.shieldBuster then
            self.health = self.health - shot.weapon.damage

            sounds:enemy("hurt")
            --self:animate("hit")

            if self.health < 0 then
                self:die()
            end
        end
    end
end


function Enemy:die()
    -- guard to stop multiple deaths
    if not self:isDead() then
        self.mode = EnemyMode.dead

        self:destroyEmitter()
        --self:emit("deathflash")
        --self:emit("die")

        sounds:enemy("killed")

        self:destroy()
    end
end


return Enemy