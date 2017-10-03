local Character = {
    isCharacter = true
}

-- Aliases:
local random = math.random


function Character:setWeaponBones(weapon)
    self.boneRoot = self.skeleton:getRootBone()
    
    if weapon.bone then
        self.boneBarrel = self.skeleton:findBone("barrel-"..weapon.bone)

        if weapon.name == "launcher" then
            self.boneGunRear = self.skeleton:findBone("launcher-rear")
        end
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


function Character:shootProjectile(projectileBuilder, camera, filter)
    self.flagShootAllowed = false

    local weapon = self.weapon
    local name   = weapon.name
    local ammo   = weapon.ammoType
    local angle  = self:getAngle()
    local x      = self:x() + self.boneBarrel.worldX
    local y      = self:y() - self.boneBarrel.worldY

    self:animate("shoot_"..name)

    if ammo == "bullet" then
        self:emit(ammo.."Shot", {xpos=x, ypos=y, duration=250, angle=angle-90})
    end

    if name == "shotgun" then
        level:createProjectile({xpos=x, ypos=y, angle=angle-10, filter=filter, powerupDamage=self.powerupDamage}, weapon)
        level:createProjectile({xpos=x, ypos=y, angle=angle,    filter=filter, powerupDamage=self.powerupDamage}, weapon)
        level:createProjectile({xpos=x, ypos=y, angle=angle+10, filter=filter, powerupDamage=self.powerupDamage}, weapon)
    else
        level:createProjectile({xpos=x, ypos=y, angle=angle, filter=filter, powerupDamage=self.powerupDamage}, weapon)
    end

    local rof = self.weapon.rof

    if self.powerupFastShoot then
        rof = rof / 2
    end

    after(rof, function() 
        self.flagShootAllowed = true 
    end)
end


function Character:shootReloadCheck(callback)
    self.ammo = self.ammo - 1

    if self.ammo <= 0 then
        local weapon = self.weapon

        sounds:projectile("reload")
        self:animate("reload_"..weapon.name)

        after(weapon.reload, function()
            self.ammo = weapon.ammo

            if self.powerupExtraAmmo then
                self.ammo = self.ammo + weapon.ammo
            end

            if callback then callback() end
        end)
    end
end


return Character