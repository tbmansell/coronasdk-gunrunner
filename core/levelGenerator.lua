local spriteSheetInfo = require("core.sheetInfo")


-- Class
local LevelGenerator = {
    MaxWidth        = 25,
    MinWidth        = 8,
    StartWidth      = 20,
    StartHeight     = 24,

    environments    = {},
    tiles           = {},
    section         = 0,
    currentHeight   = 0,

    enemyMaxRank     = 1,
    enemyPoints      = 10,
    enemyWeaponAlloc = nil,
    enemyRankAlloc   = nil,
    enemyFormation   = nil,
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

    self.tiles.shadowRightTop   = spriteSheetInfo:getFrameIndex("shadowRightTop")
    self.tiles.shadowRight      = spriteSheetInfo:getFrameIndex("shadowRight")
    self.tiles.shadowRightBot   = spriteSheetInfo:getFrameIndex("shadowRightBot")
    self.tiles.shadowBotLeft    = spriteSheetInfo:getFrameIndex("shadowBotLeft")
    self.tiles.shadowBot        = spriteSheetInfo:getFrameIndex("shadowBot")

    self.tiles.patternHazzard   = spriteSheetInfo:getFrameIndex("pattern-hazzard")
    self.tiles.patternPipes     = spriteSheetInfo:getFrameIndex("pattern-pipes")
    self.tiles.patternGrill     = spriteSheetInfo:getFrameIndex("pattern-grill")

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


function LevelGenerator:newEnvironment()
    local env = {
        tiles   = {},
        shadows = {}
    }

    self.section = self.section + 1

    self:setEnvironmentWidth(env)
    self:setEnvironmentShape(env)
    self:setEnvironmentEdges(env)

    if self.section > 1 then
        self:setEnvironmentWalls(env)
    end

    self:setEnvironmentFloor(env)

    self.environments[#self.environments + 1] = env

    return env
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
        env.height = self.StartHeight
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
                env.tiles[y]   = {}
                env.shadows[y] = {}

                for x=1, env.width do
                    env.tiles[y][x]   = self.tiles.default
                    env.shadows[y][x] = 0
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
            -- shadow:
            if x==1 then
                if y>2 then env.shadows[y-1][x+1] = self.tiles.shadowRightBot end
                env.shadows[y][x+1] = self.tiles.shadowRight
            end

            for i=1, length do
                env.tiles[y-i][x] = self.tiles.wallVert
                -- shadow:
                if x==1 then env.shadows[y-i][x+1] = self.tiles.shadowRight end
            end

            env.tiles[y-length-1][x] = self.tiles.wallTop
            -- shadow:
            if x==1 then env.shadows[y-length-1][x+1] = self.tiles.shadowRightTop end

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
    -- shadow:
    env.shadows[y+1][x] = self.tiles.shadowBotLeft

    local middle = width - 2

    for i=1, middle do
        env.tiles[y][x + i] = self.tiles.wallHoriz
        -- shadow:
        env.shadows[y+1][x+i] = self.tiles.shadowBot
    end

    env.tiles[y][x + middle + 1] = self.tiles.wallRight
    -- shadows:
    env.shadows[y][x+middle + 2]   = self.tiles.shadowRightTop
    env.shadows[y+1][x+middle + 1] = self.tiles.shadowBot
    env.shadows[y+1][x+middle + 2] = self.tiles.shadowRightBot
end


function LevelGenerator:makeVertWall(env, x, y, length)
    --print("horiz: x="..x.." y="..y.." length="..length)

    env.tiles[y][x] = self.tiles.wallBot
    -- shadow:
    env.shadows[y+1][x+1] = self.tiles.shadowRightBot
    env.shadows[y+1][x]   = self.tiles.shadowBotLeft
    env.shadows[y][x+1]   = self.tiles.shadowRight

    local middle = length - 2

    for i=1, middle do
        env.tiles[y - i][x]   = self.tiles.wallVert
        -- shadow:
        env.shadows[y-i][x+1] = self.tiles.shadowRight
    end

    env.tiles[y - middle - 1][x] = self.tiles.wallTop
    -- shadow:
    env.shadows[y-middle-1][x+1] = self.tiles.shadowRightTop
end


function LevelGenerator:makeBoxWall(env, x, y, width, height)
    local right, top = x+width+1, y-height-1

    --print("box: x="..x.." y="..y.." width="..width.." height="..height)

    env.tiles[y][x]       = self.tiles.wallBotLeft
    env.tiles[y][right]   = self.tiles.wallBotRight
    env.tiles[top][x]     = self.tiles.wallTopLeft
    env.tiles[top][right] = self.tiles.wallTopRight

    -- shadow:
    env.shadows[y+1][x]       = self.tiles.shadowBotLeft
    env.shadows[top][right+1] = self.tiles.shadowRightTop
    env.shadows[y+1][right]   = self.tiles.shadowBot
    env.shadows[y][right+1]   = self.tiles.shadowRight
    env.shadows[y+1][right+1] = self.tiles.shadowRightBot

    for i=1, width do
        env.tiles[y][x + i]   = self.tiles.wallHoriz
        env.tiles[top][x + i] = self.tiles.wallHoriz
        -- shadow:
        env.shadows[y+1][x+i] = self.tiles.shadowBot
    end

    for i=1, height do
        env.tiles[y - i][x]     = self.tiles.wallVert
        env.tiles[y - i][right] = self.tiles.wallVert
        -- shadow:
        env.shadows[y-i][right+1] = self.tiles.shadowRight
    end

    -- fill in center with no floor
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
                --[[if self.section == 1 then
                    env.tiles[y][x] = self.tiles.patternHazzard
                elseif self.section == 2 then
                    env.tiles[y][x] = self.tiles.patternPipes
                elseif self.section == 3 then
                    env.tiles[y][x] = self.tiles.patternGrill 
                end]]

                env.tiles[y][x] = self.tiles.plain[random(#self.tiles.plain)]
            end
        end
    end
end


function LevelGenerator:fillEnvironment()
    local index = self.section
    local env   = self.environments[index]

    self.entities = {}

    -- There are no enemies on the first section
    if index > 1 then
        self:addEnemies(index,  env)
    end

    self:addScenery(index,  env)
    self:addPowerups(index, env)
    self:addPoints(index,   env)

    --[[
    if index == 1 then
        self:addEntity({object="weapon", type="shotgun",  xpos=5,  ypos=-15})
        self:addEntity({object="weapon", type="launcher", xpos=8,  ypos=-15})
        self:addEntity({object="weapon", type="rifle",    xpos=12, ypos=-15})
        self:addEntity({object="weapon", type="laserGun", xpos=15, ypos=-15})
        
    elseif index == 2 then

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
        
        -- hand combat swarm
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=2,  ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=4,  ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=6,  ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=8,  ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=10, ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=12, ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=14, ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=16, ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=18, ypos=-11})
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=20, ypos=-11})
        
    elseif index == 3 then

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


        -- one of each enemy type
        self:addEntity({object="enemy",  type="melee",    rank=1, xpos=5, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=1, xpos=8, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=2, xpos=12, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=3, xpos=15, ypos=-15})
        self:addEntity({object="enemy",  type="shooter",  rank=4, xpos=10, ypos=-18})
    end]]

    self.currentHeight = self.currentHeight + env.height

    return self.entities
end


function LevelGenerator:addEntity(spec)
    spec.ypos = spec.ypos - self.currentHeight

    self.entities[#self.entities+1] = spec
end


function LevelGenerator:addEnemies(index, env)
    
end


function LevelGenerator:addScenery(index, env)
end


function LevelGenerator:addPowerups(index, env)
end


function LevelGenerator:addPoints(index, env)
end















return LevelGenerator