local wattageEngine   = require("plugin.wattageTileEngine")
local spriteSheetInfo = require("core.sheetInfo")
local levelGenerator  = require("core.levelGenerator")


TileEngine = {
    environment = nil,
    rowCount    = nil,
    columnCount = nil,

    floorLayer  = nil,
    wallLayer   = nil,
    entityLayer = nil,
}

-- Aliases:
local sqrt  = math.sqrt
local floor = math.floor

-- Local variables:
local coreEngine                  -- Reference to the tile engine
local lightingModel               -- Reference to the lighting model
local viewControl                 -- Reference to the UI view control
local regionManager               -- Reference to RegionManager
local spriteSheet
local spriteResolver = {}
local entityResolver = {}
local regionListener = {}
local cameraFocus    = nil
local lastTime       = 0

local TileSize          = 75
local BufferLayerIndex  = 1
local FloorLayerIndex   = 2
local WallLayerIndex    = 3
local EntityLayerIndex  = 4
--local CameraSpeed       = 4 / 1000      -- Camera speed, 4 tiles per second



regionListener.getRegion = function(params)
    local absoluteRegionRow = params.absoluteRegionRow
    local absoluteRegionCol = params.absoluteRegionCol
    local topRowOffset      = params.topRowOffset
    local leftColumnOffset  = params.leftColumnOffset

    print("regionListener.getRegion: row="..tostring(absoluteRegionRow).." col="..tostring(absoluteRegionCol).." rowOff="..tostring(topRowOffset).." colOff="..tostring(leftColumnOffset))
    
    --[[
    if (absoluteRegionRow % 2 == 0 and absoluteRegionCol % 2 == 0) or
        absoluteRegionRow % 2 == 0 or
        absoluteRegionCol % 2 == 0
    then]]
        return {
            tilesByLayerIndex = {
                levelGenerator:newEnvironment()
            }
        }
    --end
    
    --return {}
end


regionListener.regionReleased = function(regionData)
    print("regionListener.regionReleased")
end



spriteResolver.resolveForKey = function(key)
    --local frameIndex    = spriteSheetInfo:getFrameIndex(key)
    --local frame         = spriteSheetInfo.sheet.frames[frameIndex]
    --local displayObject = display.newImageRect(spriteSheet, frameIndex, frame.width, frame.height)

    local frame         = spriteSheetInfo.sheet.frames[key]
    local displayObject = display.newImageRect(spriteSheet, key, frame.width, frame.height)
    
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

    if other and other.isPlayer then
        sounds:player("killed")
        other:fallToDeath(event)
    end
end


local function addSpecialTile(layer, frame, name, row, col, event, filter)
    local entityId, spriteInfo = layer.addEntity(name)
    
    layer.centerEntityOnTile(entityId, row, col)

    local item = spriteInfo.imageRect

    physics.addBody(item, "static", {density=1, friction=0, bounce=0, shape=frame.shape, filter=filter})

    item.collision = event
    item:addEventListener("collision", item)
    return item
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
                    local item  = addSpecialTile(layer, frame, name, row, col, eventWallCollision, Filters.obstacle)
                    item.isWall = true
                    
                elseif frame.isHole then
                    addSpecialTile(layer, frame, name, row, col, eventHoleCollision, Filters.hole)
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


function TileEngine:create(group, tileSheet, environment)
    self.sceneGroup  = group
    self.environment = environment
    self.rowCount    = 96 --#environment
    self.columnCount = 80 --#environment[1]

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

    regionManager = wattageEngine.RegionManager.new({
        regionWidthInTiles  = #environment[1],    --20,
        regionHeightInTiles = #environment,       --24,
        renderRegionWidth   = 1,
        renderRegionHeight  = 1,
        tileSize            = TileSize,
        tileLayersByIndex   = { [BufferLayerIndex] = self.bufferLayer },
        entityLayersByIndex = { [EntityLayerIndex] = self.entityLayer },
        camera              = viewControl.getCamera(),
        listener            = regionListener
    })

    lightingModel.setAmbientLight(1, 1, 1, 1)

    viewControl.getCamera().setZoom(0.1)
end


function TileEngine:createLayers(wattageEngine, module)
    -- Add elements to layers
    self.bufferLayer = wattageEngine.TileLayer.new({
        rows    = self.rowCount,
        columns = self.columnCount
    })
    --[[
    self.floorLayer = wattageEngine.TileLayer.new({
        rows    = self.rowCount,
        columns = self.columnCount
    })
    
    self.wallLayer  = wattageEngine.EntityLayer.new({
        tileSize       = TileSize,
        spriteResolver = spriteResolver
    })
    ]]
    self.entityLayer  = wattageEngine.EntityLayer.new({
        tileSize       = TileSize,
        spriteResolver = entityResolver
    })
    
    --addFloorToLayer(self.floorLayer)
    --addWallsToLayer(self.wallLayer)
    
    self.bufferLayer.resetDirtyTileCollection()
    --self.floorLayer.resetDirtyTileCollection()

    module.insertLayerAtIndex(self.bufferLayer, BufferLayerIndex, 0)
    --module.insertLayerAtIndex(self.floorLayer,  FloorLayerIndex, 0)
    --module.insertLayerAtIndex(self.wallLayer,   WallLayerIndex, 0)
    module.insertLayerAtIndex(self.entityLayer, EntityLayerIndex, 0)
end


function TileEngine:destroy()
    coreEngine.destroy()
    viewControl.destroy()

    coreEngine, viewControl, lightingModel = nil, nil, nil
end


function TileEngine:addProjectile(entity)
    print("add projectile")
    self.entityLayer.addNonResourceEntity(entity.image)
end


function TileEngine:addEntity(entity, isFocus)
    print("addEntity "..entity.class.." isFocus="..tostring(isFocus))

    --local id = self.entityLayer.addNonResourceEntity(entity.image)

    if isFocus then
        cameraFocus = id
    end

    if entity.xpos or entity.ypos then
        local x = (entity.xpos or 0) --* TileSize
        local y = (entity.ypos or 0) --* TileSize
        print("move to: "..x..", "..y)
        --regionManager.setNonResourceEntityLocation(EntityLayerIndex, id, x, y)
    end
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

        if cameraFocus then
            local x, y = regionManager.getNonResourceEntityLocation(EntityLayerIndex, cameraFocus)
            --print("cameraFocus: x="..x.." y="..y.." trueX="..(x/TileSize).." trueY="..(y/TileSize))
            --regionManager.setCameraLocation(x / TileSize, y / TileSize)
            --[[
            if x and y then
                regionManager.setCameraLocation(x, y)
            end]]

            if globalTEDebugDraw then
                globalTEDebugDraw:removeSelf()
            end
            --globalTEDebugDraw = draw:newText(self.sceneGroup, "cameraFocus x="..tostring(x).." y="..tostring(y), 50, 350, 0.6, "white", "left")
        end
        
        -- Update the lighting model passing the amount of time that has passed since the last frame.
        --lightingModel.update(deltaTime)
    else
        -- This is the first call to onFrame, so lastTime needs to be initialized.
        lastTime = event.time

        -- This is the initial position of the camera
        regionManager.setCameraLocation(10, 20)

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