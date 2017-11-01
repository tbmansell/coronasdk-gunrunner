local collectableDef = require("elements.collectable")

-- Class
local CollectableBuilder = {}


function CollectableBuilder:newItem(camera, spec)
    local image        = display.newImage("images/collectables/"..spec.type..".png", 0, 0)
    local collectable  = builder:newGameObject(spec, image)

    builder:deepCopy(collectableDef, collectable)
    
    if collectable.size then
        collectable.image:scale(collectable.size, collectable.size)
    end

    collectable:moveTo(spec.xpos or 0, spec.ypos or 0)
    collectable:setPhysics()

    if collectable.dontReposition then
        camera:addCollectable(collectable)
    else
        camera:addEntity(collectable, false, 1)
    end

    return collectable
end


return CollectableBuilder