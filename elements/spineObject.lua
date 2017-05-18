-- @class Definition for spine object
local spineObject = {

    isSpine = true,
    class   = "spineObject",

    -- Methods:
    -----------
    -- *destroy()
    -- animate()
    -- loop()
    -- changeDirection()
}


function spineObject:destroy(camera)
    if self.skeleton then
	   self.skeleton:cleanUp()
    end
    
    self.skeleton  = nil
    self.stateData = nil
    self.state     = nil

    -- make sure base removes the attachments and the image property
    self:baseDestroy(camera)
end


function spineObject:animate(name)
    if self.state and self.animationOverride == nil then
        if self.stateData.skeletonData:findAnimation(name) then
            self.state:setAnimationByName(0, name, false, 0)
        else
            print("Warning: "..tostring(self.key).." does not have animation: "..tostring(name))
        end
    end
end


function spineObject:loop(name)
    if self.state and self.animationOverride == nil then
        if self.stateData.skeletonData:findAnimation(name) then
            self.state:setAnimationByName(0, name, true, 0)
        else
            print("Warning: "..tostring(self.class).." does not have animation: "..tostring(name))
        end
    end
end


function spineObject:changeDirection(direction, fixDirection)
    if self.fixDirection then return end

    if direction == right then
        self.skeleton.flipX = true
        self.direction = right
    else
        self.skeleton.flipX = false
        self.direction = left
    end

    self.fixDirection = fixDirection
end


return spineObject