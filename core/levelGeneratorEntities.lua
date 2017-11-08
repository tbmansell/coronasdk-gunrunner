local utils = require("core.utils")


-- The main class: just a loader class
local Loader = {}


-- Aliases:
local random  = math.random
local abs     = math.abs
local min     = math.min
local percent = utils.percent

-- Locals:
local index       = 1
local env         = nil
local envTiles    = nil
local envEntities = nil
local defaultTile = nil
local melees      = nil
local shooters    = nil
local reptiles    = nil
local turrets     = nil
local points      = nil

-- entity definitions for own maps
local entityDefs = {
    [361] = {object="enemy",    type="melee",   rank=1},
    [362] = {object="enemy",    type="shooter", rank=1},
    [363] = {object="enemy",    type="shooter", rank=2},
    [364] = {object="enemy",    type="shooter", rank=3},
    [365] = {object="enemy",    type="shooter", rank=4},
    [366] = {object="enemy",    type="melee",   rank=2},
    [367] = {object="enemy",    type="shooter", rank=5},
    [368] = {object="enemy",    type="shooter", rank=6},
    [369] = {object="enemy",    type="shooter", rank=7},
    [370] = {object="enemy",    type="shooter", rank=8},
    [371] = {object="enemy",    type="melee",   rank=3},
    [372] = {object="enemy",    type="shooter", rank=9},
    [373] = {object="enemy",    type="shooter", rank=10},
    [374] = {object="enemy",    type="shooter", rank=11},
    [375] = {object="enemy",    type="shooter", rank=12},
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
        melees      = nil
        shooters    = nil
        points      = nil
    end


    -- The start logic for placing al entities in a section
    function LevelGenerator:fillEnvironment()
        self.entities = {}

        defaultTile = self.tiles.default
        index       = self.section
        env         = self.environments[index]
        envTiles    = env.tiles
        envEntities = env.entities

        --print("Section "..index.." enemyPoints="..self.enemyPoints.." weaponLimit="..self.enemyWeaponLimit.." rankLimit="..self.enemyRankLimit.." weaponAlloc="..self.enemyWeaponAlloc.." rankAlloc="..self.enemyRankAlloc)

        if env.ownMap then
            self:loadEntitiesFromMap()
        else
            self:generateEntities()
        end

        self:updateProgression()

        return self.entities
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
            end
        end
    end


    function LevelGenerator:generateEntities()
        -- There are no enemies on the first section
        if index > 1 then
            -- define early presets here:
            if index == 2 then
                self.enemyWeaponAlloc = EnemyWeaponAllocations.meleeOnly
                self.enemyRankAlloc   = EnemyRankAllocations.infantry
            else
                self.enemyWeaponAlloc = random(self.enemyWeaponLimit)
                self.enemyRankAlloc   = random(self.enemyRankLimit)
            end

            --print("Section "..index.." enemyPoints="..self.enemyPoints.." weaponLimit="..self.enemyWeaponLimit.." rankLimit="..self.enemyRankLimit.." weaponAlloc="..self.enemyWeaponAlloc.." rankAlloc="..self.enemyRankAlloc)
            
            self:addEnemies()
        end

        self:addScenery()
        self:addJewels()
    end


    function LevelGenerator:updateProgression()
        -- Increment map height
        self.currentHeight = self.currentHeight + env.height

        --print("Section "..index.." height="..self.currentHeight.." heightPixels="..(self.currentHeight*self.TileSize))

        -- Increment the weapons that can appear by one each section
        if index > 1 and self.enemyWeaponLimit < EnemyWeaponAllocations.all then
            self.enemyWeaponLimit = self.enemyWeaponLimit + 1
            --print("+ WeaponLimit now "..self.enemyWeaponLimit)
        end

        -- Increment the enemy ranks that can appear by 2 every 4 sections
        if index % 4 == 0 and self.enemyRankLimit < EnemyRankAllocations.all  then
            self.enemyRankLimit = self.enemyRankLimit + 2
            --print("+ RankLimit now "..self.enemyRankLimit)
        end

        -- Increment the enemy points up or down between 20 - 50
        if self.enemyPoints < 20  then
            -- up the points evey 4 sections
            if index % 4 == 0 then
                self.enemyPoints = self.enemyPoints + 5
            end
        elseif self.enemyPoints >= 50 then
            self.enemyPoints = self.enemyPoints - 5
        else
            if random(50) then
                self.enemyPoints = self.enemyPoints + 5
            else
                self.enemyPoints = self.enemyPoints - 5
            end
        end
    end


    -- CORE PLACEMENT


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
            spec.ypos = spec.ypos + 0.5
        end

        self.entities[#self.entities+1] = spec
    end


    function LevelGenerator:createEntitySpec(xpos, ypos, otherAttributes)
        local spec = {xpos=xpos, ypos=ypos}

        for name,value in pairs(otherAttributes) do
            spec[name] = value
        end

        self:addEntity(spec)
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
        -- we must generate the enemies and then place them
        melees   = {}
        shooters = {}
        reptiles = {}
        turrets  = {}
        points   = self.enemyPoints

        self:generateEnemies()
        -- TODO: Order them by highest rank first for better placing around higher ranks
        self:placeEntities(turrets)
        self:placeEntities(melees)
        self:placeEntities(shooters)
        self:placeEntities(reptiles)
    end


    function LevelGenerator:generateEnemies()
        local alloc = self.enemyWeaponAlloc

        -- Generate the enemies weapons and ranks
        if alloc == EnemyWeaponAllocations.meleeOnly then
            self:generateMeleeEnemies()
            self:generateReptiles()

        elseif alloc == EnemyWeaponAllocations.riflesOnly or alloc == EnemyWeaponAllocations.heavyOnly then
            self:generateShooterEnemies()
            self:generateTurrets()
        else
            local r = random(100)
            if r <= 50 then
                self:generateShooterEnemies(points / 2)
                self:generateMeleeEnemies()

            elseif r <= 75 then
                self:generateMeleeEnemies()
                self:generateTurrets()
            else
                self:generateShooterEnemies()
                self:generateReptiles()
            end
        end
    end


    function LevelGenerator:generateMeleeEnemies(pointsToSpend)
        local spendTo = points - (pointsToSpend or points)
        local alloc   = self.enemyWeaponAlloc

        while points > 0 and points > spendTo do
            local rank = 1

            if self.enemyRankAlloc > 1 then
                local limit = min(self.enemyRankAlloc, 3)
                rank = random(limit)
            end

            points = points - rank
            melees[#melees+1] = {object="enemy", type="melee", rank=rank}
        end
    end


    function LevelGenerator:generateShooterEnemies(pointsToSpend)
        local spendTo = points - (pointsToSpend or points)
        
        while points > 0 and points > spendTo do
            local rank = 1

            -- Modify rank by the weapon choice
            rank = rank + self:generateShooterWeapon()
            -- Modify rank by the Rank allocation
            rank = rank + self:generateShooterLeader()

            -- after all that, if we dont have enough points left for the rank generated, cut the rank down to what is left
            if rank > points then rank = points end

            points = points - rank
            shooters[#shooters+1] = {object="enemy", type="shooter", rank=rank}
        end
    end


    function LevelGenerator:generateReptiles(pointsToSpend)
        if percent(50) then
            local r = random(100)
            
            if r <= 50 then
                for i=1, random(10) do
                    reptiles[#reptiles+1] = {object="enemy", type="reptile", rank=1, tileWidth=1, tileHeight=1}
                end
            elseif r <= 75 then
                reptiles[#reptiles+1] = {object="enemy", type="reptile", rank=2, tileWidth=1, tileHeight=1}
            else
                for i=1, random(5) do
                    reptiles[#reptiles+1] = {object="enemy", type="reptile", rank=1, tileWidth=1, tileHeight=1}
                end

                reptiles[#reptiles+1] = {object="enemy", type="reptile", rank=2, tileWidth=1, tileHeight=1}
            end
        end
    end


    function LevelGenerator:generateTurrets(pointsToSpend)
        local num = 0
        local r   = random(100)
        
        if     r <= 40 then num = 1
        elseif r <= 50 then num = 2 end

        for i=1, num do 
            turrets[#turrets+1] = {object="enemy", type="turret", rank=1, tileWidth=2, tileHeight=2}
        end
    end


    function LevelGenerator:generateShooterWeapon()
        local weapon = self.enemyWeaponAlloc
        local rank   = 0

        if weapon == EnemyWeaponAllocations.riflesOnly or weapon == EnemyWeaponAllocations.meleeAndRifles then
            -- if rifles only, 30% chance of having a shotgun (one higher rank)
            if percent(30) then rank = rank + 1 end
        elseif weapon == EnemyWeaponAllocations.heavyOnly or weapon == EnemyWeaponAllocations.meleeAndHeavy then
            -- if heavy only, add 2 rank for min launcher and 30% of having a laser
            rank = rank + 2
            if percent(30) then rank = rank + 1 end
        elseif weapon == EnemyWeaponAllocations.all then
            -- if all, 25% chance of each
            local  r = random(100)
            if     r > 25 and r <= 50 then rank = rank + 1     -- shotgun
            elseif r > 50 and r <= 50 then rank = rank + 2     -- launcher
            elseif r > 75             then rank = rank + 3 end -- laser
        end
        return rank
    end


    function LevelGenerator:generateShooterLeader()
        local alloc = self.enemyRankAlloc
        local rank  = 0

        if alloc == EnemyRankAllocations.captain then
            rank = rank + 4
        elseif alloc == EnemyRankAllocations.elite then
            rank = rank + 8
        elseif alloc == EnemyRankAllocations.infantryWithCaptain then
            -- 30% chance of captain
            if percent(30) then rank = rank + 4 end
        elseif alloc == EnemyRankAllocations.infantryWithElite then
            -- 30% chance elite 
            if percent(30) then rank = rank + 8 end
        elseif alloc == EnemyRankAllocations.captainWithElite then
            -- 30% chance of elite
            if percent(30) then 
                rank = rank + 8
            else
                rank = rank + 4
            end
        elseif alloc == EnemyRankAllocations.all then
            -- 30% chance of captain or elite
            local r = random(100)
            if     r > 40 and r <= 70 then rank = rank + 4
            elseif r > 70 then rank = rank + 8 end
        end
        return rank
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
        local formation = random(EntityFormations.chain)

        if formation == EntityFormations.clusterFuck then
            -- ClusterFuck: place each one randomly anywhere
            self:placeClusterfuck(group)
        elseif formation == EntityFormations.mob then
            -- Mob: generate a start point and stick everyone around it
            self:placeMob(group, distance or 1)
        elseif formation == EntityFormations.chain then
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
                    print("Unable to placeClusterFuck for "..attribs.object)
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
                    print("Unable to placeMob for "..attribs.object)
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
                    print("Unable to placeChain for "..attribs.object)
                    break
                end
            end
        end
    end


end


return Loader