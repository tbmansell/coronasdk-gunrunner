local builder  = require("elements.builders.builder")
local enemyDef = require("elements.enemy")

-- Class
local EnemyBuilder = {}


function EnemyBuilder:newEnemy(camera, spec)
    local enemy = builder:newSpineObject(spec, {
                       jsonName  = "playerBody", 
                       imagePath = "playerBody", 
                       skin      = spec.skin      or "Player",
                       scale     = spec.scale     or 0.5,  
                       animation = spec.animation or "run"
                   })

    enemy.legs = builder:newSpineObject(spec, {
                      jsonName  = "playerLegs", 
                      imagePath = "playerLegs", 
                      skin      = "Player", 
                      scale     = spec.scale or 0.5, 
                      animation = "run"
                  })

    -- Allow override of destroy()
    enemy.spineObjectDestroy = enemy.destroy

    builder:deepCopy(enemyDef, enemy)

    enemy.aggression = spec.aggression or 50

    enemy:moveTo(enemy.xpos or 0, enemy.ypos or 0)
    enemy:setPhysics()
    enemy:visible()

    enemy.image:insert(enemy.legs.image)
    enemy.legs:moveTo(0, -5)
    enemy.legs:visible()
    
    -- apply animation after reset as that makes enemys stand:
    if spec.animation then
        if spec.dontLoop then
            enemy:animate(spec.animation)
        else
            enemy:loop(spec.animation)
        end
    end

    if spec.angle then
        enemy:rotate(spec.angle)
    end

    -- apply weapon if specified, otherwise they are melee-only enemy


    --sounds:loadPlayer(spec.model)
    --camera:add(enemy.image, 3, true)
    
      return enemy
end


return EnemyBuilder