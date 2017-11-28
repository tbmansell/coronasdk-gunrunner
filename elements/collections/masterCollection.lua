-- @class master collection is the holding place for a class of game objects (eg. ledges)
-- Each main class of objects will live in its own master collection, which is responsible for creating their id (when added), destroying and locating them.
-- An object can belong to many collections, but only one master collection - as it defines its id
local MasterCollection = {
    
    -- reference to a global spine, so it can add objects to it
    spineCollection    = nil,
    -- reference to a global movement collection, so it can add objects to it
    movementCollection = nil,
    -- reference to a global particle emitter collection, so it can add objects to it
    particleEmitterCollection = nil,
    -- Methods:
    -----------
    -- *add()
    -- addToMaster()
    -- addToSpineCollection()
    -- addToMovementCollection()
    -- addToParticleEmitterCollection()
    -- collectedItem()
    -- *remove()
    -- +clear()
    -- +destroy()
    -- startConstantSounds()
}


-- Replaces collection.add() to add an object to this as its master and its reference collections
-- @param object to add
----
function MasterCollection:add(object)
    self:addToMaster(object)
    self:addToSpineCollection(object)
    self:addToMovementCollection(object)
    self:addToParticleEmitterCollection(object)

    if object.onStart then
        object:onStart()
    end
end


-- Replace collection.add() to make this the objects master collection - so it defines the objects id
-- NOTE: An object can only belong to one master collection and they have a direct reference to it for shared properties
-- @param object to add
----
function MasterCollection:addToMaster(object)
    local newId = #self.items + 1

    object:generateKey(newId)
    object.master = self

    self.items[newId] = object
end


-- Add object to the spine collection if required
-- @param @object to add
----
function MasterCollection:addToSpineCollection(object)
    if object.isSpine then
        if object.spineDelay and object.spineDelay > 0 then
            after(object.spineDelay, function()
                self.spineCollection:add(object)
            end)
        else
            self.spineCollection:add(object)
        end
    end
end


-- Add object to the movement collection if required
-- @param object to add
----
function MasterCollection:addToMovementCollection(object)
    if object.isMoving then
        after(object.movement.delay or 0, function()
            self.movementCollection:add(object)
        end)
    end
end


-- Add object to the particle emitter collection if required
-- @param object to add
----
function MasterCollection:addToParticleEmitterCollection(object)
    if object.boundEmitter then
        self.particleEmitterCollection:add(object)
    end
end


-- Checks if the items has been collected by a previous run of the zone, by seeing it it appears in the zoneState collection
-- @param item
-- @param zoneState
-- @param collectedName
-- @return true if item collected by matching its key
----
function MasterCollection:collectedItem(item, zoneState, collectedName)
    -- Check if this fuzzy has already been collected on the current level and exit if so (but still allow incrementing self.amount for the next one)
    if zoneState and zoneState[collectedName] and state.demoActions == nil then
        for key,data in pairs(zoneState[collectedName]) do
            if key == item.key then
                -- Add a dummy entry to the collection to keep the id the same for further fuzzies
                item:destroy()
                self.items[#self.items+1] = -1
                return true
            end
        end
    end
    return false
end


-- Replace collection.remove() to remove an object from this collection and nil its master reference
-- @param object to remove
----
function MasterCollection:remove(object)
    if object.master and object.master.name == self.name then
        -- instead of setting an element to nil, set to -1 as nil breaks usage of #
        self.items[object.id] = -1
        object.master = nil
    end
end


-- Overrides base clear() to nil refs and then call base clear
----
function MasterCollection:clear()
    self.spineCollection    = nil
    self.movementCollection = nil
    self.particleEmitterCollection = nil
    self:baseClear()
end


-- Overrides base destroy() to nil refs and then call base destroy
----
function MasterCollection:destroy()
    self.spineCollection    = nil
    self.movementCollection = nil
    self.particleEmitterCollection = nil
    self:baseDestroy()
end


-- loops through items and plays any constant sounds
----
function MasterCollection:startConstantSounds()
    local items = self.items
    local num   = #items

    for i=1,num do
        local object = items[i]

        if object and object ~= -1 and object.inGame and object.constantSound then
            object:constantSoundHandler(true)
        end
    end
end


return MasterCollection