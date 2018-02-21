local utils = require("core.utils")


-- The main class: just a loader class
local Loader = {}


-- Aliases:
local random    = math.random
local abs       = math.abs
local min       = math.min
local percent   = utils.percent
local inRange   = utils.randomInRange
local percentOf = utils.percentOf

-- Locals:
local index       = 1
local env         = nil
local envTiles    = nil
local envEntities = nil
local defaultTile = nil

-- entity definitions for own maps
local entityDefs = {
    [361] = {object="enemy",    category="melee",   type=EnemyTypes.lizardClub,     rank=1},
    [362] = {object="enemy",    category="shooter", type=EnemyTypes.lizardRifle,    rank=1},
    [363] = {object="enemy",    category="shooter", type=EnemyTypes.lizardShotgun,  rank=1},
    [364] = {object="enemy",    category="heavy",   type=EnemyTypes.lizardLauncher, rank=1},
    [365] = {object="enemy",    category="heavy",   type=EnemyTypes.lizardLaserGun, rank=1},
    [366] = {object="enemy",    category="melee",   type=EnemyTypes.lizardClub,     rank=2},
    [367] = {object="enemy",    category="shooter", type=EnemyTypes.lizardRifle,    rank=2},
    [368] = {object="enemy",    category="shooter", type=EnemyTypes.lizardShotgun,  rank=2},
    [369] = {object="enemy",    category="heavy",   type=EnemyTypes.lizardLauncher, rank=2},
    [370] = {object="enemy",    category="heavy",   type=EnemyTypes.lizardLaserGun, rank=2},
    [371] = {object="enemy",    category="melee",   type=EnemyTypes.lizardClub,     rank=3},
    [372] = {object="enemy",    category="shooter", type=EnemyTypes.lizardRifle,    rank=3},
    [373] = {object="enemy",    category="shooter", type=EnemyTypes.lizardShotgun,  rank=3},
    [374] = {object="enemy",    category="heavy",   type=EnemyTypes.lizardLauncher, rank=3},
    [375] = {object="enemy",    category="heavy",   type=EnemyTypes.lizardLaserGun, rank=3},

    [391] = {object="weapon",   type=Weapons.rifle.name},
    [392] = {object="weapon",   type=Weapons.shotgun.name},
    [393] = {object="weapon",   type=Weapons.launcher.name},
    [394] = {object="weapon",   type=Weapons.laserGun.name},
    [406] = {object="powerup",  type=Powerups.damage},
    [407] = {object="powerup",  type=Powerups.extraAmmo},
    [408] = {object="powerup",  type=Powerups.fastMove},
    [409] = {object="powerup",  type=Powerups.fastShoot},
    [410] = {object="powerup",  type=Powerups.health, health=5},
    [411] = {object="powerup",  type=Powerups.laserSight},
    [412] = {object="powerup",  type=Powerups.shield},
    [421] = {object="obstacle", type="crate",    variant="small"},
    [422] = {object="obstacle", type="crate",    variant="big"},
    [425] = {object="obstacle", type="gas",      variant="small"},
    [426] = {object="obstacle", type="gas",      variant="big"},
    [429] = {object="obstacle", type="computer", variant="1"},
    [430] = {object="obstacle", type="computer", variant="2"},
    [431] = {object="obstacle", type="computer", variant="3"},
}



local function canPlaceAt(x, y)
    return x > 1 and 
           x < env.width and 
           y > 0 and 
           y <= env.height and 
           envEntities[y][x] == false and 
           envTiles[y][x]    == defaultTile
end


-- width is to the right of x, height is above y
local function canPlace(x, y, width, height)
    if not width and not height then
        return canPlaceAt(x, y)
    end

    if width then
        for w=1, width do
            if not canPlaceAt(x+w-1, y) then
                return false
            end
        end
    end

    if height then
        for h=1, height do
            if not canPlaceAt(x, y-h+1) then
                return false
            end
        end
    end

    return true
end


function Loader:load(LevelGenerator)


    function LevelGenerator:destroyEntities()
        index       = 1
        env         = nil
        envTiles    = nil
        envEntities = nil
        defaultTile = nil
    end


    -- The start logic for placing all entities in a section
    function LevelGenerator:fillEnvironment()
        defaultTile = self.tiles.default
        index       = self.section
        env         = self.environments[index]
        envTiles    = env.tiles
        envEntities = env.entities

        if env.isCustom then
            self:loadEntitiesFromMap()
        elseif not env.isLast then
            self:generateEntities()
        end

        self:updateProgression()
    end


    function LevelGenerator:loadEntitiesFromMap()
        local entityData = env.entityData
        
        for y=1, env.height do
            for x=1, env.width do
                local gridIndex   = ((y-1)*env.height) + x
                local entityIndex = entityData[gridIndex]

                if entityDefs[entityIndex] then
                    self:createEntitySpec(x, y, entityDefs[entityIndex])
                end

                local tile = env.tiles[y][x]

                if tile == self.tiles.entrance then
                    self:createEntitySpec(x, y, {object="obstacle", type="securityDoor", guards="entrance", dontRotate=true, section=self.section})

                elseif tile == self.tiles.exit then
                    self:createEntitySpec(x, y, {object="obstacle", type="securityDoor", guards="exit", dontRotate=true, section=self.section})
                end
            end
        end
    end


    function LevelGenerator:generateEntities()
        -- There are no enemies on the first and last sections
        if index > 1 and not env.isLast then
            if index <= #EnemyLayoutIntro then
                -- ease them into the various enemies in the first set of sections
                self.enemyLayout = EnemyLayouts[EnemyLayoutIntro[index]]
            else
                -- pick a random layout
                self.enemyLayout = EnemyLayouts[random(#EnemyLayouts)]
            end

            self.enemyUnits    = inRange(self.enemyUnitsRange)
            self.enemyCaptains = inRange(self.enemyCaptainRange)
            self.enemyElites   = inRange(self.enemyEliteRange)
            
            self:addEnemies()
        end

        self:addScenery()
        self:addJewels()
    end


    function LevelGenerator:updateProgression()
        -- Increment map height
        self.currentHeight = self.currentHeight + env.height

        -- Increment ranges after every custom section
        if index % (globalLoadSections+1) == 0 then

            if self.enemyUnitsRange[1] < 20 then
                self.enemyUnitsRange[1] = self.enemyUnitsRange[1] + 2
                self.enemyUnitsRange[2] = self.enemyUnitsRange[2] + 4
            end

            if self.enemyCaptainRange[2] < 100 then
                self.enemyCaptainRange[1] = self.enemyCaptainRange[1] + 5
                self.enemyCaptainRange[2] = self.enemyCaptainRange[2] + 10
            end

            if index > (globalLoadSections*2) and self.enemyEliteRange[2] < 100 then
                self.enemyEliteRange[1] = self.enemyEliteRange[1] + 5
                self.enemyEliteRange[2] = self.enemyEliteRange[2] + 10
            end
        end
    end


    -- CORE PLACEMENT

    function LevelGenerator:createEntitySpec(xpos, ypos, otherAttributes)
        local spec = {xpos=xpos, ypos=ypos, mapSection=env.number}

        for name,value in pairs(otherAttributes) do
            spec[name] = value
        end

        self:addEntity(spec)
    end


    function LevelGenerator:addEntity(spec)
        envEntities[spec.ypos][spec.xpos] = true

        if spec.tileWidth then
            for w=1, spec.tileWidth-1 do
                envEntities[spec.ypos][spec.xpos+w] = true
            end
        end

        if spec.tileHeight then
            for y=1, spec.tileHeight-1 do
                envEntities[spec.ypos-y][spec.xpos] = true
            end
        end

        -- Map the ypos for tile coordinates (start top) to the level system (top bottom)
        spec.ypos = (-(env.height - (spec.ypos - 1))) + 0.5 - self.currentHeight
        spec.xpos = spec.xpos - 0.5

        if spec.tileWidth then
            spec.xpos = spec.xpos + 0.5
        end

        if spec.tileHeight then
            spec.ypos = spec.ypos - 0.5
        end

        envEntities[#envEntities+1] = spec
    end


    function LevelGenerator:place(x, y, w, h, n, min)
        if canPlace(x, y, w, h) then
            return x, y
        else
            -- loop through looking for next closest tile to the one we wanted
            for i=(min or 1), (n or 10) do 
                local newx, newy = self:placeAround(x, y, w, h, i)

                if newx ~= nil and newy ~= nil then
                    return newx, newy
                end
            end
        end
        return nil, nil
    end


    function LevelGenerator:placeAround(x, y, w, h, n)
        if      canPlace(x-n, y,   w, h) then return x-n, y
        elseif  canPlace(x+n, y,   w, h) then return x+n, y
        elseif  canPlace(x,   y-n, w, h) then return x,   y-n
        elseif  canPlace(x,   y+n, w, h) then return x,   y+n
        elseif  canPlace(x-n, y-n, w, h) then return x-n, y-n
        elseif  canPlace(x+n, y-n, w, h) then return x+n, y-n
        elseif  canPlace(x-n, y+n, w, h) then return x-n, y+n
        elseif  canPlace(x+n, y+n, w, h) then return x+n, y+n
        else                             return nil, nil
        end
    end


    function LevelGenerator:getRandomPosition()
        return 1 + random(env.width - 2), random(env.height)
    end


    -- ENEMY PLACEMENT


    function LevelGenerator:addEnemies()
        self:addEnemyCategory(EnemyCategories.melee)
        self:addEnemyCategory(EnemyCategories.shooter)
        self:addEnemyCategory(EnemyCategories.heavy)
        self:addEnemyCategory(EnemyCategories.turret)
    end


    function LevelGenerator:addEnemyCategory(category)
        local amount = percentOf(self.enemyUnits, self.enemyLayout[category])

        if amount > 0 then
            self.amountCaptains = percentOf(amount, self.enemyCaptains)
            self.amountElites   = percentOf(amount, self.enemyElites)
            -- TODO: Order them by highest rank first for better placing around higher ranks
            self:addEnemyTypes(category, amount)
        end
    end


    function LevelGenerator:addEnemyTypes(category, amount)
        local types    = #EnemyDefs[category]
        local entities = {}

        -- Setup entities arrays
        for i=1, types do
            entities[i] = {}
        end

        -- Fill entities arrays
        for i=1, amount do
            local type  = random(types)
            local group = entities[type]
            local enemy = {object="enemy", category=category, type=type, rank=1}

            self:upgradeEnemy(enemy, category, type)
            
            group[#group+1] = enemy
        end

        -- Place entities
        for i=1, types do
            if #entities[i] > 0 then
                self:placeEntities(entities[i])
            end
        end
    end


    function LevelGenerator:upgradeEnemy(enemySpec, category, type)
        if self.amountElites > 0 and table.indexOf(EnemyDefs[category][type], EnemyRanks.elite) then
            enemySpec.rank    = EnemyRanks.elite
            self.amountElites = self.amountElites - 1

        elseif self.amountCaptains > 0 and table.indexOf(EnemyDefs[category][type], EnemyRanks.captain) then
            enemySpec.rank      = EnemyRanks.captain
            self.amountCaptains = self.amountCaptains - 1
        end
    end


    function LevelGenerator:addScenery()
        if percent(50) then
            local variantGenerator = function()
                if percent(20) then return "big" else return "small" end
            end
            
            self:generateScenery(15, "crate", variantGenerator)
        end

        if percent(30) then
            local variantGenerator = function()
                if percent(30) then return "big" else return "small" end
            end

            self:generateScenery(10, "gas", variantGenerator)
        end

        if index > 1 and percent(50) then
            local variantGenerator = function()
                local r = random(100)
                if r <= 35 then return "1" elseif r <= 70 then return "2" else return "3" end
            end

            self:generateScenery(8, "computer", variantGenerator, 2)
        end
    end


    function LevelGenerator:generateScenery(maxAmount, type, variantGenerator, tileWidth, tileHeight)
        local amount = random(maxAmount)

        while amount > 0 do
            local batch = random(amount)
            local group = {}

            if amount == 1 then batch = 1 end

            for i=1,batch do
                local spec = {object="obstacle", type=type, variant=variantGenerator()}

                if tileWidth then 
                    spec.tileWidth = tileWidth
                end

                if tileHeight then
                    spec.tileHeight = tileHeight
                end

                group[#group+1] = spec
            end

            self:placeEntities(group, random(3))

            amount = amount - batch
        end
    end


    function LevelGenerator:addJewels()
        local group = {}

        for i=1, random(7) do
            group[#group+1] = {object="jewel", type="jewel-pink", size=1.5}
        end

        self:placeClusterfuck(group)
    end


    function LevelGenerator:placeEntities(group, distance)
        local formation = random(Formations.chain)

        if formation == Formations.clusterFuck then
            -- ClusterFuck: place each one randomly anywhere
            self:placeClusterfuck(group)
        elseif formation == Formations.mob then
            -- Mob: generate a start point and stick everyone around it
            self:placeMob(group, distance or 1)
        elseif formation == Formations.chain then
            -- Squad: same as mob but more spaced out
            self:placeChain(group, distance or 2)
        end
    end


    function LevelGenerator:placeClusterfuck(group)
        local safety = 0

        for _,attribs in pairs(group) do
            local placed = false
            while placed == false do
                local startX, startY = self:getRandomPosition()
                local xpos, ypos     = self:place(startX, startY, attribs.tileWidth, attribs.tileHeight)

                if xpos ~= nil and ypos ~= nil then
                    placed = true
                    self:createEntitySpec(xpos, ypos, attribs)
                end

                safety = safety + 1
                if safety > 1000 then
                    --print("Unable to placeClusterFuck for "..attribs.object)
                    break
                end
            end
        end
    end


    function LevelGenerator:placeMob(group, distance)
        local startX, startY = self:getRandomPosition()
        local safety = 0

        for _,attribs in pairs(group) do
            local placed = false
            while placed == false do
                local xpos, ypos = self:place(startX, startY, attribs.tileWidth, attribs.tileHeight, 20, distance)

                if xpos ~= nil and ypos ~= nil then
                    placed = true
                    self:createEntitySpec(xpos, ypos, attribs)
                end

                safety = safety + 1
                if safety > 1000 then
                    --print("Unable to placeMob for "..attribs.object)
                    break
                end
            end
        end
    end


    function LevelGenerator:placeChain(group, distance)
        local xpos, ypos = self:getRandomPosition()
        local safety = 0

        for _,attribs in pairs(group) do
            local placed = false
            while placed == false do
                xpos, ypos = self:place(xpos, ypos, attribs.tileWidth, attribs.tileHeight, 20, distance)

                if xpos ~= nil and ypos ~= nil then
                    placed = true
                    self:createEntitySpec(xpos, ypos, attribs)
                else
                    -- generate a new x/y otherwise the chain will crash
                    xpos, ypos = self:getRandomPosition()
                end

                safety = safety + 1
                if safety > 1000 then
                    --print("Unable to placeChain for "..attribs.object)
                    break
                end
            end
        end
    end


end


return Loader