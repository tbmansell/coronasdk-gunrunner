local anim        = require("core.animations")
local spine       = require("core.spine")
--local soundEngine = require("core.sound-engine")
local projectileBuilder = require("elements.builders.projectileBuilder")

-- Class
local Player = {

    isPlayer    = true,
    class       = "Player",
    intHeight   = 30,
    intWidth    = 30,

    ingame      = false,
    mode        = PlayerMode.ready,
    hasDied     = false,
    health      = 100,
    gear        = {},
    shielded    = false,
    weapon      = nil,
    shotsFired  = 0,

    flagShootAllowed = true,    
}

-- Aliases:
--local play     = globalSoundPlayer
local math_abs = math.abs
local osTime   = os.time



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


function Player:stopMomentum(completely)
    if self.image then
        self.image.angularVelocity = 0
        self.image:setLinearVelocity(0, 0)
    end
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
    return self.mode ~= PlayerMode.dead and self.flagShootAllowed
end


function Player:shoot(camera)
    if self:canShoot() then
        self.flagShootAllowed = false
        self.shotsFired = self.shotsFired + 1

        after(self.weapon.rof, function() 
            self.flagShootAllowed = true 
        end)

        local shot = projectileBuilder:newShot(nil, self.weapon, {xpos=self:x(), ypos=self:y()-50, angle=self.angle+90, filter=Filters.playerShot})

        shot:fire()
    end
end


function Player:setMode(mode, aliveOnly)
    -- aliveOnly to be used so we dont accidentally overwrite status if currently dead
    if not aliveOnly or not self:isDead() then
        self.mode = mode
    end
end


function Player:setPhysics()
    local w, h  = self.intWidth, self.intHeight  --self:width(), self:height()
    local shape = {-w,-h, w,-h, w,h, -w,h}

    physics.addBody(self.image, (self.physicsBody or "dynamic"), {shape=shape, density=1, friction=1, bounce=0, filter=Filters.player})
   
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
    self:loop("run")
end


----------------- FUNCTIONS TO HANDLE BEING KILLED -------------------


function Player:hit(shot)
    if self.mode ~= PlayerMode.dead then
        if not self.shielded or shot.shieldBuster then
            self.health = self.health - shot.damage

            self:animate("hit")

            if self.health < 0 then
                self:explode()
            end
        end 
    end
end


function Player:fallToDeath(options, sound)
    local options = options or {}

    self:die(options.animation, sound, false, options.fall, options.message)
end


function Player:explode(options, sound)
    local options = options or {}

    if sound and type(sound) == "table" then
        sound.action = sound.action or "playerDeathExplode"
    else
        sound = "playerDeathExplode"
    end

    self:die(options.animation, sound, true, false, options.message)
end


-- Base function which performs the common things that happen when a player is killed
function Player:die(animation, sound, stopMoving, fall, message)
    -- guard to stop multiple deaths
    if self.mode ~= PlayerMode.dead then
        self.mode = PlayerMode.dead

        if self.runSound then
            self:stopSound(self.runSound)
            self.runSound = nil
        end

        self:destroyEmitter()
        --self:emit("deathflash")
        --self:emit("die")

        -- Sound can be empty (no sound), string (just play sound of that name) or table (sound with options)
        if sound then
            if type(sound) == "string" then
                self:sound(sound)
            else
                self:sound(sound.action, sound)
            end
        end

        self.animationOverride = nil
        self:animate(animation or "Death EXPLODE BIG")

        if stopMoving then
            self:stopMomentum(true)
        end

        if message and self.main then
            hud:displayMessageDied(message)
        end

        after(3000, function() 
            

            if self.failedCallback then 
                self:failedCallback() 
            end
        end)
    end
end


function Player:destroy(camera, destroyBoundItems)
    self:spineObjectDestroy(camera, destroyBoundItems)
end


function Player:setWeapon(weapon)
    self.weapon            = weapon
    self.flagShootAllowed  = true
    self.gear[weapon.name] = true
    self:loadGear()
end


function Player:setGear(item)
    self.gear[item.name] = true
    self:loadGear()
end


function Player:removeGear(item)
    self.gear[item.name] = false
    self:loadGear()
end


function Player:pose()
    self.skeleton:setToSetupPose()
    self:loadGear()
end


function Player:loadGear()
    for item,set in pairs(self.gear) do
        --[[ if set then
            self.skeleton:setAttachment(item.skeletonName, item.skeletonName)
        else
            self.skeleton:setAttachment(item.skeletonName, nil)
        end
        ]]
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
        play(params.sound, params)
    else
        -- Some sounds should be allowed to be playe as many times as called and not bound by the action name:
        if action == "randomRing" then
            action = action..osTime()
        end

        soundEngine:playManagedAction(self, action, params)
    end
end


return Player