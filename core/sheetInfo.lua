local SheetInfo = {

    sheetContentWidth  = 750,
    sheetContentHeight = 500,

    sheet = {
        frames = {
            {
                -- tiles_0
                x=51, 
                y=1,
                width=50,
                height=50,
            },
            {
                -- tiles_1
                x=1,
                y=51,
                width=50,
                height=50,
            },
            {
                -- tiles_2
                x=1,
                y=101,
                width=50,
                height=50,
            },
            {
                -- tiles_3
                x=1,
                y=301,
                width=50,
                height=50,
            },
        }
    },

    frameIndex = {
        ["tiles_0"] = 1,
        ["tiles_1"] = 2,
        ["tiles_2"] = 3,
        ["tiles_3"] = 4,
    },
}


function SheetInfo:getSheet()
    return self.sheet;
end


function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end


return SheetInfo