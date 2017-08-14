local Character = {
    isCharacter = true
}


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
    local x    = self:x() + self.boneBarrel.worldX
    local y    = self:y() - self.boneBarrel.worldY

    self:animate("shoot_assault")

    if self.weapon.name == "shotgun" then
        local shot1 = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self.angle+75, filter=filter})
        local shot2 = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self.angle+90, filter=filter})
        local shot3 = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self.angle+105, filter=filter})

        shot1:fire()
        shot2:fire()
        shot3:fire()
    else
        local shot = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self.angle+90, filter=filter})
        shot:fire()
    end
end


return Character