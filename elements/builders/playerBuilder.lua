local builder   = require("elements.builders.builder")
local playerDef = require("elements.player")

-- Class
local PlayerBuilder = {}


function PlayerBuilder:newPlayer(camera, spec)
    local player = builder:newSpineObject(spec, {
                       jsonName  = "playerBody", 
                       imagePath = "playerBody", 
                       skin      = spec.skin      or "Player",
                       scale     = spec.scale     or 0.5,  
                       animation = spec.animation or "run"
                   })

    player.legs = builder:newSpineObject(spec, {
                      jsonName  = "playerLegs", 
                      imagePath = "playerLegs", 
                      skin      = "Player", 
                      scale     = spec.scale or 0.5, 
                      animation = "run"
                  })

    -- Allow override of destroy()
    player.spineObjectDestroy = player.destroy
    -- Override updateSpine for multilpe spine animations
    player.updateSingleSpine  = player.updateSpine

    builder:deepCopy(playerDef, player)

    player:moveTo(player.xpos or 0, player.ypos or 0)
    player:setPhysics()
    player:visible()

    player.image:insert(player.legs.image)
    player.legs:moveTo(0, -5)
    player.legs:visible()

    self:applyCharacterAbilities(player)
    self:applyPlayerOptions(player)

    --camera:add(player.image, 3)
    camera:addEntity(player)
	
	  return player
end


function PlayerBuilder:applyPlayerOptions(player)
    -- apply animation after reset as that makes players stand:
    if player.animation then
        if player.dontLoop then
            player:animate(player.animation)
        else
            player:loop(player.animation)
        end
    end

    --[[if player.loadGear then
        for _,gear in pairs(player.loadGear) do
            player:setIndividualGear(gear)
        end
    end]]
end


function PlayerBuilder:applyCharacterAbilities(player)
end


return PlayerBuilder