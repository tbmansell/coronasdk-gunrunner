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

    if other and other.isPlayer then 
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
    print(tostring(self.object).." collectedBy player")

    if self.object == "weapon" then
        sounds:collectable("gotWeapon")
        player:setWeapon(Weapons[self.type])
    end
end


return Collectable