local Stats = {
    -- total points gained over game
    points = 0,
    -- number of jewels collected
    jewels = 0,

    -- time in seconds player survived
    time = 0,
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
    }
}


function Stats:addPoints(points)
    self.points = self.points + points
end


function Stats:addJewels(jewels)
    self.jewels = self.jewels + jewels
end


function Stats:setDistance(currentDistance)
    if currentDistance > self.distance then
        self.distance = currentDistance
    end
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

    self.enemies[type][rank] = self.enemies[type][rank] + 1
end 


return Stats