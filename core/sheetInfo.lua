local SheetInfo = {

    sheetContentWidth  = 1190,
    sheetContentHeight = 1190,
    tileSize           = 75,
    tilesAccross       = 15,
    tilesDown          = 15,

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
    self.frameIndex["edgeBot"]          = 121
    self.frameIndex["edgeBotRight"]     = 126
    self.frameIndex["noFloor"]          = 183

    self.frameIndex["wallTop"]          = 16
    self.frameIndex["wallBot"]          = 76
    self.frameIndex["wallLeft"]         = 47
    self.frameIndex["wallRight"]        = 51
    self.frameIndex["wallHoriz"]        = 48
    self.frameIndex["wallVert"]         = 31
    self.frameIndex["wallVertPattern"]  = 46
    self.frameIndex["wallPyramid"]      = 107
    self.frameIndex["wallTopLeft"]      = 3
    self.frameIndex["wallTopRight"]     = 5
    self.frameIndex["wallBotLeft"]      = 33
    self.frameIndex["wallBotRight"]     = 35

    self.frameIndex["shadowRightTop"]   = 156
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

    -- Setup walls
    local walls = {"wallTop", "wallBot", "wallRight", "wallLeft", "wallHoriz", "wallVert", "wallVertPattern", "wallTopLeft", "wallTopRight", "wallBotLeft", "wallBotRight", "wallPyramid"}

    for _,name in pairs(walls) do
        self:getFrame(name).isWall = true
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