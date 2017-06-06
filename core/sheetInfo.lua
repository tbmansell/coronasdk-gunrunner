local SheetInfo = {

    sheetContentWidth  = 1185,
    sheetContentHeight = 710,

    sheet = {
        frames = {
            {  -- plain
                x=77,   y=2,
            },
            {   -- wallTop
                x=2,    y=77,
            },
            {   -- wallBot
                x=2,    y=377,
            },
            {   -- wallVert
                x=2,    y=152,
            },
            {   -- wallHoriz
                x=227,  y=2,
            },
            {   -- wallTopLeft
                x=156, y=2,
            },
            {   -- wallTopRight
                x=310,  y=2,
            },
            {   -- wallBotLeft
                x=156,  y=156,
            },
            {   -- wallBotRight
                x=310,  y=156,
            },
        }
    },

    frameIndex = {
        ["plain"]       = 1,
        ["wallTop"]     = 2,
        ["wallBot"]     = 3,
        ["wallVert"]    = 4,
        ["wallHoriz"]   = 5,
        ["wallTopLeft"] = 6,
        ["wallTopRight"]= 7,
        ["wallBotLeft"] = 8,
        ["wallBotRight"]= 9,
    },

    nameIndex = {},
}


function SheetInfo:setup()
    -- Add dimensions to tile frames:
    for _,frame in pairs(self.sheet.frames) do
        frame.width, frame.height = 75, 75
    end

    -- Create reverse mapping of frameIndex to get tile name from index position (which is what the tiles are specified in)
    for k,v in pairs(self.frameIndex) do
        self.nameIndex[v - 1] = k
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


return SheetInfo