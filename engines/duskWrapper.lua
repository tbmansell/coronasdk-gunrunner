local dusk            = require("Dusk.Dusk")
local spriteSheetInfo = require("core.sheetInfo")


local TileEngine = {
    --cameraFocusOffsetY = 450,
    cameraFocusOffsetY = 0,

    data          = nil,
    map           = nil,
    tileLayer     = nil,
    objectLayer1  = nil,
    objectLayer2  = nil,
    objectLayer3  = nil,

    tileHeight    = 0,
    rows          = 0,
    cols          = 0,
    existingTiles = 0,
}


---- Environmental Collision Handlers


local function eventWallCollision(self, event)
    local other = event.other.object

    if other and event.phase == "began" and other.isProjectile then
        if other.ricochet then
            other:bounce(true)
        else
            other:impact()
        end
    end
end


local function eventHoleCollision(self, event)
    local other = event.other.object
    local hole  = self

    if other and event.phase == "began" and (other.isPlayer or other.isEnemy) then
        other:fallToDeath(hole)
    end
end


---- Tile Engine


function TileEngine:eventUpdateFrame(event, player)
    -- only implement this is more needs to happen per frame than in game handler
end


function TileEngine:init(tiles)
    dusk.setPreference("enableTileCulling", false)

    self.data       = dusk.loadMap("json/RunAndGunMap.json")
    self.tileHeight = self.data.tileheight
end


function TileEngine:destroy()
    self.map.destroy()
    self.map           = nil
    self.data          = nil
    self.tileLayer     = nil
    self.shadowLayer   = nil
    self.objectLayer1  = nil
    self.objectLayer2  = nil
    self.objectLayer3  = nil
    self.tileHeight    = 0
    self.rows          = 0
    self.cols          = 0
    self.existingTiles = 0
end


function TileEngine:loadEnvironment(environment)
    local envTiles   = environment.tiles
    local envShadows = environment.shadows

    local tiles  = self.data.layers[1].data
    local shadow = self.data.layers[2].data
    local rows   = #envTiles
    local cols   = #envTiles[1]
    
    for row=1, rows do
        for col=1, cols do
            local index   = self.existingTiles + (((row-1)*cols) + col)
            tiles[index]  = envTiles[row][col]
            --print("index: "..index.." row: "..row.." col: "..col)

            if envShadows[row][col] > 0 then
                shadow[index] = envShadows[row][col]
            end
        end
    end

    self.existingTiles = self.existingTiles + (rows * cols)
    self.rows          = self.rows + rows

    if cols > self.cols then
        self.cols = cols
    end
end


function TileEngine:buildLayers()
    self.map          = dusk.buildMap(self.data)
    self.tileLayer    = self.map.layer["TileLayer"]
    self.shadowLayer  = self.map.layer["ShadowLayer"]
    self.objectLayer1 = self.map.layer["BelowEntityLayer"]
    self.objectLayer2 = self.map.layer["EntityLayer"]
    self.objectLayer3 = self.map.layer["AboveEntityLayer"]
    
    for tile in self.tileLayer.tilesInRange(1,1, self.cols, self.rows) do
        local index = tile.tilesetGID
        local frame = spriteSheetInfo.sheet.frames[index]
        
        if frame then
            if frame.isWall then
                self:createWall(tile, frame)
            elseif frame.isHole then
                self:createHole(tile)
            end
        end
    end

    self.map:scale(0.7, 0.7)
    self.map.y = 250
end


function TileEngine:createWall(tile, frame)
    physics.addBody(tile, "static", {density=1, friction=0, bounce=0, shape=frame.shape, filter=Filters.obstacle})

    tile.collision = eventWallCollision
    tile:addEventListener("collision", tile)
    tile.isWall = true
end


function TileEngine:createHole(tile)
    local shape = {-10,-10, 10,-10, 10,10, -10,10}

    physics.addBody(tile, "static", {density=1, friction=0, bounce=0, shape=shape, filter=Filters.hole})

    tile.collision = eventHoleCollision
    tile:addEventListener("collision", tile)
    tile.isHole = true
end


function TileEngine:addEntity(entity, focus)
    self.objectLayer2:insert(entity.image)

    local moveY = self.rows   * self.tileHeight
    local xpos  = entity.xpos * self.tileHeight
    local ypos  = entity.ypos * self.tileHeight

    entity:moveTo(xpos, ypos + moveY)

    if focus then
        self.map.setCameraFocus(entity.image)
        self.tileLayer.setCameraOffset(1,    self.cameraFocusOffsetY)
        self.shadowLayer.setCameraOffset(1,  self.cameraFocusOffsetY)
        self.objectLayer2.setCameraOffset(1, self.cameraFocusOffsetY)
    end
end


function TileEngine:addProjectile(entity)
    self.objectLayer2:insert(entity.image or entity)
end


function TileEngine:addCollectable(entity)
    self.objectLayer2:insert(entity.image or entity)
end


function TileEngine:addParticle(entity)
    entity.y = entity.y + (self.cameraFocusOffsetY - 20)
    self.objectLayer3:insert(entity)
end


function TileEngine:moveBy(x, y)
    self.map.x = self.map.x + x
    self.map.y = self.map.y + y
end


return TileEngine