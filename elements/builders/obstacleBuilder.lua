local builder     = require("elements.builders.builder")
local obstacleDef = require("elements.obstacle")

-- Class
local ObstacleBuilder = {}


function ObstacleBuilder:newWall(camera, spec)
    local image = display.newImage("images/obstacles/wall-"..spec.type..".png", 0, 0)
    local wall  = builder:newGameObject(spec, image)

    builder:deepCopy(obstacleDef, wall)
    self:transform(wall)

    wall:moveTo(wall.xpos or 0, wall.ypos or 0)
    wall:setPhysics()

    --camera:add(wall.image, 4)

    return wall
end


function ObstacleBuilder:transform(wall)
    if wall.size then
        wall.image:scale(wall.size, wall.size)
    end

    if wall.flip == "x" then 
        wall:flipX() 
    end
    
    if wall.flip == "y" then 
        wall:flipY() 
    end

    if wall.darken then
        wall.image:setFillColor(wall.darken)
    elseif wall.rgb then
        wall.image:setFillColor(wall.rgb[1], wall.rgb[2], wall.rgb[3])
    end

    if wall.rotation then
        wall:rotate(wall.rotation)
    end
end


return ObstacleBuilder