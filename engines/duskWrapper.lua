local dusk            = require("Dusk.Dusk")
local spriteSheetInfo = require("core.sheetInfo")


local TileEngine = {
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
            other:impact(true)
        end
    end

    if other and other.isEnemy and other.turnsOnMove then
        other:stopMomentum()
        other:loop(other.stationaryAnim)
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
    local shadow = self.data.layers[3].data
    local rows   = #envTiles
    local cols   = #envTiles[1]
    
    for row=1, rows do
        for col=1, cols do
            local index   = self.existingTiles + (((row-1)*cols) + col)
            tiles[index]  = envTiles[row][col]
            --print("index: "..index.." row: "..row.." col: "..col.." tile="..tostring(tiles[index]))
--            print("shadows: "..row..", "..col)
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


function TileEngine:addEntity(entity, focus, layer)
    if layer and layer == 1 then
        self.objectLayer1:insert(entity.image)
    else
        self.objectLayer2:insert(entity.image)
    end

    local moveY = self.rows   * self.tileHeight
    local xpos  = entity.xpos * self.tileHeight
    local ypos  = entity.ypos * self.tileHeight

    entity:moveTo(xpos, ypos + moveY)

    if focus then
        self.map.setCameraFocus(entity.image)
        self:setCameraOffset()
    end
end


function TileEngine:addProjectile(entity)
    self.objectLayer2:insert(entity.image or entity)
end


function TileEngine:addCollectable(entity)
    self.objectLayer1:insert(entity.image or entity)
end


function TileEngine:addParticle(entity)
    entity.y = entity.y + (self.cameraFocusOffsetY - 20)
    self.objectLayer1:insert(entity)
end


function TileEngine:setCameraOffset(offsetX, offsetY)
    local x = offsetX or 0
    local y = offsetY or self.cameraFocusOffsetY

    self.tileLayer.setCameraOffset(x, y)
    self.shadowLayer.setCameraOffset(x, y)
    self.objectLayer1.setCameraOffset(x, y)
    self.objectLayer2.setCameraOffset(x, y)
    self.objectLayer3.setCameraOffset(x, y)
end


function TileEngine:setAngleOffset(angle)
    local offsetX, offsetY = nil, nil

    if angle > -90 and angle < 90 then
        offsetX = -angle / 3
        -- default Y to normal offset

    elseif angle >= 90 and angle < 180 then
        offsetX = -(180-angle) / 3
        offsetY = -(angle-90) / 5

    elseif angle <= 270 then
        offsetX = (angle-180) / 3
        offsetY = (angle-270) / 5
    end

    self:setCameraOffset(offsetX, offsetY)
end


function TileEngine:moveBy(x, y)
    self.map.x = self.map.x + x
    self.map.y = self.map.y + y
end


return TileEngine