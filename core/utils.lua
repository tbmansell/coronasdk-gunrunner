-- Class
local Utils = {}

-- Aliases
local random = math.random
local abs    = math.abs
local floor  = math.floor


function Utils.percent(chance)
    return random(100) <= chance
end
	

-- returns a random element from a set with no weighting
function Utils.randomFrom(set, default)
	if set == nil then return default end

	return set[random(#set)]
end


-- returns a random element from a set where the key is a % weighting
function Utils.percentFrom(set, default)
	if set == nil then return default end

	local target = random(100)
	local num = #set

	for i=1,num do
		local element = set[i]
		local chance  = element[1]
		local item    = element[2]

		if target <= chance then
			return item or default
		end
	end
	return default
end


function Utils.percentOf(amount, percent)
    return floor((amount / 100) * percent)
end


-- returns the first element from a percentage set
function Utils.firstFrom(set, default)
	if set == nil or set[1] == nil then return default end
	return set[1][2]
end


function Utils.randomRange(low, high)
    if low < 0 and high > 0 then
        local  value = random(abs(low), high+(high-low))
        return value - (high-low)
    else
        local value = random(abs(low), abs(high))
        if low < 0 and high < 0 then
            return -value
        else
            return value
        end
    end
end


-- Simpler version of randomRange, just passing a pair rather than values and not checking for negatives
function Utils.randomInRange(pair)
    if pair[2] < 1 then
        return 0
    else
        return random(pair[1], pair[2])
    end
end


return Utils