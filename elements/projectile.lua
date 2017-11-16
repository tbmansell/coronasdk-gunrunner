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

    if other and event.phase == "began" then
        if other.isPlayer or other.isEnemy or other.isObstacle then 
            other:hit(self)
        end

        if self.ricochet and other.isWall then
            self:bounce(false)
        else
            self:impact(other.isWall)
        end
    end
end


function Projectile:setPhysics(isSensor)
    local bounce = 0

    if self.ricochet then
        bounce = 1
    end

    physics.addBody(self.image, "dynamic", {isSensor=isSensor, density=0, friction=0, bounce=bounce, filter=self.filter})

    self.image.collision = Projectile.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Projectile:fire()
    local weapon = self.weapon
    local forceX = weapon.speed * -cos(rad(self.angle))
    local forceY = weapon.speed * -sin(rad(self.angle))

    self:flipY()
    -- dont call rotate() as this changes the angle
    self.image.rotation = self.angle + 90

    self:applyForce(forceX, forceY)

    sounds:projectile(weapon.shotSound)

    if weapon.ammoType == "rocket" then
        self:bindEmitter("rocketBlast")
        self.image:insert(self.boundEmitter)
        self.boundEmitter.x = 0
        self.boundEmitter.y = 0
    end
end


function Projectile:getDamage()
    if self.powerupDamage then
        return self.weapon.damage * self.powerupDamage
    else
        return self.weapon.damage
    end
end


function Projectile:bounce(fromWall)
    if self.ricochet then
        self.ricochet = self.ricochet - 1

        if self.ricochet <= 0 then
            self.ricochet = nil
        end
    end
end


function Projectile:impact(isWall)
    sounds:projectile(self.weapon.hitSound)
    self:displayImpact()

    if self.weapon.area then
        local effect = function(target)
            if target.hit then target:hit(self) end
        end

        level:createAreaOfEffect({xpos=self:x(), ypos=self:y(), area=self.weapon.area, filter=self.filter, effect=effect})
    end

    if self.shootThrough == nil or isWall then
        self:destroy()
    end
end


function Projectile:displayImpact()
    local particle = self.weapon.hitAnim

    if particle then
        self:emit(particle)

        if self.weapon.hitAnim2nd then
            self:emit(self.weapon.hitAnim2nd)
        end
    end
end


return Projectile