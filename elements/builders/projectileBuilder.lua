local builder       = require("elements.builders.builder")
local projectileDef = require("elements.projectile")

-- Class
local ProjectileBuilder = {}


function ProjectileBuilder:newShot(camera, weapon, spec)
    local image = display.newImage("images/projectiles/"..weapon.ammoType..".png", 0, 0)
    local shot  = builder:newGameObject(spec, image)

    builder:deepCopy(projectileDef, shot)

    shot.weapon = weapon
    shot.filter = spec.filter
    shot.angle  = spec.angle

    shot:moveTo(spec.xpos or 0, spec.ypos or 0)
    shot:setPhysics()

    camera:addProjectile(shot)

    return shot
end


return ProjectileBuilder