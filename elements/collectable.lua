-- Class
local Collectable = {
    
    isCollectable = true,
    class         = "Collectable",
}

-- Aliases
local cos = math.cos
local sin = math.sin
local rad = math.rad
local abs = math.abs


function Collectable.eventCollision(self, event)
    local other = event.other.object
    local self  = self.object

    if other and other.isPlayer and event.phase == "began" then 
        self:collectedBy(other)
        self:destroy()
    end
end


function Collectable:setPhysics()
    physics.addBody(self.image, "static", {density=0, friction=0, bounce=0, filter=Filters.collectable})

    self.image.collision = Collectable.eventCollision
    self.image:addEventListener("collision", self.image)
end


function Collectable:collectedBy(player)
    if self.object == "weapon" then
        --sounds:collectable("gotWeapon")
        sounds:voice(Weapons[self.type].name)
        player:setWeapon(Weapons[self.type])

    elseif self.object == "jewel" then
        sounds:collectable("gotJewel")
        player:addPoints(self.points or 5)

    elseif self.object == "powerup" then
        --sounds:collectable("gotWeapon")
        sounds:voice(self.type)

        if     self.type == Powerups.health     then player:heal(self.health)
        elseif self.type == Powerups.damage     then player:extraDamage()
        elseif self.type == Powerups.fastMove   then player:fastMove()
        elseif self.type == Powerups.fastShoot  then player:fastShoot()
        elseif self.type == Powerups.extraAmmo  then player:extraAmmo()
        elseif self.type == Powerups.shield     then player:shield()
        elseif self.type == Powerups.laserSight then player:laserSight()
        end
    end

    self:emit("collectFlash-left")
    self:emit("collectFlash-right")
end


function Collectable:onStart()
    self:bindEmitter("collectable")
end


return Collectable