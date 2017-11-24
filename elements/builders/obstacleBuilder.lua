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
    elseif spec.type == "securityDoor" then
        return self:newSecurityDoor(camera, spec)
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
    object.hits = 3

    camera:addEntity(object)

    return object
end


function ObstacleBuilder:newSecurityDoor(camera, spec)
    local door = builder:newSpineObject(spec, {
                       jsonName  = "securityDoor",
                       imagePath = "securityDoor",
                       animation = "closed"
                   })

    builder:deepCopy(obstacleDef, door)
    self:transform(door)

    door:setPhysics(false, 225, 37)
    -- This means that enemies wont be able to see through it, in the same way as tile walls
    door.image.isWall   = true
    door.isSecurityDoor = true
    door.hits           = 99999

    camera:addEntity(door)
    door:moveBy(35, 0)


    function door:open()
        sounds:general("doorOpen")
        self:animate("open")
        after(10, function() physics.removeBody(self.image) end)
    end


    function door:close()
        sounds:general("doorOpen")
        self:animate("close")
        after(10, function() self:setPhysics(false, 225, 37) end)
    end


    if door.guards == "entrance" then
        self:buildEntranceDoor(camera, door)

    elseif door.guards == "exit" then
        -- Create action to open door and remove the physics shape
        
    end

    return door
end


function ObstacleBuilder:buildEntranceDoor(camera, door)
    -- create a physics shape to open the door when the player gets near and allow them through, but not allow them to shoot or enemies rush through
    local sensor  = display.newRect(door:x(), door:y()+75, 450, 300)
    sensor.alpha  = 0
    sensor.isWall = true
    physics.addBody(sensor, "static", {isSensor=true, filter=Filters.collectable})
    
    sensor.collision = function(self, event)
        local other = event.other.object

        if other and other.isPlayer then
            if event.phase == "began" then
                if not self.removing then
                    other:lockShooting(true)
                    self.door:open()
                end

            elseif event.phase == "ended" or event.phase == "cancelled" then
                other:lockShooting(false)
                self.door:close()

                if other:y() < self.door:y() then
                    self.removing = true
                    after(10, function() physics.removeBody(self) end)
                end
            end
        end
    end

    sensor:addEventListener("collision", sensor)
    
    door.image:insert(sensor)
    camera:addCollectable(sensor)
    
    sensor.door = door
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