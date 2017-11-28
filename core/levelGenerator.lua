local json                   = require( "json" )
local levelGeneratorEntities = require("core.levelGeneratorEntities")
local utils                  = require("core.utils")


-- Class
local LevelGenerator = {
    MaxWidth         = 24,
    MinWidth         = 8,
    StartWidth       = 13,
    StartXpos        = 6,
    StartHeight      = 24,
    TileSize         = 75,

    environments     = {},
    tiles            = {},
    section          = 0,
    currentHeight    = 0,

    enemyRankLimit   = 1,
    enemyWeaponLimit = 1,
    enemyPoints      = 10,
    enemyPatternSet  = true,
    enemyWeaponAlloc = EnemyWeaponAllocations.meleeOnly,
    enemyRankAlloc   = EnemyRankAllocations.infantry,
}

-- Aliases:
local random  = math.random
local min     = math.min
local max     = math.max
local floor   = math.floor
local percent = utils.percent



function LevelGenerator:setup()
    self.tiles.default          = 2
    self.tiles.noFloor          = 183

    self.tiles.entrance         = 26
    self.tiles.exit             = 11

    self.tiles.wallTop          = 16
    self.tiles.wallBot          = 76
    self.tiles.wallLeft         = 47
    self.tiles.wallRight        = 51
    
    self.tiles.wallHoriz        = 48
    self.tiles.wallHoriz2       = 49
    self.tiles.wallHoriz3       = 50
    self.tiles.wallHoriz4       = 4

    self.tiles.wallVert         = 31
    self.tiles.wallVert2        = 46
    self.tiles.wallVert3        = 61
    self.tiles.wallVert4        = 20
    self.tiles.wallTopLeft      = 3
    self.tiles.wallTopRight     = 5
    self.tiles.wallBotLeft      = 33
    self.tiles.wallBotRight     = 35

    self.tiles.wallBlock        = 188
    self.tiles.wallBlock2       = 189
    self.tiles.wallBlock3       = 190
    self.tiles.wallBlock4       = 191

    self.tiles.edgeTopLeft      = 1
    self.tiles.edgeTopRight     = 15
    self.tiles.edgeBotLeft      = 125
    self.tiles.edgeBotRight     = 126
    self.tiles.edgeBot          = 140
    -- same as edgeBot BUT not marked as edge so we dont add needless physcics shape (for inside box)
    self.tiles.boxEdgeTop       = 140

    self.tiles.shadowRightTop   = 152
    self.tiles.shadowRight      = 167
    self.tiles.shadowRightBot   = 197
    self.tiles.shadowBotLeft    = 168
    self.tiles.shadowBot        = 169

    self.tiles.patternHazzard   = 89
    self.tiles.patternPipes     = 13
    self.tiles.patternGrill     = 11

    self.tiles.paintRedTopLeft  = 52
    self.tiles.paintRedTopRight = 54
    self.tiles.paintRedBotLeft  = 67
    self.tiles.paintRedBotRight = 69
    self.tiles.paintRedHoriz    = 53
    self.tiles.paintRedVert     = 82

    self.tiles.paintBlueTopLeft  = 262
    self.tiles.paintBlueTopRight = 264
    self.tiles.paintBlueBotLeft  = 277
    self.tiles.paintBlueBotRight = 279
    self.tiles.paintBlueHoriz    = 263
    self.tiles.paintBlueVert     = 292

    -- plain tile variations, default:
    self.tiles.defaultVarations = {6, 7, 8, 9, 21, 22, 23, 24, 36, 37, 38, 39}
end


function LevelGenerator:destroy()
    self.environments     = {}
    self.tiles            = {}
    self.section          = 0
    self.currentHeight    = 0
    self.enemyRankLimit   = 1
    self.enemyWeaponLimit = 1
    self.enemyPoints      = 10
    self.enemyWeaponAlloc = EnemyWeaponAllocations.meleeOnly
    self.enemyRankAlloc   = EnemyRankAllocations.infantry

    self:destroyEntities()
end


function LevelGenerator:newEnvironment(isCustom, isLast)
    local env = {
        tiles    = {},
        shadows  = {},
        entities = {},
        isCustom = isCustom,
        isLast   = isLast,
    }

    self.section = self.section + 1

    if isCustom then
        -- Load one of our own pre-built maps
        self:loadCustomMap(env)
    else
        -- Generate a map dynamically
        self:setEnvironmentSize(env)
        self:setEnvironmentTiles(env)
        self:setEnvironmentEdges(env)

        if self.section == 1 then
            self:setStartEdge(env)
        else
            self:setPrevBottomEdge(env, self.environments[#self.environments])

            if not isLast then
                self:setEnvironmentWalls(env)
            end
        end
    end

    self.environments[#self.environments + 1] = env

    return env
end


function LevelGenerator:getSection(index)
    return self.environments[index]
end


-- Gets current section based on ypos, but as sections are generated from top down, we flip this, so we call the bottom section #1
function LevelGenerator:getSectionAtPosition(ypos)
    local sections = #self.environments
    
    for i=sections, 1, -1 do
        local env = self.environments[i]
        local top = env.height * self.TileSize * (env.number-1)

        if ypos > top then
            return self.environments[sections - i + 1]
        end
    end
end


function LevelGenerator:assignEntityRef(referenceName, entity)
    self.environments[entity.section][referenceName] = entity
end


----- LOADING EXTERNAL MAP -----


function LevelGenerator:loadCustomMap(env)
    local file     = "json/maps/testmap1.json"
    local filepath = system.pathForFile(file, system.ResourceDirectory)
    local map, pos, msg = json.decodeFile(filepath)

    if not map then
        print("JSON Load failed for ["..file.."] at "..tostring(pos)..": "..tostring(msg))
    end

    env.isCustom = true
    env.width  = map.width
    env.height = map.height
    env.dir    = "straight"
    env.number = #self.environments + 1

    local floorLayer = map.layers[1].data

    env.entityData = map.layers[2].data

    for y=1, env.height do
        env.tiles[y]    = {}
        env.shadows[y]  = {}
        env.entities[y] = {}

        for x=1, env.width do
            local index = ((y-1)*env.height) + x

            env.tiles[y][x]    = floorLayer[index]
            env.shadows[y][x]  = 0
            env.entities[y][x] = false
        end
    end
end


----- GENERATING A MAP DYNAMICALLY -----


function LevelGenerator:setEnvironmentSize(env)
    local number = #self.environments

    -- First determine if there is a previous environment, if so we must start at that width:
    if number > 0 then
        local prev = self.environments[number]
        env.height = self.StartHeight
        env.number = number + 1

        -- make width variable: 24, 20, 16, 12
        local  r = random(100)
        if     r <= 25  then env.width = self.MaxWidth
        elseif r <= 50  then env.width = self.MaxWidth - 4
        elseif r <= 75  then env.width = self.MaxWidth - 8
        elseif r <= 100 then env.width = self.MaxWidth - 12 end

        if env.width < self.MaxWidth then
            env.startX = random(self.MaxWidth - env.width)
            -- make sure at least 3 tiles conncet the sections
            if env.startX > prev.width - 3 then
                env.startX = prev.width - 3
            end
        else
            env.startX = 1
        end
    else
        -- This is the first section
        env.width  = self.StartWidth
        env.height = self.StartHeight
        env.startX = self.StartXpos
        env.number = 1
    end
end


function LevelGenerator:setEnvironmentTiles(env)
    for y=1, env.height do
        env.tiles[y]    = {}
        env.shadows[y]  = {}
        env.entities[y] = {}

        -- load ALL tiles up to max width with the empty one and all those within 
        for x=1, self.MaxWidth do
            env.shadows[y][x]  = 0
            env.entities[y][x] = false

            if x < env.startX or x >= env.startX + env.width then
                env.tiles[y][x] = self.tiles.noFloor
            else
                env.tiles[y][x] = self.tiles.default
            end
        end
    end
end


function LevelGenerator:setEnvironmentEdges(env)
    self:setStraightEdge(env, env.startX, env.height, true)
    self:setStraightEdge(env, env.startX + env.width - 1, env.height)
end


function LevelGenerator:setStraightEdge(env, x, y, shadow)
    while y > 1 do
        -- 75% chance of wall each time
        if y > 3 and percent(75) then
            -- Determine wall length: 3 max: height left
            local length = random(y-2)

            env.tiles[y][x] = self.tiles.wallBot
            -- shadow:
            if shadow then
                if y>2 then env.shadows[y-1][x+1] = self.tiles.shadowRightBot end
                env.shadows[y][x+1] = self.tiles.shadowRight
            end

            for i=1, length do
                env.tiles[y-i][x] = self.tiles.wallVert
                -- shadow:
                if shadow then env.shadows[y-i][x+1] = self.tiles.shadowRight end
            end

            env.tiles[y-length-1][x] = self.tiles.wallTop
            -- shadow:
            if shadow then env.shadows[y-length-1][x+1] = self.tiles.shadowRightTop end

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


function LevelGenerator:setStartEdge(env)
    local y      = env.height
    local startX = env.startX + 1
    local endX   = env.startX + env.width - 2

    env.tiles[y][startX] = self.tiles.wallLeft
    env.tiles[y][endX]   = self.tiles.wallRight

    for x=startX+1, endX-1 do 
        env.tiles[y][x] = self.tiles.wallHoriz
    end
end


function LevelGenerator:setPrevBottomEdge(env, prev)
    for x=1, self.MaxWidth do
        if prev.tiles[1][x] == self.tiles.noFloor and env.tiles[env.height][x] ~= self.tiles.noFloor then
            prev.tiles[1][x] = self.tiles.edgeBot
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
        local pattern = "horizontal"
        --local pattern = "snake"
        
        if spaceY >= 10 then
            local  r = random(100)
            if     r <= 33 then pattern = "horizontal"
            elseif r <= 66 then pattern = "vertical"
            else                pattern = "box" end
        end

        if     pattern == "vertical"   then spaceY = spaceY - self:makeStripVertWalls(env, spaceY)
        elseif pattern == "horizontal" then spaceY = spaceY - self:makeStripHorizWalls(env, spaceY)
        elseif pattern == "box"        then spaceY = spaceY - self:makeStripBoxWalls(env, spaceY)
        elseif pattern == "snake"      then spaceY = spaceY - self:makeSnakeWall(env, spaceY)
        end
    end
end


function LevelGenerator:makeStripVertWalls(env, y)
    local spaceX    = env.width - 6
    local spaceY    = 2 + random(7)
    local start     = env.startX + 2
    local spaceWall = 3
    local maxWalls  = floor(spaceX / spaceWall)
    local walls     = random(maxWalls)

    if maxWalls == 1 then walls = 1 end

    if walls == 1 then
        self:makeVertWall(env, start+random(spaceX-1), y, spaceY)

    elseif walls == 2 then
        local half = spaceX / 2
        self:makeVertWall(env, start+random(half-1),      y, spaceY)
        self:makeVertWall(env, start+half+random(half-1), y, spaceY)
    else
        local distance = floor(spaceX / walls)

        for i=1, walls do
            self:makeVertWall(env, start+(distance*i), y, 2+random(spaceY-2))
        end
    end

    return spaceY + 2
end


function LevelGenerator:makeStripHorizWalls(env, y)
    local spaceX    = env.width - 6
    local spaceY    = 2 + random(7)
    local start     = env.startX + 2
    local spaceWall = 5
    local maxWalls  = floor(spaceX / spaceWall)
    local walls     = random(maxWalls)

    if maxWalls == 1 then walls = 1 end

    if walls == 1 then
        local width = 2 + random(spaceX-4)
        self:makeHorizWall(env, start+random(spaceX - width), y, width, false)

    elseif walls == 2 then
        local half = spaceX/2
        local width1 = 1 + random(half-2)
        local width2 = 1 + random(half-2)

        self:makeHorizWall(env, start+random(half-width1),        y, width1, false)
        self:makeHorizWall(env, 1+start+half+random(half-width2), y, width2, false)

    elseif walls == 3 then
        local third  = spaceX/3
        local width1 = 1 + random(third-2)
        local width2 = 1 + random(third-2)
        local width3 = 1 + random(third-2)

        self:makeHorizWall(env, start+random(third-width1),               y, width1, percent(50))
        self:makeHorizWall(env, 1+start+third+random(third-width2),       y, width2, percent(50))
        self:makeHorizWall(env, 1+start+third+third+random(third-width3), y, width3, percent(50))
    end

    return 6
end


function LevelGenerator:makeStripBoxWalls(env, y)
    local spaceX    = env.width - 6
    local spaceY    = 2 + random(7)
    local start     = env.startX + 1
    local spaceWall = 5
    local maxWalls  = floor(spaceX / spaceWall)
    local walls     = random(maxWalls)

    if maxWalls == 1 then walls = 1 end 
    
    if walls == 1 then
        local width = 2 + random(spaceX-4)
        self:makeBoxWall(env, start+random(spaceX - width), y, width, random(5))

    else
        local half   = spaceX/2
        local width1 = random(max(3, half-3))
        local width2 = random(max(3, half-3))

        self:makeBoxWall(env, start+half-(width1)-1,      y, width1, random(5))
        self:makeBoxWall(env, start+half+half-(width2), y, width2, random(5))
    end

    return 12
end


function LevelGenerator:makeHorizWall(env, x, y, width, randY)
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
            local tile = self.tiles.noFloor

            if i == height then tile = self.tiles.boxEdgeTop end

            env.tiles[y - i][x + v] = tile
        end
    end
end


function LevelGenerator:makeSnakeWall(env, y)
    local spaceX  = env.width  - 6
    local start   = env.startX + 2
    local spaceY  = y - 6
    local curY    = y
    local curX    = start + random(spaceX)
    --local length  = 0
    local prevDir = nil
    local accept  = false

    for i=1, 10 do
        local dir = nil

        accept = false
        while not accept do
            local  r = random(100)
            if     r <= 25 then dir  = "up"
            elseif r <= 50 then dir  = "left"
            elseif r <= 75 then dir  = "right"
            else   dir = "down" end

            if curY > y or curY < spaceY or curX < 1 or curX > spaceX then
                accept = false
            else
                accept = true
            end
        end

        if     dir == "up"    then curY = curY - 1
        elseif dir == "left"  then curX = curX - 1
        elseif dir == "right" then curX = curX + 1
        elseif dir == "down"  then curY = curY + 1 end

        env.tiles[curY][start + curX] = self.tiles.wallBlock
    end

    return 6
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

                -- NOTE: this has to run after entities have been placed so we can detect normal tiles
                env.tiles[y][x] = self.tiles.defaultVarations[random(#self.tiles.defaultVarations)]
            end
        end
    end

    -- differentiate each section
    for x=1, env.width-2 do
        env.tiles[1][env.startX + x] = self.tiles.patternHazzard
    end

    -- Customise specific sections
    if env.number == 1 then
        self:setEnvironmentFirstSection(env)

    elseif env.isLast then
        self:setEnvironmentLastSection(env)
    end
end


function LevelGenerator:setEnvironmentFirstSection(env)
    -- inner ring
    env.tiles[18][11] = self.tiles.paintRedTopLeft
    env.tiles[18][12] = self.tiles.paintRedHoriz
    env.tiles[18][13] = self.tiles.paintRedTopRight
    env.tiles[19][11] = self.tiles.paintRedVert
    env.tiles[19][13] = self.tiles.paintRedVert
    env.tiles[20][11] = self.tiles.paintRedBotLeft
    env.tiles[20][12] = self.tiles.paintRedHoriz
    env.tiles[20][13] = self.tiles.paintRedBotRight

    -- outer ring
    env.tiles[16][9]  = self.tiles.paintBlueTopLeft
    for i=10,14 do 
        env.tiles[16][i] = self.tiles.paintBlueHoriz
    end
    env.tiles[16][15] = self.tiles.paintBlueTopRight

    for i=17, 21 do
        env.tiles[i][9]  = self.tiles.paintBlueVert
        env.tiles[i][15] = self.tiles.paintBlueVert
    end

    env.tiles[22][9]  = self.tiles.paintBlueBotLeft
    for i=10,14 do 
        env.tiles[22][i] = self.tiles.paintBlueHoriz
    end
    env.tiles[22][15] = self.tiles.paintBlueBotRight
end


function LevelGenerator:setEnvironmentLastSection(env)
    self:setEnvironmentFirstSection(env)
end




-- Load in from another file
levelGeneratorEntities:load(LevelGenerator)



return LevelGenerator