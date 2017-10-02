-- Class
local Obstacle = {
    
    isObstacle = true,
    class      = "Obstacle",
}

-- Aliases
local cos = math.cos
local sin = math.sin
local rad = math.rad
local abs = math.abs


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
    self.hits = self.hits - shot.weapon.damage
        
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


return Obstacle