local playerDef = require("elements.player")

-- Class
local PlayerBuilder = {}


function PlayerBuilder:newPlayer(camera, spec, hud)
    local anim = spec.animation or "run_rifle"

    local player = builder:newCharacter(spec, {
                       jsonName  = "characterBody", 
                       imagePath = "character", 
                       skin      = spec.skin      or "player_basic",
                       scale     = spec.scale     or 0.5,
                       animation = anim
                   })
    
    player.legs = builder:newSpineObject(spec, {
                      jsonName  = "characterLegs", 
                      imagePath = "character", 
                      skin      = "player_basic", 
                      scale     = spec.scale or 0.5,
                      animation = "run"
                      --run_fast
                      --run_slow
                      --strafe_left
                      --strafe_right
                      --stationary
                  })
  
    -- Allow override of destroy()
    player.spineObjectDestroy = player.destroy
    -- Override updateSpine for multilpe spine animations
    player.updateSingleSpine  = player.updateSpine

    builder:deepCopy(playerDef, player)

    player.key            = "ThePlayer"
    player.gear           = {}
    player.powerups       = {}
    player.stationaryAnim = anim
    player:moveTo(player.xpos or 0, player.ypos or 0)
    player:setPhysics()
    player:visible()
    player.image:insert(player.legs.image)
    player.legs:moveTo(0, -5)
    player.legs:visible()

    self:applyCharacterAbilities(player)
    self:applyPlayerOptions(player)
    self:applyPlayerHooks(player, hud)

    --print("place player")
    camera:addEntity(player, true)
    --print("placed player")
	
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
end


function PlayerBuilder:applyCharacterAbilities(player)
end


function PlayerBuilder:applyPlayerHooks(player, hud)
    -- update hud with current ammo counter
    function player:hookAmmoCounter() 
        hud:updateAmmoCounter(self.ammo) 
    end

    -- Update hud with player health
    function player:updateHudHealth()
        hud:updateHealth(self)
    end
    
    -- Update hud movement speed
    function player:updateHudSpeed()
        hud:updateSpeed(self)
    end
end


return PlayerBuilder