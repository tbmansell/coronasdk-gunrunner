local enemyDef = require("elements.enemy")

-- Class
local EnemyBuilder = {}


local random = math.random


function EnemyBuilder:newEnemy(camera, spec)
    if spec.type == "turret" then
        return self:newTurret(camera, spec)
    else
        return self:newMovingEnemy(camera, spec)
    end
end


function EnemyBuilder:newMovingEnemy(camera, spec)
    --print("Enemy: rank="..tostring(spec.rank).." type="..tostring(spec.type).." pos="..tostring(spec.xpos)..", "..tostring(spec.ypos))

    -- Copy the enemy rank def and reference the modifyImage before spien creation
    local rankDef = builder:newClone(EnemyTypes[spec.type][spec.rank])
    local anim    = spec.animation or "stationary_1"

    spec.modifyImage = rankDef.modifyImage

    --print("Enemy: rank="..spec.rank.." skin="..(spec.skin or rankDef.skin).." pos="..tostring(spec.xpos)..", "..tostring(spec.ypos))

    local enemy = builder:newCharacter(spec, {
                       jsonName  = "characterBody",
                       imagePath = "character",
                       skin      = spec.skin  or rankDef.skin,
                       scale     = spec.scale or 0.5, 
                       animation = anim
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

    enemy.image:insert(enemy.legs.image)
    enemy.legs:moveTo(0, -5)
    enemy.legs:visible()

    self:setupEnemyCommon(camera, enemy, spec)

    enemy.stationaryAnim = anim
        
    return enemy
end


function EnemyBuilder:newTurret(camera, spec)
    -- Copy the enemy rank def and reference the modifyImage before spien creation
    local rankDef = builder:newClone(EnemyTypes[spec.type][spec.rank])
    local scale   = spec.scale     or 0.5
    local anim    = spec.animation or "scanningTargets"

    spec.modifyImage = rankDef.modifyImage
    spec.physicsBody = "static"

    local enemy = builder:newCharacter(spec, {
                       jsonName  = "turret",
                       imagePath = "character",
                       skin      = spec.skin or rankDef.skin,
                       scale     = scale, 
                       animation = anim
                   })

    -- Allow override of destroy()
    enemy.spineObjectDestroy = enemy.destroy

    -- Copy basic enemy definition and then specific rank definition ontop
    builder:deepCopy(enemyDef, enemy)
    builder:deepCopy(rankDef,  enemy)

    enemy.base = display.newImage("images/character/turrets/turret-base.png", 0, 0)
    enemy.base:scale(scale, scale)
    enemy.image:insert(enemy.base)

    self:setupEnemyCommon(camera, enemy, spec)

    enemy.isTurret        = true
    enemy.flagMoveAllowed = false
    enemy.stationaryAnim  = anim

    function enemy:updateSpine(delta)
        self.state:update(delta)
        self.state:apply(self.skeleton)
        self.boneRoot.rotation = -(self.angle)
        self.skeleton:updateWorldTransform()
    end
    
    return enemy
end


function EnemyBuilder:setupEnemyCommon(camera, enemy, spec)
    -- apply weapon
    enemy.weapon = Weapons[enemy.weapon]
    enemy.ammo   = enemy.weapon.ammo

    enemy:setWeapon(enemy.weapon)
    enemy:setPhysics()
    enemy:visible()
    
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
end


return EnemyBuilder