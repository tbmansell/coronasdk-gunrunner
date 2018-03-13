local Stats = {}


function Stats:init(startDistance)
    self.points           = 0
    self.jewels           = 0
    self.shots            = 0
    self.hits             = 0
    self.kills            = 0
    self.startingTime     = os.time()
    self.endingTime       = nil
    self.startingDistance = startDistance
    self.distance         = startDistance
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
    local mins, secs = math.round(seconds / 60), math.round(seconds % 60)

    if mins < 10 then mins = "0"..mins end
    if secs < 10 then secs = "0"..secs end

    return mins, secs
end


function Stats:getHitRatio()
    if self.hits == 0 or self.shots == 0 then
        return 0
    end
    return math.round((self.hits / self.shots) * 100)
end


function Stats:addShot(weapon)
    self.shots = self.shots + 1
end


function Stats:addHit(weapon)
    self.hits = self.hits + 1
end


function Stats:addKill(weapon, type, rank)
    self.kills = self.kills + 1
end 


return Stats