-- Class
local Projectile = {
    
    isProjectile = true,
    class        = "Projectile",
}

-- Aliases
local cos = math.cos
local sin = math.sin
local rad = math.rad
local abs = math.abs


function Projectile.eventCollision(self, event)
    local other = event.other.object
    local self  = self.object

    if other then
        if other.isPlayer or other.isEnemy then 
            other:hit(self)
        end

        sounds:projectile(self.weapon.hitSound)
        self:destroy()
    end
end


function Projectile:setPhysics()
    physics.addBody(self.image, "dynamic", {density=0, friction=0, bounce=0, filter=self.filter})

    self.image.collision = Projectile.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Projectile:fire()
    local weapon = self.weapon
    local forceX = weapon.speed * -cos(rad(self.angle))
    local forceY = weapon.speed * -sin(rad(self.angle))

    if weapon.ammoType == "rocket" then
        --[[if forceY > 0 then
            self:flipY()
        end]]
        self:flipY()
        -- dont call rotate() as this changes the angle
        self.image.rotation = self.angle + 90    
    end

    self:applyForce(forceX, forceY)

    sounds:projectile(weapon.shotSound)
end


return Projectile