local spriteSheetInfo = require("core.sheetInfo")


-- Class
local LevelGenerator = {
    MaxWidth     = 25,
    MinWidth     = 8,
    StartWidth   = 20,
    Height       = 24,

    environments = {},
    tiles        = {},
}

-- Aliases:
local random = math.random


local function percent(chance)
    return random(100) < chance
end


function LevelGenerator:setup()
    spriteSheetInfo:setup()

    self.tiles.default          = spriteSheetInfo:getFrameIndex("plain")

    self.tiles.noFloor          = spriteSheetInfo:getFrameIndex("noFloor")

    self.tiles.wallTop          = spriteSheetInfo:getFrameIndex("wallTop")
    self.tiles.wallBot          = spriteSheetInfo:getFrameIndex("wallBot")
    self.tiles.wallLeft         = spriteSheetInfo:getFrameIndex("wallLeft")
    self.tiles.wallRight        = spriteSheetInfo:getFrameIndex("wallRight")
    
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

    -- Random selection of plain tiles
    self.tiles.plain = {}

    for i=1, 12 do
        self.tiles.plain[i] = spriteSheetInfo:getFrameIndex("plain-"..i)
    end 
end


function LevelGenerator:destroy()
    self.environments = {}
    self.tiles = {}
end


function LevelGenerator:newTestEnvironmentStraight()
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
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {46, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {31, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {76, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  76},
        {125,2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  126},
        {135,121,121,121,121,121,121,121,121,121,121,121,121,121,121,135},
    }
end


function LevelGenerator:newTestEnvironmentLeft()
    self:setup()

    return {
        {118,2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  15},
        {135,118,2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  16},
        {135,135,118,2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {135,135,135,118,2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {135,135,135,135,118,2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {135,135,135,135,135,118,2,  2,  2,  2,  2,  2,  2,  2,  2,  31},
        {135,135,135,135,135,135,118,2,  2,  2,  2,  2,  2,  2,  2,  31},
        {135,135,135,135,135,135,135,118,2,  2,  2,  2,  2,  2,  2,  31},
        {135,135,135,135,135,135,135,135,118,2,  2,  2,  2,  2,  2,  31},
        {135,135,135,135,135,135,135,135,135,118,2,  2,  2,  2,  2,  31},
        {135,135,135,135,135,135,135,135,135,135,118,2,  2,  2,  2,  31},
        {135,135,135,135,135,135,135,135,135,135,135,118,2,  2,  2,  31},
        {135,135,135,135,135,135,135,135,135,135,135,135,118,2,  2,  31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,118,2,  31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
        {135,135,135,135,135,135,135,135,135,135,135,135,135,135,118,31},
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


function LevelGenerator:nextEnvironment()
    return self.environments[1]
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
    if percent(0) then
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
        if y > 3 and percent(75) then
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
    -- Some rules:
    --    > Every wall must have a gap of two tiles between it and any other, to avoid fiddly levels where you will get stuck and frustrated
    --    > A wall can have a max width (assuming no other walls on its width) of width - 6 (min gap 2 from each edge)
    --    > placement of a wall will be deterined based on if another wall can be fit next to it, if not, it will be more central (TBC)
    --    > Basic logic is that a wall must start 2 tiles back (until possible to detect if gaps in previous ENV), and end 2 tiles before end
    --    > So a wall can also have a max width of height - 4

    -- list of types of single wall lines
    --local lines   = {"vertical", "horizontal", "diagonalLeft", "diagonalRight", "zigzag", "dynamic"}
    -- list of types of contained wall shapes
    --local shapes  = {"square", "rectangle", "cross", "diamond", "lShape", "x"}
    -- list of patterns of single point walls
    --local singles = {"alone", "vertical", "horizontal", "grid"}

    local spaceY = env.height - 2

    while spaceY >= 4 do
        local pattern = "horiz"

        if spaceY >= 10 then
            local r = random(100)

            if     r <= 33 then pattern = "horiz"
            elseif r <= 66 then pattern = "vert"
            else                pattern = "box" end
        end

        --print(pattern.." "..spaceY)

        if pattern == "horiz" then
            self:makeStripHorizWalls(env, spaceY)
            spaceY = spaceY - 6

        elseif pattern == "vert" then
            self:makeStripVertWalls(env, spaceY)
            spaceY = spaceY - 12

        elseif pattern == "box" then
            local length = self:makeStripBoxWalls(env, spaceY)
            spaceY = spaceY - length
        end

    end
end


function LevelGenerator:makeStripHorizWalls(env, y)
    local spaceX = env.width - 6
    local walls  = random(4)
    local randY  = percent(50)

    if walls == 1 then
        local width = 2 + random(9)
        local x     = 3 + random(spaceX - width)

        self:makeHorizWall(env, x, y, width, randY)

    elseif walls == 2 then
        local width1 = 1  + random(4)
        local width2 = 1  + random(4)
        local x1     = 3  + random((spaceX/2) - width1)
        local x2     = 11 + random((spaceX/2) - width2)

        self:makeHorizWall(env, x1, y, width1, randY)
        self:makeHorizWall(env, x2, y, width2, randY)

    elseif walls == 3 then
        local width1 = 1 + random(2)
        local width2 = 1 + random(2)
        local width3 = 1 + random(2)
        local x2     = 8 + random(2)

        self:makeHorizWall(env, 4,  y, width1, randY)
        self:makeHorizWall(env, x2, y, width2, randY)
        self:makeHorizWall(env, 15, y, width3, randY)

    elseif walls == 4 then
        self:makeHorizWall(env, 4,  y, 2, randY)
        self:makeHorizWall(env, 8,  y, 2, randY)
        self:makeHorizWall(env, 12, y, 2, randY)
        self:makeHorizWall(env, 16, y, 2, randY)
    end
end


function LevelGenerator:makeStripVertWalls(env, y)
    local spaceX = env.width - 6
    local walls  = random(4)
    local length = 2 + random(7)

    if walls == 1 then
        local x = 3 + random(spaceX - 1)

        self:makeVertWall(env, x, y, length)

    elseif walls == 2 then
        local x1 = 3  + random((spaceX/2)-1)
        local x2 = 11 + random((spaceX/2)-1)

        self:makeVertWall(env, x1, y, length)
        self:makeVertWall(env, x2, y, length)

    elseif walls == 3 then
        local x1 = 3  + random(3)
        local x2 = 8  + random(3)
        local x3 = 13 + random(3)

        self:makeVertWall(env, x1, y, length)
        self:makeVertWall(env, x2, y, length)
        self:makeVertWall(env, x3, y, length)

    elseif walls == 4 then
        local x1 = 4
        local x2 = 7  + random(2)
        local x3 = 12 + random(2)
        local x4 = 17

        self:makeVertWall(env, x1, y, length)
        self:makeVertWall(env, x2, y, length)
        self:makeVertWall(env, x3, y, length)
        self:makeVertWall(env, x4, y, length)
    end

    return length + 2
end


function LevelGenerator:makeStripBoxWalls(env, y)
    local spaceX = env.width - 6
    local walls  = random(2)

    if walls == 1 then
        local width  = 2 + random(5)
        local height = 2 + random(5)
        local x      = 3 + random(spaceX - width)

        self:makeBoxWall(env, x, y, width, height)

    elseif walls == 2 then
        local width1  = 1 + random(3)
        local width2  = 1 + random(3)
        local height1 = 1 + random(3)
        local height2 = 1 + random(3)
        local x1      = 3  + random((spaceX/2) - width1 - 2)
        local x2      = 11 + random((spaceX/2) - width2 - 2)

        self:makeBoxWall(env, x1, y, width1, height1)
        self:makeBoxWall(env, x2, y, width2, height2)
    end

    return 12
end


function LevelGenerator:makeHorizWall(env, x, y, width, randY)
    --print("vert: x="..x.." y="..y.." width="..width)

    if randY then
        y = (y-2) + random(3)
    end

    env.tiles[y][x] = self.tiles.wallLeft

    local middle = width - 2

    for i=1, middle do
        env.tiles[y][x + i] = self.tiles.wallHoriz
    end

    env.tiles[y][x + middle + 1] = self.tiles.wallRight
end


function LevelGenerator:makeVertWall(env, x, y, length)
    --print("horiz: x="..x.." y="..y.." length="..length)

    env.tiles[y][x] = self.tiles.wallBot

    local middle = length - 2

    for i=1, middle do
        env.tiles[y - i][x] = self.tiles.wallVert
    end

    env.tiles[y - middle - 1][x] = self.tiles.wallTop
end


function LevelGenerator:makeBoxWall(env, x, y, width, height)
    local right, top = x+width+1, y-height-1
    --local midX, midY = width-2,   height-2

    --print("box: x="..x.." y="..y.." width="..width.." height="..height)

    env.tiles[y][x]       = self.tiles.wallBotLeft
    env.tiles[y][right]   = self.tiles.wallBotRight
    env.tiles[top][x]     = self.tiles.wallTopLeft
    env.tiles[top][right] = self.tiles.wallTopRight

    for i=1, width do
        env.tiles[y][x + i]   = self.tiles.wallHoriz
        env.tiles[top][x + i] = self.tiles.wallHoriz
    end

    for i=1, height do
        env.tiles[y - i][x]     = self.tiles.wallVert
        env.tiles[y - i][right] = self.tiles.wallVert
    end

    for i=1, height do
        for v=1, width do
            env.tiles[y - i][x + v] = self.tiles.noFloor
        end
    end
end


function LevelGenerator:setEnvironmentFloor(env)
    -- Determine any special tiles, or floor patterns or random tiling patterns on plain tiles
    for y=1, env.height do
        for x=1, env.width do
            if env.tiles[y][x] == self.tiles.default then 
                env.tiles[y][x] = self.tiles.plain[random(#self.tiles.plain)]
            end
        end
    end
end


function LevelGenerator:fillEnvironment()
    self.entities = {}

    if #self.environments == 1 then
        self:addEntity({object="weapon", type="shotgun",  xpos=2,  ypos=-5})
        self:addEntity({object="weapon", type="launcher", xpos=18, ypos=-5})
        self:addEntity({object="weapon", type="rifle",    xpos=10, ypos=-5})
        self:addEntity({object="weapon", type="laserGun", xpos=10, ypos=-15})

        self:addEntity({object="obstacle", type="crate", breadth="small", xpos=8, ypos=-8})
        self:addEntity({object="obstacle", type="crate", breadth="small", xpos=9, ypos=-8})
        self:addEntity({object="obstacle", type="crate", breadth="small", xpos=10, ypos=-8})
        self:addEntity({object="obstacle", type="crate", breadth="small", xpos=11, ypos=-8})
        self:addEntity({object="obstacle", type="crate", breadth="small", xpos=12, ypos=-8})

        self:addEntity({object="obstacle", type="crate", breadth="big", xpos=8, ypos=-11})
        self:addEntity({object="obstacle", type="crate", breadth="big", xpos=9, ypos=-11})
        self:addEntity({object="obstacle", type="crate", breadth="big", xpos=10, ypos=-11})
        self:addEntity({object="obstacle", type="crate", breadth="big", xpos=11, ypos=-11})
        self:addEntity({object="obstacle", type="crate", breadth="big", xpos=12, ypos=-11})

        self:addEntity({object="obstacle", type="gas", breadth="small", xpos=6, ypos=-8})
        self:addEntity({object="obstacle", type="gas", breadth="small", xpos=6, ypos=-7})
        self:addEntity({object="obstacle", type="gas", breadth="small", xpos=6, ypos=-6})
        self:addEntity({object="obstacle", type="gas", breadth="small", xpos=6, ypos=-5})
        self:addEntity({object="obstacle", type="gas", breadth="small", xpos=6, ypos=-4})
        self:addEntity({object="obstacle", type="gas", breadth="small", xpos=6, ypos=-3})
        
        self:addEntity({object="obstacle", type="gas", breadth="big", xpos=14, ypos=-8})
        self:addEntity({object="obstacle", type="gas", breadth="big", xpos=14, ypos=-7})
        self:addEntity({object="obstacle", type="gas", breadth="big", xpos=14, ypos=-6})
        self:addEntity({object="obstacle", type="gas", breadth="big", xpos=14, ypos=-5})
        self:addEntity({object="obstacle", type="gas", breadth="big", xpos=14, ypos=-4})
        self:addEntity({object="obstacle", type="gas", breadth="big", xpos=14, ypos=-3})
        
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=5, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=1, xpos=8, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=2, xpos=12, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=3, xpos=15, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=4, xpos=10, ypos=-18})
        
    end

    return self.entities
end


function LevelGenerator:addEntity(spec)
    self.entities[#self.entities+1] = spec
end




return LevelGenerator