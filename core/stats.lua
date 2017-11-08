local Stats = {
    -- total points gained over game
    points = 0,
    -- number of jewels collected
    jewels = 0,

    -- time when game started
    startingTime = nil,
    -- time when game ended
    endingTime = nil,

    -- as we are moving negatively upscreen, we need to mark the start point
    startingDistance = 0,
    -- distance in tiles (1 tile = 1 metre)
    distance = 0,

    -- stats per weapon
    weapons = {
        [Weapons.rifle.name]    = { shots=0, hits=0, kills=0 },
        [Weapons.shotgun.name]  = { shots=0, hits=0, kills=0 },
        [Weapons.launcher.name] = { shots=0, hits=0, kills=0 },
        [Weapons.laserGun.name] = { shots=0, hits=0, kills=0 },
    },

    -- stats per enemy: format is rank => kills
    enemies = {
        ["melee"]   = {[1]=0, [2]=0, [3]=0},
        ["shooter"] = {[1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0, [8]=0, [9]=0, [10]=0, [11]=0, [12]=0},
        ["reptile"] = {[1]=0, [2]=0, [3]=0},
        ["turret"]  = {[1]=0, [2]=0, [3]=0},
    }
}


function Stats:init(startDistance)
    self.points           = 0
    self.jewels           = 0
    self.startingTime     = os.time()
    self.endingTime       = nil
    self.startingDistance = startDistance
    self.distance         = startDistance

    self.weapons[Weapons.rifle.name]    = { shots=0, hits=0, kills=0 }
    self.weapons[Weapons.shotgun.name]  = { shots=0, hits=0, kills=0 }
    self.weapons[Weapons.launcher.name] = { shots=0, hits=0, kills=0 }
    self.weapons[Weapons.laserGun.name] = { shots=0, hits=0, kills=0 }

    self.enemies = {
        ["melee"]   = {[1]=0, [2]=0, [3]=0},
        ["shooter"] = {[1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0, [8]=0, [9]=0, [10]=0, [11]=0, [12]=0},
        ["reptile"] = {[1]=0, [2]=0, [3]=0},
        ["turret"]  = {[1]=0, [2]=0, [3]=0},
    }
end


function Stats:addPoints(points)
    self.points = self.points + points
end


function Stats:addJewels(jewels)
    self.jewels = self.jewels + jewels
end


function Stats:setDistance(currentDistance)
    if currentDistance < self.distance then
        self.distance = currentDistance
    end
end


function Stats:getDistance()
    local tileSize = 72
    local start    = self.startingDistance / tileSize
    local finish   = self.distance / tileSize

    return math.round(start - finish)
end


function Stats:getTime()
    self.endingTime = os.time()

    local seconds = os.difftime(self.endingTime, self.startingTime)

    -- Return minutes and seconds
    return math.round(seconds / 60), math.round(seconds % 60)
end


function Stats:addShot(weapon)
    local stat = self.weapons[weapon.name]

    if stat then
        stat.shots = stat.shots + 1
    end
end


function Stats:addHit(weapon)
    local stat = self.weapons[weapon.name]

    if stat then
        stat.hits  = stat.hits + 1
    end
end


function Stats:addKill(weapon, type, rank)
    local stat = self.weapons[weapon.name]

    if stat then
        stat.kills = stat.kills + 1
    end

    print("killed type="..tostring(type).." rank="..tostring(rank))

    self.enemies[type][rank] = self.enemies[type][rank] + 1
end 


return Stats