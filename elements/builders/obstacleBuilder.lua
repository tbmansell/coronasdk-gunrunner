local obstacleDef = require("elements.obstacle")

-- Class
local ObstacleBuilder = {}


function ObstacleBuilder:newItem(camera, spec)
    if spec.type == "crate" then
        return self:newCrate(camera, spec)
    elseif spec.type == "gas" then
        return self:newGas(camera, spec)
    elseif spec.type == "computer" then
        return self:newComputer(camera, spec)
    end
end


function ObstacleBuilder:newCrate(camera, spec)
    local image  = display.newImage("images/obstacles/"..spec.type.."-"..spec.variant..".png", 0, 0)
    local object = builder:newGameObject(spec, image)

    builder:deepCopy(obstacleDef, object)
    self:transform(object)

    object:setPhysics()
    object.isCrate = true

    if spec.variant == "big" then
        object.hits = 4
    else
        object.hits = 2
    end

    camera:addEntity(object)

    return object
end


function ObstacleBuilder:newGas(camera, spec)
    local image  = display.newImage("images/obstacles/"..spec.type.."-"..spec.variant..".png", 0, 0)
    local object = builder:newGameObject(spec, image)

    builder:deepCopy(obstacleDef, object)
    self:transform(object)
    
    object:setPhysics()
    object.isGas = true
    
    if spec.variant == "big" then
        object.hits   = 4
        object.weapon = EnvironmentalWeapon.gasBig
    else
        object.hits   = 2
        object.weapon = EnvironmentalWeapon.gasSmall
    end

    camera:addEntity(object)

    return object
end


function ObstacleBuilder:newComputer(camera, spec)
    local image  = display.newImage("images/obstacles/"..spec.type.."-"..spec.variant..".png", 0, 0)
    local object = builder:newGameObject(spec, image)

    builder:deepCopy(obstacleDef, object)
    self:transform(object)

    object:setPhysics()
    object.isComputer = true
    object.hits = 1

    camera:addEntity(object)

    return object
end


function ObstacleBuilder:newWall(camera, spec)
    local image = display.newImage("images/obstacles/"..spec.type..".png", 0, 0)
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