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

    builder:deepCopy(playerDef, player)

    player:moveTo(player.xpos or 0, player.ypos or 0)
    player:setPhysics()
    player:visible()

    player.image:insert(player.legs.image)
    player.legs:moveTo(0, -5)
    player.legs:visible()

    self:applyCharacterAbilities(player)
    self:applyPlayerOptions(camera, spec, player)

    --sounds:loadPlayer(spec.model)
    --camera:add(player.image, 3, true)
	
	  return player
end


function PlayerBuilder:applyPlayerOptions(camera, spec, player)
    -- apply animation after reset as that makes players stand:
    if spec.animation then
        if spec.dontLoop then
            player:animate(spec.animation)
        else
            player:loop(spec.animation)
        end
    end

    if spec.loadGear then
        for _,gear in pairs(spec.loadGear) do
            player:setIndividualGear(gear)
        end
    end
end


function PlayerBuilder:applyCharacterAbilities(player)
end


return PlayerBuilder