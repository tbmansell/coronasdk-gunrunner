-- Class
local Projectile = {}

-- Aliases
local cos = math.cos
local sin = math.sin
local rad = math.rad
local abs = math.abs


function Projectile:setPhysics()
    physics.addBody(self.image, "dynamic", {density=0, friction=0, bounce=0, filter=self.filter})
end


function Projectile:fire()
    local forceX = self.speed * -cos(rad(self.angle))
    local forceY = self.speed * -sin(rad(self.angle))

    self:applyForce(forceX, forceY)

    sounds:play(sounds.rifleShot)
end


return Projectile