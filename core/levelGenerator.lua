local spriteSheetInfo = require("core.sheetInfo")


-- Class
local LevelGenerator = {
    MaxWidth     = 25,
    MinWidth     = 8,
    StartWidth   = 20, 
    Height       = 20,

    environments = {},
    tiles        = {},
}

-- Aliases:
local random = math.random


function LevelGenerator:setup()
    spriteSheetInfo:setup()

    self.tiles.default          = spriteSheetInfo:getFrameIndex("plain")

    self.tiles.noFloor          = spriteSheetInfo:getFrameIndex("noFloor")

    self.tiles.wallTop          = spriteSheetInfo:getFrameIndex("wallTop")
    self.tiles.wallBot          = spriteSheetInfo:getFrameIndex("wallBot")
    self.tiles.wallHoriz        = spriteSheetInfo:getFrameIndex("wallHoriz")
    self.tiles.wallVert         = spriteSheetInfo:getFrameIndex("wallVert")
    self.tiles.wallVertPattern  = spriteSheetInfo:getFrameIndex("wallVertPattern")
    self.tiles.wallPyramid      = spriteSheetInfo:getFrameIndex("wallPyramid")
    self.tiles.wallTopLeft      = spriteSheetInfo:getFrameIndex("wallTopLeft")
    self.tiles.wallTopRight     = spriteSheetInfo:getFrameIndex("wallTopRight")
    self.tiles.wallBotLeft      = spriteSheetInfo:getFrameIndex("wallBotLeft")
    self.tiles.wallBotRight     = spriteSheetInfo:getFrameIndex("wallBotRight")
    self.tiles.wallDiagTopRight = spriteSheetInfo:getFrameIndex("wallDiagTopRight")
    self.tiles.wallDiagBotRight = spriteSheetInfo:getFrameIndex("wallDiagBotRight")
    self.tiles.wallDiagTopLeft  = spriteSheetInfo:getFrameIndex("wallDiagTopLeft")
    self.tiles.wallDiagBotLeft  = spriteSheetInfo:getFrameIndex("wallDiagBotLeft")
end


function LevelGenerator:destroy()
    self.environments = {}
    self.tiles = {}
end


function LevelGenerator:newTestEnvironment()
    self:setup()

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
    local env = {
        tiles = {}
    }

    self:setup()
    self:setEnvironmentWidth(env)
    self:setEnvironmentShape(env)
    self:setEnvironmentEdges(env)
    self:setEnvironmentWalls(env)
    self:setEnvironmentFloor(env)

    self.environments[#self.environments + 1] = env

    return env.tiles
end


function LevelGenerator:setEnvironmentWidth(env)
    local number = #self.environments

    -- First determine if there is a previous environment, if so we must start at that width:
    if number > 0 then
        local prev = self.environments[number]
        env.width  = prev.width
        env.height = prev.height
        env.dir    = prev.dir
        env.number = number + 1
    else
        -- This is the first section
        env.width  = self.StartWidth
        env.height = self.Height
        env.dir    = "straight" 
        env.number = 1
    end
end


function LevelGenerator:setEnvironmentShape(env)
    -- Determine if we are going to change shape in this env
    if random(100) > 100 then
        -- 1. Determine what direction it will change to
        -- 2. Determine where the direction change will occur
    else
        -- Stick with the same direction throughout
        if env.dir == "straight" then
            for y=1, env.height do
                env.tiles[y] = {}

                for x=1, env.width do
                    env.tiles[y][x] = self.tiles.default
                end
            end
        end
    end
end


function LevelGenerator:setEnvironmentEdges(env)
    -- Go along each edge and determine where walls and gaps appear
    if env.dir == "straight" then
        -- strting from bottom, left go up side and work out presence of wall or gap with length until reaching the end
        -- restrictions: wall have minimum width of 3 tiles (top, middle, bottom)

        local x = 1
        local y = env.height

        self:setStraightEdge(env, 1,         env.height)
        self:setStraightEdge(env, env.width, env.height)
    end
end


function LevelGenerator:setStraightEdge(env, x, y)
    while y > 1 do
        -- 75% chance of wall each time
        if y > 3 and random(100) > 25 then
            -- Determine wall length: 3 max: height left
            local length = random(y-2)

            env.tiles[y][x] = self.tiles.wallBot

            for i=1, length do
                env.tiles[y-i][x] = self.tiles.wallVert
            end

            env.tiles[y-length-1][x] = self.tiles.wallTop

            -- leave a gap after a wall
            y = y - (2+length)

            if y > 0 then
                env.tiles[y][x] = self.tiles.noFloor
            end
        else
            -- Leave a space up to max of length remaining
            local gap = random(y-1)

            for i=0, gap do
                env.tiles[y-i][x] = self.tiles.noFloor
            end

            y = y - gap                
        end
    end
end


function LevelGenerator:setEnvironmentWalls(env)
    -- Generate each wall as we go and place it, from bottom left to bottom right and going up,
    -- so we can work out how much space we have widthwise and then going up
end


function LevelGenerator:setEnvironmentFloor(env)
    -- Determine any special tiles, or floor patterns or random tiling patterns on plain tiles
end


function LevelGenerator:fillEnvironment()
    return {}
end


return LevelGenerator