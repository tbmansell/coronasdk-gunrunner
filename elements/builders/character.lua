local projectileBuilder = require("elements.builders.projectileBuilder")


local Character = {
    isCharacter = true
}


function Character:fireProjectile(filter)
    local x    = self:x() + self.boneBarrel.worldX
    local y    = self:y() - self.boneBarrel.worldY

    if self.weapon.name == "shotgun" then
        local shot = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self.angle+90, filter=filter})
        shot:fire()
    else
        local shot = projectileBuilder:newShot(camera, self.weapon, {xpos=x, ypos=y, angle=self.angle+90, filter=filter})
        shot:fire()
    end
end


return Character