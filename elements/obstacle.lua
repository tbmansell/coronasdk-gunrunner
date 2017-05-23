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

    if other and other.isProjectile then 
        sounds:projectile(other.weapon.hitSound)
        other:destroy()
    end
end


function Obstacle:setPhysics()
    physics.addBody(self.image, "static", {density=1, friction=0, bounce=0, filter=Filters.obstacle})

    self.image.collision = Obstacle.eventCollision
    self.image:addEventListener("collision", self.image)
end


return Obstacle