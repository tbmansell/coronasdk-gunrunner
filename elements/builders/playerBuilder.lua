local playerDef = require("elements.player")

-- Class
local PlayerBuilder = {}


function PlayerBuilder:newPlayer(camera, spec)
    local player = builder:newCharacter(spec, {
                       jsonName  = "characterBody", 
                       imagePath = "character", 
                       skin      = spec.skin      or "player_basic",
                       scale     = spec.scale     or 0.5,  
                       animation = spec.animation or "run_assault"
                   })
    
    player.legs = builder:newSpineObject(spec, {
                      jsonName  = "characterLegs", 
                      imagePath = "character", 
                      skin      = "player_basic", 
                      scale     = spec.scale or 0.5, 
                      animation = "run"
                  })
  
    -- Allow override of destroy()
    player.spineObjectDestroy = player.destroy
    -- Override updateSpine for multilpe spine animations
    player.updateSingleSpine  = player.updateSpine

    builder:deepCopy(playerDef, player)

    player.key  = "ThePlayer"
    player.gear = {}
    player:moveTo(player.xpos or 0, player.ypos or 0)
    player:setPhysics()
    player:visible()

    player.image:insert(player.legs.image)
    player.legs:moveTo(0, -5)
    player.legs:visible()

    self:applyCharacterAbilities(player)
    self:applyPlayerOptions(player)

    camera:addEntity(player, true)
	
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