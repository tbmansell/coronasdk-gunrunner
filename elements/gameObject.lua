local particles         = require("core.particles")
--local soundEngine       = require("core.sound-engine")


-- Class
local GameObject = {

    key           = nil,           --  the id is used to differantiate instances of the same class and type for collections
	id            = 0,             -- the class is used to determine the top most (most derived) class of the object is
	class         = "GameObject",  -- the image property holds the actual image:
	image         = nil,           -- true if object has a physics shape, false if not
	inPhysics     = true,          -- set to true when destroy() is called
    isDestroyed   = false,         -- the reverse of isDestroyed: starts true and set t`o false when destroy() is called
    inGame        = true,          -- reference to a ledge object which this object is bound to (moves with)
    attachedOther = nil,           -- list of other objects which are bound to this object
    boundItems    = {},            -- list of other objects this object is to be bound to, once it's full key has been created - by the first key() call from adding to a master collection
    bindQueue     = {},            -- list of references to collections this object is in: stored as {[name] = {id, ref}, }
    collections   = {},            -- each type of object has a collection dedicated to it so we have a direct ref for shared info (eg. ledgeCollection for ledge)
    master        = nil,           
	flipYAxis     = false,
    flipXAxis     = false,
    angle         = 0,
}

-- Aliases:
local math_round = math.round
local draw_point = drawMovingPathPoint
local new_circle = display.newCircle


-- @hook: override this if the object has a physics shape
function GameObject:setPhysics() end


function GameObject:generateKey(id)
	if not self.key then
        self.id  = id
    	self.key = self.class.."_"..self.type.."_"..self.id

        -- Once a key has been generated: bind this object to any other objects currently queued
        local num = #self.bindQueue
        for i=1,num do
            self.bindQueue[i]:bind(self)
        end
        self.bindQueue = {}
    else
        print("Warning: generateKey() already called on: "..self.key.." new id sent is "..id)
    end
    return self.key
end


function GameObject:toString(orig)
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        local first = true
        copy = "{"

        for orig_key, orig_value in next, orig, nil do
            if first then first = false else copy=copy..", " end
            local v = self:toString(orig_value)
            copy = copy..orig_key.."="..tostring(v)
            print(orig_key)
        end
        copy = copy.."}"
    else  -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function GameObject:destroy(camera, destroyBoundItems)
    self:destroyEmitter()
    self:detachFromOther()

	-- Releases all this object's bound objects
    if self.boundItems then
        for key,object in pairs(self.boundItems) do
            if object.image then
                self:release(object)

                if destroyBoundItems and not object.isPlayer then
                    object:destroy()
                end
            end
        end
    end

    if self.timerRotatingHandle then
        timer.cancel(self.timerRotatingHandle)
        self.timerRotatingHandle = nil
    end

    if self.timerAnimationHandle then
        timer.cancel(self.timerAnimationHandle)
        self.timerAnimationHandle = nil
    end

    if camera then
        camera:remove(self.image)
    end

    if self.movement and self.movement.center then
        if camera then camera:remove(self.movement.center) end
        self.movement.center:removeSelf()
        self.movement.center = nil
    end

    if self.image and self.image.removeSelf then
        self.image:removeSelf()
    end

    self.image 	     = nil
    self.boundItems  = nil
    self.isDestroyed = true
    self.inGame      = false

    -- remove itself from all collections its currently in (collection does the work, the object just triggers the action)
    if self.collections then
        for _,collection in pairs(self.collections) do
        	if collection.ref then
        		collection.ref:remove(self)   -- this ref to collection removed by collection
        	end
        end
    end

    -- remove itself from its master collection
    if self.master then
    	self.master:remove(self)   -- this ref to collection removed by collection
    end

    self.collections = nil
end


-- BINDING


function GameObject:bind(object)
    self.boundItems[object.key] = object

    object.attachedOther = self
end


function GameObject:queueBind(object)
    self.bindQueue[#self.bindQueue+1] = object
end


function GameObject:release(object)
    if self.boundItems then
        self.boundItems[object.key] = nil
    end

    object.attachedOther = nil
end


function GameObject:numBoundItems()
    local num=0

    for key,object in pairs(self.boundItems) do
        if object then 
            num = num + 1 
        end
    end
    return num
end


function GameObject:detachFromOther()
    if self.attachedOther then
        self.attachedOther:release(self)	-- release will nil this objects reference
    end
end


function GameObject:isBound(object)
    return (self.boundItems[object.key] ~= nil)
end


-- ESSENTIALS


function GameObject:x(x)
    if self.image then
        if x then 
        	self.image.x = x
        else
        	return self.image.x
        end
    end
end


function GameObject:y(y)
    if self.image then
        if y then 
        	self.image.y = y
        else
        	return self.image.y
        end
    end
end


function GameObject:pos()
    if self.image then
        return self.image.x, self.image.y
    else
        return 0, 0
    end
end


function GameObject:moveBy(x, y)
    if self.image then
        if x then self.image.x = self.image.x + x end
        if y then self.image.y = self.image.y + y end
    end
end


function GameObject:moveTo(x, y)
    if self.image then
        if x then self.image.x = x end
        if y then self.image.y = y end
    end
end


function GameObject:width()
    if self.image then
        return self.image.width
    else
        return 0
    end
end


function GameObject:height()
    if self.image then
        return self.image.height
    else
        return 0
    end
end


function GameObject:leftEdge(fromEdge)
    if self.image then
        return self.image.x - (self:width()/2)
    else
        return 0
    end
end


function GameObject:rightEdge(fromEdge)
    if self.image then
        return self.image.x + (self:width()/2)
    else
        return 0
    end
end


function GameObject:topEdge(fromEdge)
    if self.image then
        return self.image.y - (self:height()/2)
    else
        return 0
    end
end


function GameObject:bottomEdge(fromEdge)
    if self.image then
        return self.image.y + (self:height()/2)
    else
        return 0
    end
end


function GameObject:distanceFrom(to)
    local xdist, ydist = 0, math_round(to:jumpTop() - self:jumpTop())

    if self:x() < to:x() then
        xdist = math_round(to:jumpLeft()  - self:jumpRight())
    else
        xdist = math_round(to:jumpRight() - self:jumpLeft())
    end

    return xdist, ydist
end


function GameObject:flipX()
    if self.image then
        self.flipXAxis = true
        self.image:scale(-1,1)
    end
end


function GameObject:flipY()
    if self.image then
        self.flipYAxis = true
        self.image:scale(1,-1)
    end
end


function GameObject:solid()
    if self.image then
        self.image.isSensor = false
    end
end


function GameObject:intangible()
    if self.image then
        self.image.isSensor = true
    end
end


function GameObject:setGravity(gravityScale)
    if self.image then
        self.image.gravityScale = gravityScale or 1
    end
end


function GameObject:body(type)
    if self.image then
        self.image.bodyType = type
    end
end


function GameObject:visible(alpha)
    if self.image then
	   self.image.alpha = alpha or 1
    end
end


function GameObject:hide()
    if self.image then
	   self.image.alpha = 0
    end
end


function GameObject:rotate(rotation)
    if self.image then
        self.image.rotation = rotation
        self.angle = rotation
    end
end


function GameObject:isRotated()
    return (self.image.rotation ~= nil and self.image.rotation ~= 0)
end


function GameObject:applyForce(velx, vely)
    if self.image then
        self.image:setLinearVelocity(velx, vely)
    end
end


function GameObject:applySpin(spin)
    if self.image then
        self.image.angularVelocity = spin
    end
end


function GameObject:getForce()
    return self.image:getLinearVelocity()
end


function GameObject:stopMomentum()
    if self.image then
        self.image.angularVelocity = 0
        self.image:setLinearVelocity(0, 0)
    end
end


function GameObject:pose()
    self.skeleton:setToSetupPose()
end


function GameObject:updateSpine(delta)
    self.state:update(delta)
    self.state:apply(self.skeleton)
    self.skeleton:updateWorldTransform()
end


-- MOVEMENT


function GameObject:setMovement(camera, movement, drawPath)
    camera        = camera   or self:getCamera()
    self.movement = movement or self.movement

    -- for circular movement:
    if self.movement.pattern == movePatternCircular and self.movement.center == nil then
        local length = self.length or self.movement.distance
        local center = new_circle(self:x() - length, self:y() - length, 5)
        center.alpha = 0
        camera:add(center, 3)

        self.movement.center = center
    end
   
    setupMovingItem(self)

    -- disable draw here for any object that has specified dontDraw
    if self.movement.dontDraw then
        self.movement.draw = false
    end
    
    self:scaleMovement(camera)
end


function GameObject:move()
    if self.movement then
        self.isMoving = true
        
        if self.master then
            self.master:addToMovementCollection(self)
        end
    end
end


function GameObject:moveNow(movement, drawPath)
    self:setMovement(nil, movement, drawPath)
    self:move()
end


function GameObject:stop()
    if self.master then
        self.master.movementCollection:remove(self)
    end
    self.isMoving = false
end


function GameObject:pauseMovement(duration)
    local time = duration or self.movement.pause

    -- only allow pause if time specified and not already paused
    if time > 0 and self.pauseMovementHandle == nil then
        self.pauseMovementHandle = transition.to(self, {dummy=1, time=time, onComplete=function() self:pauseMovementFinished() end})
    end
end


function GameObject:pauseMovementFinished()
    if self.pauseMovementHandle ~= nil then 
    	self.pauseMovementHandle = nil
    end
end


function GameObject:movementCompleted()
    self:stop()
end


-- EMITTERS


function GameObject:emit(effectName, params, attach)
    local params  = params or {}

    local emitter = particles:showEmitter(
        --self:getCamera(),
        effectName, 
        params.xpos     or self:x(), 
        params.ypos     or self:y(), 
        params.duration or 1500,
        params.alpha    or 1
    )

    if self.direction == left then
        emitter:scale(-1,1)
    end

    if attach then
        self.image:insert(emitter)
    end

    return emitter
end


function GameObject:bindEmitter(effectName, params)
    params.duration = "forever"

    self:destroyEmitter()
    self.boundEmitterOn = true
    self.boundEmitter   = self:emit(effectName, params, self.isSpine)

    if self.master then
        -- TODO: check if already in collection
        self.master.particleEmitterCollection:add(self)
    end
end


function GameObject:destroyEmitter()
    if self.boundEmitter then
        if self.master and self.master.particleEmitterCollection then
            self.master.particleEmitterCollection:remove(self)
        end

        self.boundEmitter:destroy()
        self.boundEmitter   = nil
        self.boundEmitterOn = false
    end
end


-- SOUNDS


function GameObject:sound(action, params)
    local soundData = nil

    if type(params) == "function" then
        soundData = params(soundEngine)
    else
        soundData = params or {}
    end

    soundData.sound = soundData.sound or sounds[action]

    if soundData.duration == "forever" then
        soundData.loops    = -1
    end

    if soundData.sound then
        soundEngine:playManagedAction(self, action, soundData)
    end
end


function GameObject:stopSound(action)
    soundEngine:stopSound(self.key, action)
end


function GameObject:constantSoundHandler(force, delay)
    if force or (self.constantSound and self.inGame) then
        after(delay or 250, function()
            if self.inGame then
                self:sound("constant", self.constantSound)
            end
        end)
    end
end


return GameObject