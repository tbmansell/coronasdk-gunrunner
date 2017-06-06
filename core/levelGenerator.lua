local spriteSheetInfo = require("core.sheetInfo")


-- Class
local LevelGenerator = {
    MaxWidth = 25,
    MinWidth = 8,
    Height   = 20
}


function LevelGenerator:newTestEnvironment()
    return {
        {1,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  15},
        {16, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  16},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {46, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {46, 2,  2,  2,  2,  3,  4,  4,  5,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  31, 2,  2,  31, 2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  31, 2,  2,  31, 2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  33, 4,  4,  35, 2,  2,  2,  2,  2,  2,  31},
        {46, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  107,2,  107,2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  107,2,  107,2,  2,  2,  31},
        {46, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  16, 2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  79, 80, 2,  2,  2,  2,  2,  2,  2,  31},
        {76, 2,  2,  2,  2,  79, 80, 2,  2,  2,  2,  2,  2,  2,  2,  76},
        {125,2,  2,  2,  2,  76, 92, 2,  2,  2,  2,  2,  2,  2,  2,  126},
        {135,121,121,121,121,121,121,121,121,121,121,121,121,121,121,135},
    }
end


function LevelGenerator:fillTestEnvironment()
    return {
        {object="enemy",  xpos=2,  ypos=3,    type="melee",   rank=1},
        {object="enemy",  xpos=10, ypos=3,    type="melee",   rank=1},

        {object="enemy",  xpos=2,  ypos=5,    type="shooter", rank=1},
        {object="enemy",  xpos=7,  ypos=7,    type="shooter", rank=1},
        {object="enemy",  xpos=12, ypos=7,    type="shooter", rank=1},
        {object="enemy",  xpos=7,  ypos=10,   type="shooter", rank=1},
        
        {object="enemy",  xpos=9,  ypos=10,   type="shooter", rank=2},
        {object="enemy",  xpos=12, ypos=10,   type="shooter", rank=2},
        
        {object="enemy",  xpos=12, ypos=5,    type="shooter", rank=3},

        {object="weapon", xpos=3, ypos=3,     type="launcher"},
    }
end


function LevelGenerator:newEnvironment()
end



function LevelGenerator:fillEnvironment()
end


return LevelGenerator