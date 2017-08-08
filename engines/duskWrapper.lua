local dusk            = require("Dusk.Dusk")
local spriteSheetInfo = require("core.sheetInfo")


local TileEngine = {
    map          = nil,
    tileLayer    = nil,
    objectLayer1 = nil,
    objectLayer2 = nil,
    objectLayer3 = nil,

    rows = 0,
    cols = 0,
    existingTiles = 0,
}


local function eventWallCollision(self, event)
    local other = event.other.object

    if other and other.isProjectile then 
        sounds:projectile(other.weapon.hitSound)
        other:destroy()
    end
end


function TileEngine:eventUpdateFrame(event, player)
end


function TileEngine:create(view, tiles, levelGenerator)
    dusk.setPreference("enableTileCulling", false)

    self.data       = dusk.loadMap("json/RunAndGunMap.json")
    self.tileHeight = self.data.tileheight
    
    for i=1, 1 do
        self:loadEnvironment(levelGenerator:newEnvironment())
    end

    self.map          = dusk.buildMap(self.data)
    self.tileLayer    = self.map.layer["TileLayer"]
    self.objectLayer1 = self.map.layer["BelowEntityLayer"]
    self.objectLayer2 = self.map.layer["EntityLayer"]
    self.objectLayer3 = self.map.layer["AboveEntityLayer"]

    print("cols="..self.cols.." rows="..self.rows)
    --self.tileLayer.lock(1,1, self.cols, self.rows, "d")

    for tile in self.tileLayer.tilesInRange(1,1, self.cols, self.rows) do
        local index = tile.tilesetGID
        local frame = spriteSheetInfo.sheet.frames[index]

        --print("tile ["..tile.tileX..","..tile.tileY.."] index="..tostring(index))
        
        if frame then
            if frame.isWall then
                physics.addBody(tile, "static", {density=1, friction=0, bounce=0, shape=frame.shape, filter=Filters.obstacle})

                tile.collision = eventWallCollision
                tile:addEventListener("collision", tile)
                tile.isWall = true
                
            elseif frame.isHole then
                --self:addSpecialTile(layer, frame, name, row, col, eventHoleCollision, Filters.hole)
            end
        end
    end

    self.map:scale(0.7, 0.7)
end


function TileEngine:loadEnvironment(environment)
    local flat = self.data.layers[1].data
    local rows = #environment
    local cols = #environment[1]
    
    --print("rows="..self.rows.." cols="..self.cols.." existingTiles="..self.existingTiles)
    
    for row=1, rows do
        for col=1, cols do
            local index = self.existingTiles + (((row-1)*cols) + col)
            flat[index] = environment[row][col]
        end
    end

    self.existingTiles = self.existingTiles + (rows * cols)
    self.rows          = self.rows + rows

    if cols > self.cols then
        self.cols = cols
    end
end


function TileEngine:destroy()
    self.map.destroy()
    self.tileLayer    = nil
    self.objectLayer1 = nil
    self.objectLayer2 = nil
    self.objectLayer3 = nil

    --self.tileLayer.collision = eventWallCollision
    --self.tileLayer("collision", self.tileLayer)
end


function TileEngine:addEntity(entity, focus)
    self.objectLayer2:insert(entity.image)

    local moveY = self.rows   * self.tileHeight
    local xpos  = entity.xpos * self.tileHeight
    local ypos  = entity.ypos * self.tileHeight

    print(tostring(entity.class).." entity at "..xpos..", "..ypos.." moveY="..moveY)

    entity:moveTo(xpos, ypos + moveY)

    if focus then
        self.map.setCameraFocus(entity.image)
        self.tileLayer.setCameraOffset(1,    450)
        self.objectLayer2.setCameraOffset(1, 450)
    end
end


function TileEngine:addProjectile(entity)
    self.objectLayer2:insert(entity.image)
end


function TileEngine:moveBy(x, y)
    self.map.x = self.map.x + x
    self.map.y = self.map.y + y
end


return TileEngine