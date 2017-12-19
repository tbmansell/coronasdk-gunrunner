local spine            = require("core.spine")
local gameObject       = require("elements.gameObject")
local spineObject      = require("elements.spineObject")
local characterObject  = require("elements.character")
local collection   	   = require("elements.collections.collection")
local masterCollection = require("elements.collections.masterCollection")

-- Class
local Builder = {}

-- Local vars for performance
local spineDrawDistance = 1200
local leftBoundary      = -1200
local rightBoundary     = 1200
local topBoundary       = -1200
local bottomBoundary    = 1200

-- Used for spine animation
local lastTime          = 0

-- Aliases
local new_image 		= display.newImage
local move_item_pattern = moveItemPattern


function Builder:deepCopy(orig, copy)
    local orig_type = type(orig)
    
    if orig_type == 'table' then
        copy = copy or {}

        for orig_key, orig_value in next, orig, nil do
        	copy[self:deepCopy(orig_key, copy)] = self:deepCopy(orig_value, copy)
        end
    else  -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function Builder:newClone(orig)
    local orig_type = type(orig)
    local copy
   
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do          
            copy[self:newClone(orig_key)] = self:newClone(orig_value)
        end
    else  -- number, string, boolean, etc
    	copy = orig
    end
    return copy
end


function Builder:deepPrint(orig)
    if type(orig) == "table" then
        for key, value in next, orig, nil do
            if type(value) == "table" then
                print(key.."=")
                self:deepPrint(value)
            else
                print(key.."="..tostring(value))
            end
        end
    else
        print(tostring(orig))
    end
end


function Builder:newGameObject(spec, image, makeGroup)
	-- an object is at its foundation a copy of the table spec passed in where we can override specifics
	local object = self:newClone(spec)

	-- we then apply the gameObject definition over it
	self:deepCopy(gameObject, object)

	if not object.type then object.type = "" end

	-- deepCopy on empty tables does not seem to work as it should, so reset them here
	object.boundItems  = {}
	object.collections = {}
	object.bindQueue   = {}

    if makeGroup then
        object.image        = display.newGroup()
        object.image.object = object
        object.image:insert(image)
    else
    	-- simple assignment of an image passed in as a property of this object, and allow the image to have a ref to the object for event handlers
    	object.image 		= image
    	object.image.object = object
    end

	return object
end


function Builder:newSpineObject(spec, spineParams)
	local imagePath = spineParams.imagePath
	local json 		= spine.SkeletonJson.new()

	if spineParams.scale then
    	json.scale = spineParams.scale
	end

	local skeletonData = json:readSkeletonDataFile("json/spine/"..spineParams.jsonName..".json")
    local skeleton     = spine.Skeleton.new(skeletonData, nil)
    
    if spec.modifyImage then
    	-- Allow customisation of the spine images as they are created
    	local modify = spec.modifyImage

	    function skeleton:createImage(attachment)
	        local image = new_image("images/" .. imagePath .. "/" .. attachment.name .. ".png")
			image:setFillColor(modify[1], modify[2], modify[3])
			return image, true
	    end
	else
		-- Normal use: no modification to images
		function skeleton:createImage(attachment)
	        return new_image("images/" .. imagePath .. "/" .. attachment.name .. ".png"), false
	    end
	end

    if spineParams.skin ~= nil then
    	skeleton:setSkin(spineParams.skin)
    end
    
    skeleton:setToSetupPose()

    -- Now build the gameObject:
    local object = self:newGameObject(spec, skeleton.group)

    -- spineObject overrides the base destroy() to add spine cleanup - so keep ref to base destroy()
    object.isSpine     = true
	object.baseDestroy = object.destroy
	object.skeleton    = skeleton
	object.class       = "spineObject"

    -- we then apply the spineObject definition over it
	self:deepCopy(spineObject, object)

	-- setup initial animation to LOOP
    if spineParams.animation then
    	local loop = true
    	if spineParams.loop == false then loop = false end

    	object.stateData = spine.AnimationStateData.new(skeletonData)
    	object.state     = spine.AnimationState.new(object.stateData)
    	object.state:setAnimationByName(0, spineParams.animation, loop, 0)
	end

	return object
end


function Builder:newCharacter(spec, spineParams)
    local character = self:newSpineObject(spec, spineParams)

    self:deepCopy(characterObject, character)

    return character
end


function Builder:setupCustomShape(object, width, height)
	object.customWidth  = width
	object.customHeight = height

	-- These functions replace the base ones for performance reasons (rather than have if/else inside): 

    function object:width()
        return self.customWidth * self.scaled
    end
    
    function object:height()
        return self.customHeight * self.scaled
    end
end


function Builder:newCollection(name)
	local coll = self:newClone(collection)
	coll.name  = name
	coll.items = {}
	return coll
end


function Builder:newSpineCollection()
	local collection = self:newCollection("spineSet")

	function collection:animateEach(delta, visibleOnly, player)
		local items = self.items
	    local num   = #items

	    for i=1,num do
	        local object = items[i]

	        if object and object ~= -1 and object.inGame then
	        	-- Check if image on-screen (or close to on-screen for fast movement)
                if object:inDistance(player, spineDrawDistance) then
                    object:updateSpine(delta)
                end
	        end
	    end
	end

	return collection
end


function Builder:newMovementCollection()
	local collection = self:newCollection("movementSet")

	-- Essentially just calls the global moveItemPattern() on each object
	function collection:moveEach(delta, camera)
	    local items = self.items
	    local num   = #items

	    for i=1,num do
	        local object = items[i]

	        if object and object ~= -1 then
	        	-- objects marked punyMover=true only move if visible on-screen for performance
	        	if object.punyMover then
	        		local x, y = object.image.x, object.image.y

	        		if (x >= leftBoundary and x <= rightBoundary and y >= topBoundary and y <= bottomBoundary) then
	        			move_item_pattern(camera, object, delta)
	        		end
	        	else
	        		-- All other objects always move regardless of where they are on level
	        		move_item_pattern(camera, object, delta)
	        	end
	        end
	    end
	end

	return collection
end


function Builder:newParticleEmitterCollection()
	local collection = self:newCollection("particleEmitterSet")

	-- Called to check that collectables with bound emitters turn them off when they are off screen and on when on screen
	function collection:checkEach()
	    local items = self.items
	    local num   = #items

	    for i=1,num do
	        local object = items[i]

	        if object and object ~= -1 and object.inGame and object.boundEmitter then
                local x, y = object.image.x, object.image.y
                
                if (x >= leftBoundary and x <= rightBoundary and y >= topBoundary and y <= bottomBoundary) then
                    if not object.boundEmitterOn then
                        object.boundEmitterOn = true
                        object.boundEmitter:start()
                    end
                else
                    if object.boundEmitterOn then
                        object.boundEmitterOn = false
                        object.boundEmitter:stop()
                    end
                end
	        end
	    end
	end

	return collection
end


function Builder:newMasterCollection(name, spineCollection, movementCollection, particleEmitterCollection)
	local collection = self:newCollection(name)

    -- override base clear(), destroy() but provide base references to them
    collection.baseClear   = collection.clear
    collection.baseDestroy = collection.destroy
    collection.baseAdd     = collection.add

	self:deepCopy(masterCollection, collection)

	collection.spineCollection   	     = spineCollection
	collection.movementCollection 	     = movementCollection
	collection.particleEmitterCollection = particleEmitterCollection

	return collection
end


return Builder