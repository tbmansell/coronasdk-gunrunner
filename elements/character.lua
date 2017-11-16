local Character = {
    isCharacter = true
}

-- Aliases:
local random = math.random


function Character:setWeaponBones(weapon)
    self.boneRoot = self.skeleton:getRootBone()
    
    if weapon.bone then
        self.boneBarrel = self.skeleton:findBone("barrel-"..weapon.bone)

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

    return self.angle - 5 + a
end


function Character:shootProjectile(projectileBuilder, camera, filter, reloadCallback)
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
        rof = rof / 2
    end

    after(rof, function()
        self.flagShootAllowed = true
        self:loop(self.stationaryAnim)

        local reload = self:shootReloadCheck(reloadCallback)

        if weapon.burst and not reload then
            if self.burst then 
                self.burst = self.burst - 1
                if self.burst == 1 then self.burst = nil end
            else
                self.burst = weapon.burst
            end 

            if self.burst then
                self:shootProjectile(projectileBuilder, camera, filter, reloadCallback)
            end           
        end
    end)
end


function Character:shootReloadCheck(callback)
    self.ammo = self.ammo - 1

    if self.ammo <= 0 then
        -- reload
        local weapon = self.weapon

        sounds:projectile("reload")
        self:animate("reload_"..weapon.name)

        if callback then callback() end

        after(weapon.reload, function()
            self.ammo = weapon.ammo

            if self:hasExtraAmmo() then
                self.ammo = self.ammo + weapon.ammo
            end

            if callback then callback() end
        end)
        return true
    end
    return false
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