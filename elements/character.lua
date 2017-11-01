local Character = {
    isCharacter = true
}

-- Aliases:
local random = math.random


function Character:setWeaponBones(weapon)
    self.boneRoot = self.skeleton:getRootBone()
    
    if weapon.bone then
        print("Looking for bone: barrel-"..weapon.bone.." for weapon "..weapon.name)
        self.boneBarrel = self.skeleton:findBone("barrel-"..weapon.bone)

        print("found? "..tostring(self.boneBarrel))

        --[[if weapon.name == "launcher" then
            self.boneGunRear = self.skeleton:findBone("launcher-rear")
        end]]
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
    local damage = self:hasExtraDamage()
    local angle  = self:getAngle()
    local x      = self:x() + self.boneBarrel.worldX
    local y      = self:y() - self.boneBarrel.worldY

    self:animate("shoot_"..name)

    if name == "shotgun" then
        level:createProjectile({xpos=x, ypos=y, angle=angle-10, filter=filter, powerupDamage=damage}, weapon)
        level:createProjectile({xpos=x, ypos=y, angle=angle,    filter=filter, powerupDamage=damage}, weapon)
        level:createProjectile({xpos=x, ypos=y, angle=angle+10, filter=filter, powerupDamage=damage}, weapon)
    else
        level:createProjectile({xpos=x, ypos=y, angle=angle, filter=filter, powerupDamage=damage}, weapon)
    end

    local rof = self.weapon.rof

    if self:hasFastShoot() then
        print("fast shoot")
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

            if self:hasExtraAmmo() then
                self.ammo = self.ammo + weapon.ammo
            end

            if callback then callback() end
        end)
    end
end


function Character:hasFastShoot()
    return false
end


function Character:hasExtraDamage()
    return false
end


function Character:hasExtraAmmo()
    return false
end


return Character