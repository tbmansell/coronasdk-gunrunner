local SheetInfo = {

    sheetContentWidth  = 1185,
    sheetContentHeight = 710,
    tileSize           = 75,
    tilesAccross       = 15,
    tilesDown          = 9,

    sheet = {
        frames = {}
    },

    frameIndex = {
        --[[
        ["edgeTopLeft"]     = 1,
        ["edgeTopRight"]    = 15,
        ["edgeBotLeft"]     = 135,
        ["edgeBotRight"]    = 120,

        ["plain"]           = 2,

        ["wallTop"]         = 16,
        ["wallBot"]         = 76,
        ["wallHoriz"]       = 4,
        ["wallVert"]        = 46,
        ["wallVertPattern"] = 61,
        
        ["wallTopLeft"]     = 3,
        ["wallTopRight"]    = 5,
        ["wallBotLeft"]     = 47,
        ["wallBotRight"]    = 49,
        ]]
    },

    nameIndex = {},
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

    self.frameIndex["edgeTopLeft"]      = 1
    self.frameIndex["edgeTopRight"]     = 15
    self.frameIndex["edgeBotLeft"]      = 125
    self.frameIndex["edgeBot"]          = 121
    self.frameIndex["edgeBotRight"]     = 126
    self.frameIndex["noFloor"]          = 135



    self.frameIndex["wallTop"]          = 16
    self.frameIndex["wallBot"]          = 76
    self.frameIndex["wallHoriz"]        = 4
    self.frameIndex["wallVert"]         = 31
    self.frameIndex["wallVertPattern"]  = 46
    self.frameIndex["wallPyramid"]      = 107
    self.frameIndex["wallTopLeft"]      = 3
    self.frameIndex["wallTopRight"]     = 5
    self.frameIndex["wallBotLeft"]      = 33
    self.frameIndex["wallBotRight"]     = 35
    self.frameIndex["wallDiagTopRight"] = 80
    self.frameIndex["wallDiagBotRight"] = 79
    self.frameIndex["wallDiagTopLeft"]  = 81
    self.frameIndex["wallDiagBotLeft"]  = 82
end


function SheetInfo:setupSpecialTiles()
    local size, half = self.tileSize, self.tileSize / 2

    -- Setup walls
    local walls = {"wallTop", "wallBot", "wallHoriz", "wallVert", "wallVertPattern", "wallTopLeft", "wallTopRight", "wallBotLeft", "wallBotRight", "wallPyramid", "wallDiagTopRight", "wallDiagBotRight", "wallDiagTopLeft", "wallDiagBotLeft"}

    for _,name in pairs(walls) do
        self:getFrame(name).isWall = true
    end

    -- Setup diagonal wall shapes:
    self:getFrame("wallDiagTopRight").shape = {-half,-half, half,-half, -half,half}
    self:getFrame("wallDiagBotRight").shape = {half,-half,  half,half,  -half,half}

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