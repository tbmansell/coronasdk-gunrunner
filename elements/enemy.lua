local utils = require("core.utils")
local anim  = require("core.animations")


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
    flagStrikeAllowed = true,
    flagMoveAllowed   = true,
    flagChargeAllowed = true,
    waitingToShoot    = false,
    waitingToStrike   = false,
    waitingToMove     = false,
    waitingToTurn     = false,
    waitingToCharge   = false,
}

-- Aliases
local PI      = 180 / math.pi
local abs     = math.abs
local cos     = math.cos
local sin     = math.sin
local rad     = math.rad
local atan2   = math.atan2
local round   = math.round
local random  = math.random
local percent = utils.percent



function Enemy.eventCollision(self, event)
    local other = event.other.object or event.other
    local self  = self.object

    if other then
        if event.phase == "began" and other.isHole then
            self:fallToDeath(other)

        elseif other.isPlayer and not self.isTurret then 
            -- always strike on start of contact
            if event.phase == "began" then
                self:strike(other)
            -- Logic to keep striking if contact is kept 
            elseif self:decideToStrike() then
                self:strike(other)
            end
        elseif self.turnsOnMove then
            self:stopMomentum()
            self:loop(self.stationaryAnim)
        end
    end
end


function Enemy:updateSpine(delta)
    self.state:update(delta)
    self.state:apply(self.skeleton)
    
    self.boneRoot.rotation = -(self.angle + 30)
    
    self.skeleton:updateWorldTransform()

    if self.legs then
        self.legs:updateSpine(delta)
    end
end


function Enemy:rotate(rotation)
    if self.image then
        self.angle = rotation
    end
end


function Enemy:animateRotate(rotation)
    if self.image and self.angle ~= rotation then
        local diff = self.angle - rotation

        if diff ~= 0 and diff % 360 ~= 0 then
            if self.turnsOnMove then
                self:loop("turn_left")
            end
 
            if diff > 180 then
                rotation = rotation + 360
            elseif diff < -180 then
                rotation = rotation - 360
            end

            transition.to(self, {angle=rotation, time=self.turnSpeed, onComplete=function()
                if self.mode == EnemyMode.ready and not self.isTurret then
                    self:loop(self.stationaryAnim)
                end
            end})
        end
    end
end


function Enemy:animateLegs(anim)
    if self.legs then
        self.legs:loop(anim)
    end
end


function Enemy:setMode(mode, aliveOnly)
    -- aliveOnly to be used so we dont accidentally overwrite status if currently dead
    if not aliveOnly or not self:isDead() then
        self.mode = mode
    end
end


function Enemy:setPhysics()
    physics.addBody(self.image, (self.physicsBody or "dynamic"), {radius=self.intWidth, density=1, friction=1, bounce=0, filter=Filters.enemy})
   
    self.image.isFixedRotation   = true
    self.image.isSleepingAllowed = false

    self.image.collision = Enemy.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Enemy:destroy(camera, destroyBoundItems)
    self:spineObjectDestroy(camera, destroyBoundItems)
end


function Enemy:isDead()
    return self.mode == EnemyMode.dead
end


function Enemy:canShoot()
    return self.mode ~= EnemyMode.dead and self.flagShootAllowed and self.ammo > 0
end


function Enemy:canStrike()
    return self.mode ~= EnemyMode.dead and self.flagStrikeAllowed
end


function Enemy:canMove()
    return self.mode ~= EnemyMode.dead and self.mode ~= EnemyMode.charge and self.flagMoveAllowed
end


function Enemy:canCharge()
    return self.mode ~= EnemyMode.dead and self.flagChargeAllowed
end


function Enemy:canTurn()
    return not (self.turnsOnMove and (self.mode == EnemyMode.walk or self.mode == EnemyMode.charge))
end


function Enemy:lineOfSight(player)
    local hits = physics.rayCast(self:x(), self:y(), player:x(), player:y(), "sorted")

    if hits then
        for i,v in pairs(hits) do
            if v.object.isWall then
                return false
            end
        end
    end

    return true
end


function Enemy:setWeapon(weapon)
    if weapon.slot then
        self.skeleton:setAttachment(weapon.slot, weapon.skin)
    end

    self:setWeaponBones(weapon)
end


function Enemy:checkShouldFreeze(distX, distY)
    local fx, fy = self:getForce()

    if fx ~= 0 or fy ~= 0 then
        --print(self.key.." FREEZE distance("..tostring(distX)..", "..tostring(distY)..") force("..tostring(fx)..", "..tostring(fy)..") mode="..tostring(self.mode))
        self.frozen = {fx, fy}
        self:stopMomentum()
    end
end


function Enemy:checkBehaviour(camera, player)
    -- Enemy must be in certain distance before they will do anything
    if self.mode ~= EnemyMode.dead then
        -- check if we should unfreeze:
        if self.frozen then
            --print(self.key.." UNfreeze force("..tostring(self.frozen[1])..", "..tostring(self.frozen[2])..") mode="..tostring(self.mode))
            self:applyForce(self.frozen[1], self.frozen[2])
            self.frozen = nil
        end

        if self:lineOfSight(player) then
            -- Face player if not charging
            if self:canTurn() and self.mode ~= EnemyMode.charge  then
                local angle = round(90 + atan2(player:y()- self:y(), player:x() - self:x()) * PI)

                if self.turnsOnMove then angle = angle - 30 end
                
                if angle ~= self.angle then
                    self:animateRotate(angle)
                end
            end

            -- Check if should shoot player
            if self.ammo and self:decideToShoot() then
                self:shoot(camera)
            -- Check if should charge and attack
            elseif self.melee and self:decideToCharge() then
                self:charge(player)
            elseif self:decideToMove() then
                self:move()
            end
        else
            -- if not visible randomly rotate
            if self:decideToMove() then
                self:move()
            elseif self:decideToTurn() then
                self:randomTurn()
            end
        end
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


function Enemy:decideToStrike()
    if self:canStrike() and not self.waitingToStrike then
        if random(100) < self.aggression then
            -- Go and strike, (note repeat call allow repeat true returns)
            return true
        else
            -- Decide to think about it
            self.waitingToStrike = true
            after(self.decisionDelay, function() self.waitingToStrike = false end)
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


function Enemy:decideToTurn()
    if not self.waitingToTurn and self:canTurn() then
        -- always have to wait to decide again
        self.waitingToTurn = true
        after(self.decisionDelay, function() self.waitingToTurn = false end)

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
    self:shootProjectile(projectileBuilder, camera, Filters.enemyShot)
end


function Enemy:strike(target)
    self.flagStrikeAllowed = false
    self:setMode(EnemyMode.strike)

    local weapon = self.weapon

    sounds:enemy("melee")
    self:stopMomentum()
    self:loop("strike_"..weapon.name)
    target:hit({weapon=weapon, getDamage=function() return weapon.damage end})

    after(weapon.time, function()
        self:loop(self.stationaryAnim)
        self:animateLegs("stationary")

        self.flagStrikeAllowed = true
        self:setMode(EnemyMode.ready)
    end)
end


function Enemy:move()
    self.flagMoveAllowed = false
    self:setMode(EnemyMode.walk)

    local direction = utils.randomRange(1, 360)

    if self.turnsOnMove then
        self:animateRotate(direction-120)
        
        after(self.turnSpeed, function()
            if not self:isDead() then self:doMove(direction) end
        end)
    else
        self:doMove(direction)
    end
end


function Enemy:doMove(direction)
    local duration = utils.randomRange(250, self.roaming)
    local forceX   = self.speed * -cos(rad(direction))
    local forceY   = self.speed * -sin(rad(direction))

    self:applyForce(forceX, forceY)
    self:loop("run_"..self.weapon.name)
    self:animateLegs("run")

    after(duration, function()
        if not self:isDead() then
            self:stopMomentum()
            self:loop(self.stationaryAnim)
            self:animateLegs("stationary")
            self:setMode(EnemyMode.ready)
            self.flagMoveAllowed = true
        end
    end)
end


function Enemy:randomTurn()
    local turn = random(45)

    if random(100) > 50 then
        turn = -turn
    end

    self:animateRotate(self.angle + turn)
end


function Enemy:charge(player)
    self.flagChargeAllowed = false
    self:setMode(EnemyMode.charge)

    local direction = atan2(self:y() - player:y(), self:x() - player:x()) * PI
    
    if self.turnsOnMove then
        self:animateRotate(direction-120)
        
        after(self.turnSpeed, function()
            if not self:isDead() then self:doCharge(direction) end
        end)
    else
        self:animateRotate(direction-90)
        self:doCharge(direction)
    end
end


function Enemy:doCharge(direction)
    local runSpeed  = self.speed * 2
    local duration  = 2000
    local forceX    = runSpeed * -cos(rad(direction))
    local forceY    = runSpeed * -sin(rad(direction))

    sounds:enemy("charge")
    self:loop("run_"..self.weapon.name)
    self:animateLegs("run")
    self:stopMomentum()
    self:applyForce(forceX, forceY)

    after(duration, function()
        self.flagChargeAllowed = true

        if not self:isDead() and self.mode == EnemyMode.charge then
            self:stopMomentum()
            self:loop(self.stationaryAnim)
            self:animateLegs("stationary")
            self:setMode(EnemyMode.ready)
        end
    end)
end


function Enemy:hit(shot)
    if not self:isDead() then
        stats:addHit(shot.weapon)

        if not self.shielded or shot.weapon.shieldBuster then
            local damage = shot.weapon.damage

            if shot.getDamge then
                damage = shot:getDamage()
            end
            
            self.health = self.health - damage

            sounds:enemy("hurt")
            self:animate("hit_1")

            if self.health <= 0 then
                self:explode()
                stats:addKill(shot.weapon, self.type, self.rank)
            end
        end
    end
end


function Enemy:explode()
    -- guard to stop multiple deaths
    if not self:isDead() then
        self.mode = EnemyMode.dead

        sounds:enemy("killed")

        self:stopMomentum()
        self:animate("death_"..random(3))

        local seq = anim:chainSeq("die", self.image)
        seq:tran({time=350, alpha=0})
        seq.onComplete = function()
            print("*** explode "..self.key)
            self:destroy()
        end
        seq:start()

        after(50, function()
            --self:destroyEmitter()
            if self.isTurret then
                self:emit("explosionLarge")
                self:emit("smokeLarge")
            else
                self:emit("enemyDie1")
                self:emit("enemyDie2")
            end

            self:dropWeapon()
        end)
    end
end


function Enemy:fallToDeath(hole)
    if not self:isDead() then
        self.mode = EnemyMode.dead

        sounds:player("killed")

        self:stopMomentum(true)
        --self:animate(animation or "death_"..random(2))

        local seq = anim:chainSeq("die", self.image)
        seq:tran({time=1000, x=hole.x, y=hole.y, xScale=0.01, yScale=0.01, alpha=0})
        seq.onComplete = function()
            print("*** fallToDeath "..self.key)
            self:destroy()
        end
        seq:start()
    end
end


function Enemy:dropWeapon()
    -- % chance dead enemy drops their weapon
    local weapon = self.weapon

    if weapon.collect and percent(weapon.collect) then
        level:createCollectable({object="weapon", type=weapon.name, xpos=self:x(), ypos=self:y(), dontReposition=true})
    end
end


return Enemy