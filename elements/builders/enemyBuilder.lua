local builder  = require("elements.builders.builder")
local enemyDef = require("elements.enemy")

-- Class
local EnemyBuilder = {}


function EnemyBuilder:newEnemy(camera, spec)
    -- Copy the enemy rank def and reference the modifyImage before spien creation
    local rankDef = builder:newClone(EnemyTypes[spec.type][spec.rank])
    spec.modifyImage = rankDef.modifyImage

    local enemy = builder:newSpineObject(spec, {
                       jsonName  = "enemyBodyReptile",
                       imagePath = "enemyBody/Lizard Basic",
                       skin      = spec.skin      or "lizard_basic",
                       scale     = spec.scale     or 0.5,  
                       animation = spec.animation or "run"
                   })

    enemy.legs = builder:newSpineObject(spec, {
                      jsonName  = "enemyLegsReptile", 
                      imagePath = "enemyLegs/lizard_basic", 
                      skin      = "lizard_basic", 
                      scale     = spec.scale or 0.5, 
                      animation = "run"
                  })

    -- Allow override of destroy()
    enemy.spineObjectDestroy = enemy.destroy

    -- Copy basic enemy definition and then specific rank definition ontop
    builder:deepCopy(enemyDef, enemy)
    builder:deepCopy(rankDef,  enemy)

    -- apply weapon if specified, otherwise they are melee-only enemy
    if enemy.weapon then
        enemy.weapon = Weapons[enemy.weapon]
        enemy.ammo   = enemy.weapon.ammo
    end

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

    camera:addEntity(enemy, enemy.xpos, enemy.ypos)
    
   return enemy
end


return EnemyBuilder