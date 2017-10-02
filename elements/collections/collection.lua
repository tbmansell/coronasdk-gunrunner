-- Class
local Collection = {
    
    -- list of all the gameObjects stored in the collection
    items    = {},
    -- name of the collection, to allow game objects to know which they are assigned to
    name     = "default",
    -- used for delta calculations
    lastTime = 0,
}


-- Gets the size of the list
-- @return size
----
function Collection:size()
    return #self.items
end


-- Add an object to this collection: let the collection do the object linkage to save functions on every object
-- This function is to allow objects to belong to multiple collections, so it does not modify the objects id
-- @param object to add
-- @return bool - true if added, false if already in the collection an not re-added
----
function Collection:add(object)
    -- first check that the object is not already in the list: otherwise the model is broken as we have it in twice and cant remove it
    if self:contains(object) then
        print("WARNING: object "..tostring(object.key).." already exists in collection "..tostring(self.name))
        return false
    end

    local newId = #self.items + 1
    
    -- create a reference to this collection in the added object, so they can remove themselves from it
    object.collections[self.name] = {
        id  = newId,
        ref = self
    }

    self.items[newId] = object

    if object.onStart then
        object:onStart()
    end
    
    return true
end


-- Removes an object from this collection
-- @param object to remove
----
function Collection:remove(object)
    if object.collections then
        -- instead of setting an element to nil, set to -1 as nil breaks usage of #
        local name = self.name
        local link = object.collections[name]

        if link then
            -- remove objects ref to this standard collection
            self.items[link.id] = -1
            object.collections[name] = nil
        end
    end
end


-- Indexes into this collection with an ID and fetches the item at that index
-- @param id - id of item or index of collection (should be the same for master collections)
-- @return object at the index
----
function Collection:get(id)
    return self.items[id]
end


-- Determines if the object passed is currently in this collection
-- @param objectToFind - to find
-- @return bool  - true if found
function Collection:contains(objectToFind)
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 and object.key == objectToFind.key then
            return true
        end
    end
    return false
end


--  Clears the list and removes all links for objects in it (but does not destroy contained object)
----
function Collection:clear()
    local items = self.items
    local name  = self.name
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 then
            object.collections[name] = nil
        end
    end

    self.items = {}
end


-- Clears the list and destroys all objects in it
----
function Collection:destroy()
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 then
            object:destroy()
            items[i] = nil
        end
    end

    self.items = {}
end


-- Runs the passed function for each object in the list, passing the object as a parameter to the function
-- @param func - a function(object) run for each item
function Collection:forEach(func)
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 then
            func(object)
        end
    end
end


function Collection:checkBehaviour(camera, player)
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 and object.checkBehaviour then
            object:checkBehaviour(camera, player)
        end
    end
end


-- Scales each object in the collection
-- @param camera - required for scaling
----
function Collection:scale(camera)
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 and object.inGame then
            object:scale(camera)
        end
    end
end


-- Destroys each object in the collection which has a stage property == stage
-- @param stage - the stage to destroy
----
function Collection:destroyStage(stage)
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 and object.stage == stage then
            object:destroy()
            items[i] = -1
        end
    end
end


-- Gets an object from the collection which matches the targetName
-- @param targetName - names to fetch (should be unique)
-- @return object matching or nil
----
function Collection:getTargetName(targetName)
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]
        if object and object ~= -1 and object.targetName == targetName then
            return object
        end
    end
    return nil
end


-- Pauses all timers on objects in the collection
----
function Collection:pauseTimers()
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]

        if object and object ~= -1 and object.inGame then
            -- Stop rotating items
            if object.timerRotatingHandle then
                timer.pause(object.timerRotatingHandle)
            end

            -- Stop animation items
            if object.timerAnimationHandle then
                timer.pause(object.timerAnimationHandle)
            end
        end
    end
end


-- Resumes all timers on objects in the collection
function Collection:resumeTimers()
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]

        if object and object ~= -1 and object.inGame then
            -- Stop rotating items
            if object.timerRotatingHandle then
                timer.resume(object.timerRotatingHandle)
            end

            -- Stop animation items
            if object.timerAnimationHandle then
                timer.resume(object.timerAnimationHandle)
            end
        end
    end
end



return Collection