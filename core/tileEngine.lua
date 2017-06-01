local wattageEngine   = require("plugin.wattageTileEngine")
local spriteSheetInfo = require("core.sheetInfo")


TileEngine = {
    environment = nil,
    rowCount    = nil,
    columnCount = nil,
}

-- Aliases:
local sqrt = math.sqrt

-- Local variables:
local coreEngine                  -- Reference to the tile engine
local lightingModel               -- Reference to the lighting model
local viewControl                 -- Reference to the UI view control
local spriteSheet
local spriteResolver = {}
local lastTime = 0

local TileSize    = 52
local cameraSpeed = 4 / 1000      -- Camera speed, 4 tiles per second


----------------------- PRIVATE FUNCTIONS --------------------


spriteResolver.resolveForKey = function(key)
    local frameIndex    = spriteSheetInfo:getFrameIndex(key)
    local frame         = spriteSheetInfo.sheet.frames[frameIndex]
    local displayObject = display.newImageRect(spriteSheet, frameIndex, frame.width, frame.height)
    
    return wattageEngine.SpriteInfo.new({
        imageRect = displayObject,
        width     = frame.width,
        height    = frame.height
    })
end


local function addFloorToLayer(layer)
    for row=1, TileEngine.rowCount do
        for col=1, TileEngine.columnCount do
            local value = TileEngine.environment[row][col]
            if value == 0 then
                layer.updateTile(
                    row,
                    col,
                    wattageEngine.Tile.new({
                        resourceKey="tiles_0"
                    })
                )
            elseif value == 1 then
                layer.updateTile(
                    row,
                    col,
                    wattageEngine.Tile.new({
                        resourceKey="tiles_1"
                    })
                )
            end
        end
    end
end


local function addWallsToLayer(layer)
    for row=1, TileEngine.rowCount do
        for col=1, TileEngine.columnCount do
            local value = TileEngine.environment[row][col]

            if value == 1 then
                layer.updateTile(
                    row,
                    col,
                    wattageEngine.Tile.new({
                        resourceKey="tiles_1"
                    }))
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

    local floorLayer = wattageEngine.TileLayer.new({
        rows    = self.rowCount,
        columns = self.columnCount
    })

    addFloorToLayer(floorLayer)
    floorLayer.resetDirtyTileCollection()

    module.insertLayerAtIndex(floorLayer, 1, 0)


    ---
    local entityLayer  = wattageEngine.EntityLayer.new({
        tileSize       = TileSize,
        spriteResolver = spriteResolver
    })

    local entityId, spriteInfo = entityLayer.addEntity("tiles_2")
    entityLayer.centerEntityOnTile(entityId, 8, 8)
    
    local wall = spriteInfo.imageRect
    physics.addBody(wall, "static", {density=1, friction=0, bounce=0, filter=Filters.obstacle})


    local playerId = entityLayer.addNonResourceEntity(player.image)
    entityLayer.centerEntityOnTile(playerId, 8, 11)


    module.insertLayerAtIndex(entityLayer, 2, 0)
    ---


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

    --lightingModel.setAmbientLight(1, 1, 1, 0.7)
end


function TileEngine:destroy()
    coreEngine.destroy()
    viewControl.destroy()

    coreEngine, viewControl, lightingModel = nil, nil, nil
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
        local x, y = focus.x / TileSize, focus.y / TileSize
        camera.setLocation(x, y)
        
        -- Update the lighting model passing the amount of time that has passed since the last frame.
        --lightingModel.update(deltaTime)
    else
        -- This is the first call to onFrame, so lastTime needs to be initialized.
        lastTime = event.time

        -- This is the initial position of the camera
        camera.setLocation(7, 7)
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