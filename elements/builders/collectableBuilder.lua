local builder        = require("elements.builders.builder")
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

    collectable:moveTo(collectable.xpos or 0, collectable.ypos or 0)
    collectable:setPhysics()

    camera:add(collectable.image, 4)

    return collectable
end


return CollectableBuilder