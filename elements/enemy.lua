local utils             = require("core.utils")
local projectileBuilder = require("elements.builders.projectileBuilder")

-- Class
local Enemy = {
    
    isEnemy    = true,
    class      = "Enemy",
    intHeight  = 30,
    intWidth   = 30,

    mode       = EnemyMode.ready,
    health     = 10,
    aggression = 50,    -- % chance enemy will trigger attack after wait period
    quickness  = 1000,  -- waiting time for enemy between attacks

    weapon     = nil,
    melee      = false,
    shielded   = false,
    shotsFired = 0,

    flagShootAllowed = true,
    waitingToShoot   = false,
    waitingToCharge  = false,
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
end


function Enemy:isDead()
    return self.mode == EnemyMode.dead
end


function Enemy:canShoot()
    return self.mode ~= EnemyMode.dead and self.flagShootAllowed
end


function Enemy:lineOfSight(player)
    return true
end


function Enemy:decideToShoot()
    if not self.waitingToShoot then
        if random(100) < self.aggression then
            -- Go and shoot, (note repeat call allow repeat true returns)
            return true
        else
            -- Decide to think about it
            self.waitingToShoot = true
            after(self.quickness, function() self.waitingToShoot = false end)
            return false
        end
    end
end


function Enemy:decideToCharge()

end


function Enemy:shoot(camera)
    if self:canShoot() then
        self.flagShootAllowed = false
        self.shotsFired = self.shotsFired + 1

        after(self.weapon.rof, function() 
            self.flagShootAllowed = true 
        end)

        local shot = projectileBuilder:newShot(nil, self.weapon, {xpos=self:x(), ypos=self:y(), angle=self.angle+90, filter=Filters.enemyShot})

        shot:fire()
    end
end


function Enemy:charge()
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


function Enemy:checkBehaviour(player)
    if self:lineOfSight(player) then
        -- Face player
        local angle = round(90 + atan2(player:y()- self:y(), player:x() - self:x()) * PI)
        
        if angle ~= self.angle then
            self:rotate(angle)
        end

        -- Check if should shoot player
        if self.weapon then
            if self:decideToShoot() then
                self:shoot()
            end
        -- Check if should chrge and attack
        elseif self.melee then
            if self:decideToCharge() then
                self:charge()
            end
        end
    end
end


return Enemy