local enemyDef = require("elements.enemy")

-- Class
local EnemyBuilder = {}


function EnemyBuilder:newEnemy(camera, spec)
    -- Copy the enemy rank def and reference the modifyImage before spien creation
    local rankDef = builder:newClone(EnemyTypes[spec.type][spec.rank])
    spec.modifyImage = rankDef.modifyImage


    local enemy = builder:newCharacter(spec, {
                       jsonName  = "characterBody",
                       imagePath = "character",
                       skin      = spec.skin      or rankDef.skin,
                       scale     = spec.scale     or 0.5, 
                       animation = spec.animation or "stationary_1" --"run_assault"
                   })
    
    enemy.legs = builder:newSpineObject(spec, {
                      jsonName  = "characterLegs", 
                      imagePath = "character", 
                      skin      = "lizard_assault", 
                      scale     = spec.scale or 0.5, 
                      animation = "stationary"
                  })

    -- Allow override of destroy()
    enemy.spineObjectDestroy = enemy.destroy

    -- Copy basic enemy definition and then specific rank definition ontop
    builder:deepCopy(enemyDef, enemy)
    builder:deepCopy(rankDef,  enemy)

    -- apply weapon
    enemy.weapon = Weapons[enemy.weapon]
    enemy.ammo   = enemy.weapon.ammo

    enemy:setWeapon(enemy.weapon)
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

    camera:addEntity(enemy)
    
   return enemy
end


return EnemyBuilder