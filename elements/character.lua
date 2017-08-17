local Character = {
    isCharacter = true
}

-- Aliases:
local random = math.random


function Character:shootAmmoRof()
    self.flagShootAllowed = false
    self.ammo = self.ammo - 1

    -- enable more firing after ROF period ending
    after(self.weapon.rof, function() 
        self.flagShootAllowed = true 
    end)
end


function Character:shootReloadCheck(callback)
    if self.ammo <= 0 then
        sounds:projectile("reload")

        after(1500, function()
            self.ammo = self.weapon.ammo

            if callback then callback() end
        end)
    end
end


function Character:shootProjectile(projectileBuilder, camera, filter)
    local x = self:x() + self.boneBarrel.worldX
    local y = self:y() - self.boneBarrel.worldY

    self:animate("shoot_assault")

    if self.weapon.name == "shotgun" then
        local angle = self:getAngle()

        local shot1 = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=angle-10, filter=filter})
        local shot2 = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=angle,    filter=filter})
        local shot3 = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=angle+10, filter=filter})

        shot1:fire()
        shot2:fire()
        shot3:fire()
    else
        local shot = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self:getAngle(), filter=filter})
        shot:fire()
    end
end


function Character:getAngle(offset)
    local a = offset or 90

    if self.inaccuracy then
        local r = random(100)

        if r <= self.inaccuracy then
            if random(100) > 50 then
                a = a - r
            else
                a = a + r
            end
        end
    end

    return self.angle + a
end


return Character