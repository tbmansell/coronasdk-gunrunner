local anim        = require("core.animations")
local spine       = require("core.spine")
--local soundEngine = require("core.sound-engine")

-- Class
local Player = {

    isPlayer      = true,
    class         = "Player",
    intHeight     = 25,
    intWidth      = 25,
    verticalSpeed = 10,--4,
    strafeSpeed   = 10,--4,

    mode          = PlayerMode.ready,
    health        = 20,
    gear          = {},  -- array have to be set by the builder due to deep copy problems
    shielded      = false,
    weapon        = nil,
    ammo          = 0,
    boneBarrel    = nil,

    flagShootAllowed = true,
}

-- Aliases:
local random= math.random


function Player:updateSpine(delta)
    self.state:update(delta)
    self.state:apply(self.skeleton)

    self.boneRoot.rotation = - (self.angle + 30)

    self.skeleton:updateWorldTransform()
    
    self.legs:updateSpine(delta)
end


function Player:topEdge()
    return self.image.y - self.intHeight
end


function Player:bottomEdge()
    return self.image.y
end


function Player:width()
    return self.intWidth
end


function Player:height()
    return self.intHeight
end


function Player:midHeight()
    return self.image.y - (self.intHeight/2)
end


function Player:isDead()
    return self.mode == PlayerMode.dead
end


function Player:canMove()
    return self.mode ~= PlayerMode.dead
end


function Player:canJump()
    return self.mode ~= PlayerMode.dead
end


function Player:canAim()
    return self.mode ~= PlayerMode.dead
end


function Player:canShoot()
    return self.mode ~= PlayerMode.dead and self.flagShootAllowed and self.ammo > 0
end


function Player:shoot(camera, ammoCounter)
    if self:canShoot() then
        self:shootProjectile(projectileBuilder, camera, Filters.playerShot)
        self:shootReloadCheck(function() self:hookAmmoCounter() end)
        self:hookAmmoCounter()
    end
end



---- override
function Player:rotate(rotation, event)
    if self.image then
        self.angle = rotation
    end
end


function Player:setMode(mode, aliveOnly)
    -- aliveOnly to be used so we dont accidentally overwrite status if currently dead
    if not aliveOnly or not self:isDead() then
        self.mode = mode
    end
end


function Player:setPhysics()
    physics.addBody(self.image, (self.physicsBody or "dynamic"), {radius=self.intWidth, density=1, friction=1, bounce=0, filter=Filters.player})
   
    self.image.isFixedRotation   = true
    self.image.isSleepingAllowed = false
end


function Player:setPhysicsFilter(action)
    local filter = self:selectFilter(action)

    if self.physicsFilterPrev ~= filter then
        self.physicsFilterPrev = filter

        local xvel, yvel = self:getForce()
        physics.removeBody(self.image)

        self:setPhysics(self:getCamera().scaleImage, filter)

        if xvel ~= 0 or yvel ~= 0 then
            self:applyForce(xvel, yvel)
        end

        -- if on an obstable then keep player from falling off
        if self.attachedObstacle then
            self.image.gravityScale = 0
        end
    end
end


function Player:selectFilter(action)
    if action == "addShield" then
        return Filters.playerShielded
    
    elseif action == "removeShield" then
        if self.mode == PlayerMode.jump then
            return Filters.playerJumping
        else 
            return Filters.player
        end
    elseif action == "jump" then
        if self.shielded then
            return Filters.playerShielded
        else
            return Filters.playerJumping
        end
    elseif action == "land" then
        if self.shielded then
            return Filters.playerShielded
        else 
            return Filters.player
        end
    else
        return Filters.player
    end
end


function Player:startLevelSequence()
    self:pose()
    self:loop("run_"..self.weapon.name)
end


----------------- FUNCTIONS TO HANDLE BEING KILLED -------------------


function Player:hit(shot)
    if not self:isDead() then
        if not self.shielded or shot.weapon.shieldBuster then
            self.health = self.health - shot.weapon.damage
            
            sounds:player("hurt")
            self:animate("hit_1")
            self:updateHudHealth()

            if self.health < 0 then
                self:explode()
            end
        end 
    end
end


function Player:explode(sound, message)
    if not self:isDead() then
        self.mode = PlayerMode.dead

        --[[if self.runSound then
            self:stopSound(self.runSound)
            self.runSound = nil
        end]]

        sounds:player(sound or "killed")

        self:destroyEmitter()
        self:stopMomentum(true)
        self:animate(animation or "death_"..random(2))

        local seq = anim:chainSeq("die", self.image)
        seq:tran({time=1000, alpha=0})
        seq.onComplete = function()
            self:hide()
            self:failedCallback() 
        end
        seq:start()

        if message then
            hud:displayMessageDied(message)
        end
    end
end


function Player:fallToDeath(hole)
    if not self:isDead() then
        self.mode = PlayerMode.dead

        --[[if self.runSound then
            self:stopSound(self.runSound)
            self.runSound = nil
        end]]

        sounds:player("killed")

        self:destroyEmitter()
        self:stopMomentum(true)
        --self:animate(animation or "death_"..random(2))

        local seq = anim:chainSeq("die", self.image)
        seq:tran({time=1000, x=hole.x, y=hole.y, xScale=0.01, yScale=0.01, alpha=0})
        seq.onComplete = function()
            self:hide()
            self:failedCallback() 
        end
        seq:start()
    end
end


function Player:destroy(camera, destroyBoundItems)
    self:spineObjectDestroy(camera, destroyBoundItems)
end


----------------- FUNCTIONS TO HANDLE GEAR ------------------- 


function Player:setWeapon(weapon)
    self.weapon            = weapon
    self.ammo              = weapon.ammo
    self.flagShootAllowed  = true
    self.gear["weapon"]    = {slot=weapon.slot, skin=weapon.skin}
    
    self:loadGear()
    self:setWeaponBones(weapon)
    self:loop("run_"..weapon.name)
    self:hookAmmoCounter()
end


function Player:setGear(item)
    self.gear[item.name] = {slot=item.slot, skin=item.skin}
    self:loadGear()
end


function Player:removeGear(item)
    self.gear[item.name] = nil
    self:loadGear()
end


function Player:pose()
    self.skeleton:setToSetupPose()
    self:loadGear()
end


function Player:loadGear()
    for name, item in pairs(self.gear) do
        if item then
            self.skeleton:setAttachment(item.slot, item.skin)
        else
            self.skeleton:setAttachment(item.slot, nil)
        end
    end
end


-- Replaces gameObject:sound()
-- @param string action - name of the sound (under global sounds) which also double as the action name for a managed sound
-- @param table  param  - optional list of sound properties
----
function Player:sound(action, params)
    local params = params or {}

    -- The following are special actions that get a random sound to play
    if     action == "randomJump"        then params.sound = soundEngine:getPlayerJump(self.model)
    elseif action == "randomWorry"       then params.sound = soundEngine:getPlayerWorry(self.model)
    elseif action == "randomCelebrate"   then params.sound = soundEngine:getPlayerCelebrate(self.model)
    elseif action == "randomImpactVoice" then params.sound = soundEngine:getPlayerImpact(self.model)
    elseif action == "randomFall"        then params.sound = soundEngine:getRandomPlayerFall()
    elseif action == "randomImpact"      then params.sound = soundEngine:getRandomImpact()
    elseif action == "randomRing"        then params.sound = soundEngine:getRandomRing()
    else
        params.sound = params.sound or sounds[action]
    end

    if self.main and not params.manage then
        -- Sound should be in full and not in sound engine as its the main player
        --sounds:play(params.sound, params)
    else
        --sounds:play(action, params)
    end
end


return Player