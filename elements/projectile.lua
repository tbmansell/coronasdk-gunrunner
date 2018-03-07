-- Class
local Projectile = {
    
    isProjectile = true,
    class        = "Projectile",
}

-- Aliases
local cos     = math.cos
local sin     = math.sin
local rad     = math.rad
local abs     = math.abs
local indexOf = indexOf


function Projectile.eventCollision(self, event)
    local other = event.other.object or event.other
    local self  = self.object

    if other and event.phase == "began" then
        if other.isPlayer or other.isEnemy or other.isObstacle then
            other:hit(self)
        end

        if self.ricochet and other.isWall then
            self:bounce(false)
        else
            self:impact(other.isWall, other)
        end
    end
end


function Projectile:setPhysics(isSensor)
    local bounce = 0
    local shape  = nil

    if self.ricochet then
        bounce = 1
    end

    if self.isFlame then
        shape = {-30,180, 30,180, 5,0, -5,0}
    end

    physics.addBody(self.image, "dynamic", {isSensor=isSensor, density=0, friction=0, bounce=bounce, shape=shape, filter=self.filter})

    self.image.collision = Projectile.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Projectile:removePhysics()
    physics.removeBody(self.image)
    self.image:removeEventListener("collision", self.image)
    self.image.collision = nil
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

    elseif weapon.ammoType == "laserBolt" then
        self:bindEmitter("laserBolt", {angle=self.image.rotation})
        self.image:insert(self.boundEmitter)
        self.boundEmitter.x = 0
        self.boundEmitter.y = 0

    elseif weapon.ammoType == "flame" then
        self:bindEmitter("flamer", {angle=self.image.rotation})
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


function Projectile:impact(isWall, target)
    sounds:projectile(self.weapon.hitSound)
    self:displayImpact(isWall, target)

    if self.weapon.area then
        local effect = function(target)
            if target.hit then target:hit(self) end
        end

        level:createAreaOfEffect({xpos=self:x(), ypos=self:y(), area=self.weapon.area, filter=self.filter, effect=effect})
    end

    if (self.shootThrough == nil or isWall) and not self.isFlame then
        self:destroy()
    end
end


function Projectile:displayImpact(isWall, target)
    local particle = self.weapon.hitAnim

    if particle then
        if self.isFlame then
            if isWall then
                self:emit(particle, {xpos=target.x, ypos=target.y})
            else
                self:emit(particle, {xpos=target:x(), ypos=target:y()})
            end
        else
            self:emit(particle)
        end

        if self.weapon.hitAnim2nd then
            self:emit(self.weapon.hitAnim2nd)
        end
    end
end


return Projectile