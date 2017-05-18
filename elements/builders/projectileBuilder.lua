local builder       = require("elements.builders.builder")
local projectileDef = require("elements.projectile")

-- Class
local ProjectileBuilder = {}


function ProjectileBuilder:newShot(camera, weapon, spec)
    local image = display.newImage("images/projectiles/"..weapon.ammoType..".png", 0, 0)
    local shot  = builder:newGameObject(spec, image)

    builder:deepCopy(projectileDef, shot)

    shot.speed  = weapon.speed
    shot.damage = weapon.damage
    shot.filter = spec.filter

    shot:moveTo(spec.xpos or 0, spec.ypos or 0)
    shot:setPhysics()

    if spec.angle then
        shot:rotate(spec.angle)
    end

    return shot
end


return ProjectileBuilder