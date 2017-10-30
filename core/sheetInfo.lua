local SheetInfo = {

    sheetContentWidth  = 1190,
    sheetContentHeight = 1190,
    tilesInSet         = 210,
    tileSize           = 75,
    tilesAccross       = 15,
    tilesDown          = 25,
    --tilesDown          = 15,

    sheet = {
        frames = {}
    },
    frameIndex = {},
    nameIndex  = {},
}


function SheetInfo:setup()
    local size = self.tileSize

    -- Create sheet frame coordinates
    for y=0, self.tilesDown do
        for x=0, self.tilesAccross-1 do
            local frame = {
                x      = (x * size) + ((x+1) * 2),
                y      = (y * size) + ((y+1) * 2),
                width  = size,
                height = size
            }

            local index = #self.sheet.frames + 1
            
            self.sheet.frames[index] = frame

            -- TEMPORARY: until all indexes manually added
            self.frameIndex[tostring(index)] = index
        end
        
    end

    -- setup tile attributes:
    self:nameTiles()
    self:setupSpecialTiles()

    -- Create reverse mapping of frameIndex to get tile name from index position (which is what the tiles are specified in)
    for k,v in pairs(self.frameIndex) do
        self.nameIndex[v] = k
    end
end


function SheetInfo:nameTiles()
    -- Create names to reference tiles
    self.frameIndex["plain"]            = 2
    self.frameIndex["plain-1"]          = 6
    self.frameIndex["plain-2"]          = 7
    self.frameIndex["plain-3"]          = 8
    self.frameIndex["plain-4"]          = 9
    self.frameIndex["plain-5"]          = 21
    self.frameIndex["plain-6"]          = 22
    self.frameIndex["plain-7"]          = 23
    self.frameIndex["plain-8"]          = 24
    self.frameIndex["plain-9"]          = 36
    self.frameIndex["plain-10"]         = 37
    self.frameIndex["plain-11"]         = 38
    self.frameIndex["plain-12"]         = 39

    self.frameIndex["pattern-hazzard"]  = 89
    self.frameIndex["pattern-pipes"]    = 13
    self.frameIndex["pattern-grill"]    = 11

    self.frameIndex["edgeTopLeft"]      = 1
    self.frameIndex["edgeTopRight"]     = 15
    self.frameIndex["edgeBotLeft"]      = 125
    self.frameIndex["edgeBot"]          = 140
    self.frameIndex["edgeBotRight"]     = 126
    self.frameIndex["noFloor"]          = 183

    -- same as edgeBot BUT not marked as edge so we dont add needless physcics shape (for inside box)
    self.frameIndex["boxEdgeTop"]       = 140

    self.frameIndex["wallTop"]          = 16
    self.frameIndex["wallBot"]          = 76
    self.frameIndex["wallLeft"]         = 47
    self.frameIndex["wallRight"]        = 51
    self.frameIndex["wallHoriz"]        = 48
    self.frameIndex["wallHoriz2"]       = 49
    self.frameIndex["wallHoriz3"]       = 50
    self.frameIndex["wallHoriz4"]       = 4
    self.frameIndex["wallVert"]         = 31
    self.frameIndex["wallVert2"]        = 46
    self.frameIndex["wallVert3"]        = 61
    self.frameIndex["wallVert4"]        = 20
    self.frameIndex["wallTopLeft"]      = 3
    self.frameIndex["wallTopRight"]     = 5
    self.frameIndex["wallBotLeft"]      = 33
    self.frameIndex["wallBotRight"]     = 35
    -- different style wall block
    self.frameIndex["wallBlock"]        = 188
    self.frameIndex["wallBlock2"]       = 189
    self.frameIndex["wallBlock3"]       = 190
    self.frameIndex["wallBlock4"]       = 191

    self.frameIndex["shadowRightTop"]   = 152
    self.frameIndex["shadowRight"]      = 167
    self.frameIndex["shadowRightBot"]   = 197
    self.frameIndex["shadowBotLeft"]    = 168
    self.frameIndex["shadowBot"]        = 169

    self.frameIndex["paintRedTopLeft"]  = 52
    self.frameIndex["paintRedTopRight"] = 54
    self.frameIndex["paintRedHoriz"]    = 53
    self.frameIndex["paintRedVert"]     = 82
    self.frameIndex["paintRedBotLeft"]  = 67
    self.frameIndex["paintRedBotRight"] = 69

    self.frameIndex["paintBlueTopLeft"]  = 262
    self.frameIndex["paintBlueTopRight"] = 264
    self.frameIndex["paintBlueHoriz"]    = 263
    self.frameIndex["paintBlueVert"]     = 292
    self.frameIndex["paintBlueBotLeft"]  = 277
    self.frameIndex["paintBlueBotRight"] = 279
end


function SheetInfo:setupSpecialTiles()
    local size, half = self.tileSize, self.tileSize / 2
    local numTiles   = #self.sheet.frames

    -- Setup walls
    local walls = {"wallTop", "wallBot", "wallRight", "wallLeft", "wallHoriz", "wallHoriz2", "wallHoriz3", "wallHoriz4", "wallVert", "wallVert2", "wallVert3", "wallVert4", 
                   "wallTopLeft", "wallTopRight", "wallBotLeft", "wallBotRight", "wallBlock", "wallBlock2", "wallBlock3", "wallBlock4"}

    for _,name in pairs(walls) do
        local index = self:getFrameIndex(name)
        self.sheet.frames[index].isWall = true
        
        -- update for second tileset underneath
        local index2 = index + self.tilesInSet

        if index2 <= numTiles then
            self.sheet.frames[index2].isWall = true
        end

        --self:getFrame(name).isWall = true
    end

    -- Setup holes:
    local holes = {"edgeTopLeft", "edgeTopRight", "edgeBotLeft", "edgeBotRight", "edgeBot", "noFloor"}

    for _,name in pairs(holes) do
        self:getFrame(name).isHole = true
    end

end


function SheetInfo:getSheet()
    return self.sheet
end


function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name]
end


function SheetInfo:getName(index)
    return self.nameIndex[index]
end


function SheetInfo:getFrame(name)
    return self.sheet.frames[ self.frameIndex[name] ]
end


return SheetInfo