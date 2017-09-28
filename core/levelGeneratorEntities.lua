-- The main class: just a loader class
local Loader = {}


-- Aliases:
local random = math.random
local abs    = math.abs
local min    = math.min

-- Locals:
local index       = 1
local env         = nil
local envTiles    = nil
local envEntities = nil
local defaultTile = nil
local melees      = nil
local shooters    = nil
local points      = nil


local function percent(chance)
    return random(100) < chance
end


local function canPlace(x, y)
    return x > 1 and 
           x < env.width and 
           y > 0 and 
           y <= env.height and 
           envEntities[y][x] == false and 
           envTiles[y][x]    == defaultTile
end


function Loader:load(LevelGenerator)

    -- The start logic for placing al entities in a section
    function LevelGenerator:fillEnvironment()
        self.entities = {}

        defaultTile = self.tiles.default
        index       = self.section
        env         = self.environments[index]
        envTiles    = env.tiles
        envEntities = env.entities

        --print("Section "..index.." enemyPoints="..self.enemyPoints.." weaponLimit="..self.enemyWeaponLimit.." rankLimit="..self.enemyRankLimit.." weaponAlloc="..self.enemyWeaponAlloc.." rankAlloc="..self.enemyRankAlloc)

        -- There are no enemies on the first section
        if index > 1 then
        --if index > 0 then
            -- define early presets here:
            if index == 2 then
            --if index == 1 then
                self.enemyWeaponAlloc = EnemyWeaponAllocations.meleeOnly
                self.enemyRankAlloc   = EnemyRankAllocations.infantry
                --self:addEnemies()
            else
                self.enemyWeaponAlloc = random(self.enemyWeaponLimit)
                self.enemyRankAlloc   = random(self.enemyRankLimit)
            end

            print("Section "..index.." enemyPoints="..self.enemyPoints.." weaponLimit="..self.enemyWeaponLimit.." rankLimit="..self.enemyRankLimit.." weaponAlloc="..self.enemyWeaponAlloc.." rankAlloc="..self.enemyRankAlloc)
            
            self:addEnemies()
        end

        self:addScenery()
        self:addPowerups()
        self:addPoints()

        -- Increment map height
        self.currentHeight = self.currentHeight + env.height

        -- Increment the weapons that can appear by one each section
        if index > 1 and self.enemyWeaponLimit < EnemyWeaponAllocations.all then
            self.enemyWeaponLimit = self.enemyWeaponLimit + 1
            print("+ WeaponLimit now "..self.enemyWeaponLimit)
        end

        -- Increment the enemy ranks that can appear by 2 every 4 sections
        if index % 4 == 0 and self.enemyRankLimit < EnemyRankAllocations.all  then
            self.enemyRankLimit = self.enemyRankLimit + 2
            print("+ RankLimit now "..self.enemyRankLimit)
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

        return self.entities
    end


    -- CORE PLACEMENT


    function LevelGenerator:addEntity(spec)
        envEntities[spec.ypos][spec.xpos] = true

        -- Map the ypos for tile coordinates (start top) to the level system (top bottom)
        spec.ypos = (-(env.height - (spec.ypos - 1))) + 0.5 - self.currentHeight
        spec.xpos = spec.xpos - 0.5

        self.entities[#self.entities+1] = spec
    end


    function LevelGenerator:createEntitySpec(xpos, ypos, otherAttributes)
        local spec = {xpos=xpos, ypos=ypos}

        for name,value in pairs(otherAttributes) do
            spec[name] = value
        end

        self:addEntity(spec)
    end


    function LevelGenerator:place(x, y, n, min)
        if canPlace(x, y) then
            return x, y
        else
            -- loop through looking for next closest tile to the one we wanted
            for i=(min or 1), (n or 10) do 
                local newx, newy = self:placeAround(x, y, i)

                if newx ~= nil and newy ~= nil then
                    return newx, newy
                end
            end
        end
        return nil, nil
    end


    function LevelGenerator:placeUp(x, y, n)
        return self:place(x, y - (n or 1))
    end

    function LevelGenerator:placeDown(x, y, n)
        return self:place(x, y + (n or 1))
    end

    function LevelGenerator:placeLeft(x, y, n)
        return self:place(x - (n or 1), y)
    end

    function LevelGenerator:placeRight(x, y, n)
        return self:place(x + (n or 1), y)
    end


    function LevelGenerator:placeAround(x, y, n)
        if      canPlace(x-n, y)   then return x-n, y
        elseif  canPlace(x+n, y)   then return x+n, y
        elseif  canPlace(x,   y-n) then return x,   y-n
        elseif  canPlace(x,   y+n) then return x,   y+n
        elseif  canPlace(x-n, y-n) then return x-n, y-n
        elseif  canPlace(x+n, y-n) then return x+n, y-n
        elseif  canPlace(x-n, y+n) then return x-n, y+n
        elseif  canPlace(x+n, y+n) then return x+n, y+n
        else                            return nil, nil
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
        points   = self.enemyPoints

        self:generateEnemies()
        -- TODO: Order them by highest rank first for better placing around higher ranks
        self:placeEntities(melees)
        self:placeEntities(shooters)
    end


    function LevelGenerator:generateEnemies()
        local alloc = self.enemyWeaponAlloc

        -- Generate the enemies weapons and ranks
        if alloc == EnemyWeaponAllocations.meleeOnly then
            self:generateMeleeEnemies()
        elseif alloc == EnemyWeaponAllocations.riflesOnly or alloc == EnemyWeaponAllocations.heavyOnly then
            self:generateShooterEnemies()
        else
            -- 50% chance of both, 25% chance of either
            local r = random(100)
            if r > 0 and r <= 50 then
                self:generateMeleeEnemies(points / 2)
                self:generateShooterEnemies()
            elseif r > 50 and r <= 75 then
                self:generateMeleeEnemies()
            else
                self:generateShooterEnemies()
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
            local r = random(100)
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
                if percent(30) then return "big" else return "small" end
            end
            
            self:generateScenery(15, "crate", variantGenerator)
        end

        if percent(30) then
            local variantGenerator = function()
                if percent(30) then return "big" else return "small" end
            end

            self:generateScenery(10, "gas", variantGenerator)
        end

        if percent(100) then
            local variantGenerator = function()
                local r = random(100)
                if r <= 35 then return "1" elseif r <= 70 then return "2" else return "3" end
            end

            self:generateScenery(6, "computer", variantGenerator)
        end
    end


    function LevelGenerator:generateScenery(maxAmount, type, variantGenerator)
        local amount = random(maxAmount)

        while amount > 0 do
            local batch = random(amount)
            local group = {}

            if amount == 1 then batch = 1 end

            for i=1,batch do
                group[#group+1] = {object="obstacle", type=type, variant=variantGenerator()}
            end

            self:placeEntities(group, random(3))

            amount = amount - batch
        end
    end


    function LevelGenerator:addPowerups()
        local chance = 50

        while chance > 0 do
            if percent(chance) then
                self:generateWeapon()
                chance = chance / 2
            else
                chance = 0
            end
        end
    end


    function LevelGenerator:generateWeapon()
        local weapon = "rifle"
        local r = random(100)

        if     r > 25 and r  <= 50 then weapon = "shotgun"
        elseif r > 50 and r  <= 75 then weapon = "launcher"
        elseif r > 75              then weapon = "laserGun" end

        local startX, startY = self:getRandomPosition()
        local xpos, ypos     = self:place(startX, startY)

        if xpos and ypos then
            self:addEntity({object="weapon", type=weapon, xpos=xpos, ypos=ypos})
        end
    end


    function LevelGenerator:addPoints()
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
        for _,attribs in pairs(group) do
            local placed = false
            while placed == false do
                local startX, startY = self:getRandomPosition()
                local xpos, ypos     = self:place(startX, startY)

                if xpos and ypos then
                    placed = true
                    self:createEntitySpec(xpos, ypos, attribs)
                end
            end
        end
    end


    function LevelGenerator:placeMob(group, distance)
        local startX, startY = self:getRandomPosition()

        for _,attribs in pairs(group) do
            local placed = false
            while placed == false do
                local xpos, ypos = self:place(startX, startY, 20, distance)

                if xpos and ypos then
                    placed = true
                    self:createEntitySpec(xpos, ypos, attribs)
                end
            end
        end
    end


    function LevelGenerator:placeChain(group, distance)
        local xpos, ypos = self:getRandomPosition()

        for _,attribs in pairs(group) do
            local placed = false
            while placed == false do
                xpos, ypos = self:place(xpos, ypos, 20, distance)

                if xpos and ypos then
                    placed = true
                    self:createEntitySpec(xpos, ypos, attribs)
                end
            end
        end
    end


end



return Loader