local projectileDef = require("elements.projectile")

-- Class
local ProjectileBuilder = {}


function ProjectileBuilder:newShot(camera, weapon, spec)
    local image = display.newImage("images/projectiles/"..weapon.ammoType..".png", 0, 0)
    local shot  = builder:newGameObject(spec, image)

    builder:deepCopy(projectileDef, shot)

    shot.weapon   = weapon
    shot.filter   = spec.filter
    shot.angle    = spec.angle
    shot.ricochet = weapon.ricochet

    shot:moveTo(spec.xpos or 0, spec.ypos or 0)
    shot:setPhysics()

    camera:addProjectile(shot)

    return shot
end


function ProjectileBuilder:newAreaOfEffect(camera, spec)
    local area = display.newCircle(spec.xpos or 0, spec.ypos or 0, spec.area)
    area.alpha = 0

    after(10, function()
        physics.addBody(area, "dynamic", {density=1, friction=0, bounce=0, radius=spec.area, filter=spec.filter})
    end)

    area.collision = function(self, event)
        local other = event.other.object

        if other and event.phase == "began" then
            spec.effect(other)
        end
    end

    area:addEventListener("collision", image)

    camera:addProjectile(area)

    after(100, function() area:removeSelf() end)

    return area
end


return ProjectileBuilder