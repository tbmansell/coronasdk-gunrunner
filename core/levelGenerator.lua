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

    enemyUnitsRange   = {10, 10},
    enemyCaptainRange = {0,  0},
    enemyEliteRange   = {0,  0},
    enemyLayout       = nil,
}

-- Paint colors:
local red   = 1
local blue  = 2
-- Patterns
local grill       = 1
local transparent = 3
local broken      = 6
local hazzard     = 7
local bars        = 8

-- Aliases:
local random  = math.random
local min     = math.min
local max     = math.max
local floor   = math.floor
local percent = utils.percent



function LevelGenerator:setup()
    -- global default tiles:
    self.tiles.default          = 2
    -- global no floor with physics shape for hole
    self.tiles.noFloor          = 183
    -- global no floor for inside boxes where we dont need a physics shape
    self.tiles.noFloorInside    = 184
    

    -- special tiles for custom map entrance and exit doors:
    self.tiles.entrance         = 26
    self.tiles.exit             = 11
    
    -- shadows:
    self.tiles.shadowRightTop   = 152
    self.tiles.shadowRight      = 167
    self.tiles.shadowRightBot   = 197
    self.tiles.shadowBotLeft    = 168
    self.tiles.shadowBot        = 169

    -- standard floor edge with physics shape
    self.tiles.edgeBot          = 140
    -- floor edge for inside box with no physics shape
    self.tiles.edgeBotInside    = 141


    -- simple straight-only walls
    self.tiles.walls = {
        simple = {
            horiz = {
                [1] = {158, 159, 160, 161},
                [2] = {173, 174, 175, 176},
                [3] = {188, 189, 190, 191},
                [4] = {203, 204, 205, 206},
            },
            vert = {
                [1] = {165, 180, 195, 210},
                [2] = {164, 179, 194, 209},
                [3] = {163, 178, 193, 208},
                [4] = {162, 177, 192, 207},
            }
        },
        complex = {

        }
    }


    self.tiles.wallTop          = 1
    self.tiles.wallBot          = 61
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


    self.tiles.paint = {
        [red] = {
            topLeft  = 52,
            topRight = 54,
            botLeft  = 67,
            botRight = 69,
            horiz    = 53,
            vert     = 82,
        },
        [blue] = {
            topLeft  = 262,
            topRight = 264,
            botLeft  = 277,
            botRight = 279,
            horiz    = 263,
            vert     = 292,
        }
    }


    -- patterned tiles:
    self.tiles.patterns = {
        [1] = {
            [grill]       = {12,  13,  14,  15},
            [2]           = {27,  28,  29,  30},
            [transparent] = {42,  43,  44,  45},
            [4]           = {57,  58,  59,  60},
            [5]           = {72,  73,  74,  75},
            [broken]      = {87,  88,  89,  90},
            [hazzard]     = {102, 103, 104, 105},
            [bars]        = {117, 118, 119, 120},
            [9]           = {132, 133, 134, 135},
        },
        [2] = {
            [grill]       = {222, 223, 224, 225},
            [2]           = {237, 238, 239, 240},
            [transparent] = {252, 253, 254, 255},
            [4]           = {267, 268, 269, 270},
            [5]           = {282, 283, 284, 285},
            [broken]      = {297, 298, 299, 300},
            [hazzard]     = {312, 313, 314, 315},
            [bars]        = {327, 328, 329, 330},
            [9]           = {342, 343, 344, 345},
        }
    }

    -- plain tile variations:
    self.tiles.defaultVariations = {
        [1] = {7,   8,   9,   22,  23,  24,  37,  38,  39},
        [2] = {97,  98,  99,  112, 113, 114, 127, 128, 129},
        [3] = {217, 218, 219, 232, 233, 234, 247, 248, 249},
        [4] = {307, 308, 309, 322, 323, 324, 337, 338, 339}
    }
end


function LevelGenerator:destroy()
    self.environments     = {}
    self.tiles            = {}
    self.section          = 0
    self.currentHeight    = 0
    -- ranges
    self.enemyUnitsRange   = {8, 12}
    self.enemyCaptainRange = {0,  0}
    self.enemyEliteRange   = {0,  0}
    -- values picked
    self.enemyLayout       = nil
    self.enemyUnits        = 0
    self.enemyCaptains     = 0
    self.enemyElites       = 0

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
            local tile = self.tiles.noFloorInside

            if i == height then tile = self.tiles.edgeBotInside end

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
    local defaults    = self.tiles.defaultVariations[1]
    local numDefaults = #defaults

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
                env.tiles[y][x] = defaults[random(numDefaults)]
            end
        end
    end

    local hazzards    = self.tiles.patterns[2][hazzard]
    local numHazzards = #hazzards

    -- differentiate each section
    for x=1, env.width-2 do
        env.tiles[1][env.startX + x] = hazzards[random(numHazzards)]
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
    env.tiles[18][11] = self.tiles.paint[red].topLeft
    env.tiles[18][12] = self.tiles.paint[red].horiz
    env.tiles[18][13] = self.tiles.paint[red].topRight
    env.tiles[19][11] = self.tiles.paint[red].vert
    env.tiles[19][13] = self.tiles.paint[red].vert
    env.tiles[20][11] = self.tiles.paint[red].botLeft
    env.tiles[20][12] = self.tiles.paint[red].horiz
    env.tiles[20][13] = self.tiles.paint[red].botRight

    -- outer ring
    env.tiles[16][9]  = self.tiles.paint[blue].topLeft
    for i=10,14 do 
        env.tiles[16][i] = self.tiles.paint[blue].horiz
    end
    env.tiles[16][15] = self.tiles.paint[blue].topRight

    for i=17, 21 do
        env.tiles[i][9]  = self.tiles.paint[blue].vert
        env.tiles[i][15] = self.tiles.paint[blue].vert
    end

    env.tiles[22][9]  = self.tiles.paint[blue].botLeft
    for i=10,14 do 
        env.tiles[22][i] = self.tiles.paint[blue].horiz
    end
    env.tiles[22][15] = self.tiles.paint[blue].botRight
end


function LevelGenerator:setEnvironmentLastSection(env)
    self:setEnvironmentFirstSection(env)
end



-- Load in from another file
levelGeneratorEntities:load(LevelGenerator)



return LevelGenerator