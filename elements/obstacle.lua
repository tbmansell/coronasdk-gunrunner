local utils = require("core.utils")


-- Class
local Obstacle = {
    
    isObstacle = true,
    class      = "Obstacle",
}

-- Aliases
local cos     = math.cos
local sin     = math.sin
local rad     = math.rad
local abs     = math.abs
local random  = math.random
local percent = utils.percent


function Obstacle.eventCollision(self, event)
    local other = event.other.object
    local self  = self.object

    --[[if other and other.isProjectile then
        sounds:projectile(other.weapon.hitSound)
        other:destroy()
    end]]
end


function Obstacle:setPhysics()
    physics.addBody(self.image, "static", {density=1, friction=0, bounce=0, filter=Filters.obstacle})

    self.image.collision = Obstacle.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Obstacle:hit(shot)
    local damage = shot.weapon.damage

    if shot.getDamge then
        damage = shot:getDamage()
    end

    self.hits = self.hits - damage
        
    if self.hits <= 0 then
        self:explode()
    else
        self.image:setFillColor(1, 0.6, 0.6)
        after(50, function() 
            if self.image then self.image:setFillColor(1, 1, 1) end
        end)
    end
end


function Obstacle:explode()
    sounds:projectile("rocketHit")
    
    if self.isCrate then
        self:emit("explosionCrate")
        self:emit("smokeCrate")
        self:generatePowerup(50)

    elseif self.isComputer then
        self:emit("explosion")
        self:emit("smoke")

    elseif self.isGas then
        self:emit("explosionGas")
        self:emit("smoke")

        local effect = function(target)
            if target.hit then target:hit(self) end
        end

        -- enviromental damage has to hurt both player and enemies
        level:createAreaOfEffect({xpos=self:x(), ypos=self:y(), area=self.weapon.area, filter=Filters.playerShot, effect=effect})
        level:createAreaOfEffect({xpos=self:x(), ypos=self:y(), area=self.weapon.area, filter=Filters.enemyShot,  effect=effect})
    end

    self:destroy()
end


function Obstacle:generatePowerup(chance)
    level:createPowerup(Powerups.shield, self:x(), self:y())
    --[[
    if percent(chance) then
        local r = random(100)
        local x = self:x()
        local y = self:y()
        
        if     r <= 14 then level:createPowerup(Powerups.health, x, y)
        elseif r <= 28 then level:createPowerup(Powerups.damage, x, y)
        elseif r <= 42 then level:createPowerup(Powerups.fastMove, x, y)
        elseif r <= 56 then level:createPowerup(Powerups.fastShoot, x, y)
        elseif r <= 70 then level:createPowerup(Powerups.extraAmmo, x, y)
        elseif r <= 84 then level:createPowerup(Powerups.laserSight, x, y)
        else                level:createPowerup(Powerups.shield, x, y)
        end
    end]]
end


return Obstacle