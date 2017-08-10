local anim    = require("core.animations")
local builder = require("level-objects.builders.builder")


-- local constants
local typeCharacter        = 1
local typeBossUfo          = 2
local typeBossChair        = 3
local typeEffectsFlash     = 4
local typeEffectsExplosion = 5
local typeFuzzy            = 6
local typeGearShield       = 7 
local typeGearFlame        = 8 
local typeHolocube         = 9
local typeJumpMarker       = 10
local typeLandingDust      = 11
local typeStartMarker      = 12
local typeRing             = 13
-- max for looping
local maxType              = typeRing


-- @class Definition for Spine store
local SpineStore = {

    -- reference to a spine collection to add and remove objects to/from
    spineCollection = nil,
    -- list of dust colors
    dustColors      = {"grey", "red", "yellow", "green"},
    -- tracks how many of each type of spine object is currently in use
    --inUse           = {},
    -- stores how many of each type of object have been created
    created         = {},
    -- stores a list of landing dust spine objects, per color, pre-loaded rath than load on land
    landingDust     = {},
    -- used for a displayGroup when removing items from game elements, as in order to remove them from a DG, you have to insert them into another
    removeGroup     = nil,

    -- Methods:
    -----------
    -- load()
    -- destroy()
    -- destroyList()
    -- fetchObject()

    -- newLandingDust()
    -- newJumpMarker()
    -- newStartMarker()
    -- newGearShield()
    -- newGearFlame()
    -- newEffectFlash()
    -- newEffectExplosion()
    -- newHoloCube()
    -- newRing()
    -- newFuzzy()
    -- newCharacter()
    -- newBoss()
    
    -- showLandingDust()
    -- showJumpMarker()
    -- showStartMarker()
    -- showGearShield()
    -- showGearFlame()
    -- showFlash()
    -- showExplosion()
    -- showHoloCube()
    -- showRing()
    -- showFuzzy()
    -- showCharacter()
    -- showBossUfo()
    -- showBossChair()

    -- hideJumpMarkers()
    -- hideStartMarker()
    -- hideGearShield()
    -- hideGearFlame()
}


-- Aliases:
local math_random = math.random


function SpineStore:load(spineCollection)
    self.removeGroup     = display.newGroup()
    self.spineCollection = spineCollection

    for type=1, maxType do
        self.created[type] = {}
    end
end


function SpineStore:destroy()
    for type=1, maxType do
        self:destroyList(self.created[type], type)
    end

    self.removeGroup:removeSelf()
    self.removeGroup     = nil
    self.spineCollection = nil
end


-- Destroy all items for a list
-- @param list to destroy
----
function SpineStore:destroyList(list, type)
    local num = #list

    for i=1,num do
        local entry = list[i]
        entry.used = false
        entry.item:destroy()
        entry.item = nil
    end

    self.created[type] = {}
end


function SpineStore:fetchObject(creator, type, params)
    local created = self.created[type]
    local num     = #created

    for i=1,num do
        local entry = created[i]

        if entry.used == false and entry.item then
            -- found one that is built but unused
            entry.used = true
            return entry.item
        end
    end

    -- build a new one and add it to the end of the list
    local newObject = creator(self, params)

    newObject.inPhysics            = false
    newObject.belongsToSpineStore  = true
    newObject:pose()
    newObject:generateKey(num + 1)
    
    created[num+1] = {
        used = true, 
        item = newObject
    }

    return newObject
end


function SpineStore:releaseObject(type, objectToRelease)
    local created = self.created[type]
    local num     = #created

    for i=1,num do
        local entry  = created[i]
        local object = entry.item

        if object and object.key == objectToRelease.key then
            entry.used = false
            return
        end
    end
end


function SpineStore:releaseAllObjects(type)
    local created = self.created[type]
    local num     = #created

    for i=1,num do
        created[i].used = false
    end
end


-- Adds an item to the spine collection and handles spineDelays
-- @param object
----
function SpineStore:addSpine(object)
    if object.spineDelay and object.spineDelay > 0 then
        after(object.spineDelay, function()
            self.spineCollection:add(object)
        end)
    else
        self.spineCollection:add(object)
    end
end


-- Creates a new explosion effect (used for ledges etc)
-- @return spineObject
----
function SpineStore:newEffectExplosion(size)
    return builder:newSpineObject({type="effectexplosion"}, {jsonName="bulletImpact", imagePath="projectiles", scale=(size or 1), animation="Standard"})
end


-- Requests to show a explosion effect on he player
-- @param camera
-- @param player
----
function SpineStore:showExplosion(camera, target, size)
    local effect = self:fetchObject(self.newEffectExplosion, typeEffectsExplosion, size)

    if effect then
        effect:moveTo(target:pos())
        effect:visible()
        effect:animate("Standard")

        camera:add(effect.image, 2)
        self.spineCollection:add(effect)

        after(1500, function()
            effect:hide()
            camera:remove(effect.image)
            self.spineCollection:remove(effect)
            self:releaseObject(typeEffectsExplosion, effect)
        end)
    end
end


return SpineStore