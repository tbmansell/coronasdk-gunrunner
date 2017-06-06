local wattageEngine   = require("plugin.wattageTileEngine")
local spriteSheetInfo = require("core.sheetInfo")


TileEngine = {
    environment = nil,
    rowCount    = nil,
    columnCount = nil,

    floorLayer  = nil,
    wallLayer   = nil,
    entityLayer = nil,
}

-- Aliases:
local sqrt = math.sqrt

-- Local variables:
local coreEngine                  -- Reference to the tile engine
local lightingModel               -- Reference to the lighting model
local viewControl                 -- Reference to the UI view control
local spriteSheet
local spriteResolver = {}
local entityResolver = {}
local lastTime = 0

local TileSize    = 75
local cameraSpeed = 4 / 1000      -- Camera speed, 4 tiles per second




spriteResolver.resolveForKey = function(key)
    local frameIndex    = spriteSheetInfo:getFrameIndex(key)
    local frame         = spriteSheetInfo.sheet.frames[frameIndex]
    --print("resolve: key="..tostring(key))
    local displayObject = display.newImageRect(spriteSheet, frameIndex, frame.width, frame.height)
    
    return wattageEngine.SpriteInfo.new({
        imageRect = displayObject,
        width     = frame.width,
        height    = frame.height
    })
end


entityResolver.resolveForKey = function(displayObject)
    return wattageEngine.SpriteInfo.new({
        imageRect = displayObject,
    })
end


local function eventWallCollision(self, event)
    local other = event.other.object

    if other and other.isProjectile then 
        sounds:projectile(other.weapon.hitSound)
        other:destroy()
    end
end


local function eventHoleCollision(self, event)
    local other = event.other.object

    print("eventHoleCollision")

    if other and other.isPlayer then
        sounds:player("killed")
        other:fallToDeath(event)
    end
end


local function addFloorToLayer(layer)
    for row=1, TileEngine.rowCount do
        for col=1, TileEngine.columnCount do
            local value = TileEngine.environment[row][col]
            local name  = spriteSheetInfo:getName(value)

            --print(tostring(value).."="..tostring(name))
            layer.updateTile(row, col, wattageEngine.Tile.new({resourceKey=name}))
        end
    end
end


local function addWallsToLayer(layer)
    for row=1, TileEngine.rowCount do
        for col=1, TileEngine.columnCount do
            local value = TileEngine.environment[row][col]
            local name  = spriteSheetInfo:getName(value)
            local frame = spriteSheetInfo.sheet.frames[value]
            
            if frame then
                if frame.isWall then
                    local entityId, spriteInfo = layer.addEntity(name)

                    layer.centerEntityOnTile(entityId, row, col)
                    
                    local wall = spriteInfo.imageRect

                    -- Create wall physics object
                    physics.addBody(wall, "static", {density=1, friction=0, bounce=0, shape=frame.shape, filter=Filters.obstacle})

                    -- Create collision effect that destroys any projectile touching it
                    wall.collision = eventWallCollision
                    wall:addEventListener("collision", wall)

                elseif frame.isHole then
                    local entityId, spriteInfo = layer.addEntity(name)
                    
                    layer.centerEntityOnTile(entityId, row, col)

                    local hole = spriteInfo.imageRect

                    physics.addBody(hole, "static", {density=1, friction=0, bounce=0, shape=frame.shape, filter=Filters.hole})

                    hole.collision = eventHoleCollision
                    hole:addEventListener("collision", hole)
                end
            end
        end
    end
end


local function isTileTransparent(column, row)
    local rowTable = TileEngine.environment[row]

    if rowTable == nil then
        return true
    end
    
    local value = rowTable[column]
    
    return value == nil or value == 0
end


local function allTilesAffectedByAmbient(row, column)
    return true
end


----------------------- PUBLIC FUNCTIONS --------------------


function TileEngine:create(group, tileSheet, player, environment)
    self.environment = environment
    self.rowCount    = #environment
    self.columnCount = #environment[1]

    spriteSheetInfo:setup()
    spriteSheet = graphics.newImageSheet(tileSheet, spriteSheetInfo:getSheet())

    local tileEngineLayer = display.newGroup()

    coreEngine = wattageEngine.Engine.new({
        parentGroup                          = tileEngineLayer,
        tileSize                             = TileSize,
        spriteResolver                       = spriteResolver,
        compensateLightingForViewingPosition = false,
        hideOutOfSightElements               = false
    })

    lightingModel = wattageEngine.LightingModel.new({
        isTransparent                        = isTileTransparent,
        isTileAffectedByAmbient              = allTilesAffectedByAmbient,
        useTransitioners                     = false,
        compensateLightingForViewingPosition = false
    })

    local module = wattageEngine.Module.new({
        name          = "moduleMain",
        rows          = self.rowCount,
        columns       = self.columnCount,
        lightingModel = lightingModel,
        losModel      = wattageEngine.LineOfSightModel.ALL_VISIBLE
    })

    self:createLayers(wattageEngine, module)

    coreEngine.addModule({module = module})
    coreEngine.setActiveModule({moduleName = "moduleMain"})

    viewControl = wattageEngine.ViewControl.new({
        parentGroup         = group,
        centerX             = globalCenterX,
        centerY             = globalCenterY,
        pixelWidth          = display.actualContentWidth,
        pixelHeight         = display.actualContentHeight,
        tileEngineInstance  = coreEngine
    })

    lightingModel.setAmbientLight(1, 1, 1, 1)
end


function TileEngine:createLayers(wattageEngine, module)
    -- Add elements to layers
    self.floorLayer = wattageEngine.TileLayer.new({
        rows    = self.rowCount,
        columns = self.columnCount
    })
    
    self.wallLayer  = wattageEngine.EntityLayer.new({
        tileSize       = TileSize,
        spriteResolver = spriteResolver
    })

    self.entityLayer  = wattageEngine.EntityLayer.new({
        tileSize       = TileSize,
        spriteResolver = entityResolver
    })

    addFloorToLayer(self.floorLayer)
    addWallsToLayer(self.wallLayer)
    
    self.floorLayer.resetDirtyTileCollection()

    -- Add player to layer: however this is moving the entity element matching the playerId
    --local playerId = self.entityLayer.addNonResourceEntity(player.image)
    --entityLayer.centerEntityOnTile(playerId, 5, 11)
    --self.entityLayer.addNonResourceEntity(player.image)

    module.insertLayerAtIndex(self.floorLayer,  1, 0)
    module.insertLayerAtIndex(self.wallLayer,   2, 0)
    module.insertLayerAtIndex(self.entityLayer, 3, 0)
end


function TileEngine:destroy()
    coreEngine.destroy()
    viewControl.destroy()

    coreEngine, viewControl, lightingModel = nil, nil, nil
end


function TileEngine:addEntity(entity, x, y)
    if x and y then
        self.entityLayer:centerEntityOnTile(entity, x, y)
    end

    self.entityLayer.addNonResourceEntity(entity.image)
end


function TileEngine:eventUpdateFrame(event, focus)
    local camera        = viewControl.getCamera()
    --local lightingModel = coreEngine.getActiveModule().lightingModel

    if lastTime ~= 0 then
        -- Determine the amount of time that has passed since the last frame and
        -- record the current time in the lastTime variable to be used in the next frame.
        local curTime   = event.time
        local deltaTime = curTime - lastTime
        lastTime = curTime

        --local x, y = initFocusX - focus.x, initFocusY - focus.y
        local x, y = focus.x / TileSize, (focus.y-230) / TileSize
        camera.setLocation(x, y)
        
        -- Update the lighting model passing the amount of time that has passed since the last frame.
        --lightingModel.update(deltaTime)
    else
        -- This is the first call to onFrame, so lastTime needs to be initialized.
        lastTime = event.time

        -- This is the initial position of the camera
        --camera.setLocation(7, 7)
        --camera.setZoom(1.75)

        -- Since a time delta cannot be calculated on the first frame, 1 is passed in here as a placeholder.
        --lightingModel.update(1)
    end

    -- Render the tiles visible to the passed in camera.
    coreEngine.render(camera)

    -- The lighting model tracks changes, then acts on all accumulated changes in
    -- the lightingModel.update() function.  This call resets the change tracking
    -- and must be called after lightingModel.update().
    --lightingModel.resetDirtyFlags()
end


return TileEngine