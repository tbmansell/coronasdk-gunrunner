-- Class
local Utils = {}

-- Aliases
local math_random = math.random
local math_abs    = math.abs
	

-- returns a random element from a set with no weighting
function Utils.randomFrom(set, default)
	if set == nil then return default end

	return set[math_random(#set)]
end


-- returns a random element from a set where the key is a % weighting
function Utils.percentFrom(set, default)
	if set == nil then return default end

	local target = math_random(100)
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


-- returns the first element from a percentage set
function Utils.firstFrom(set, default)
	if set == nil or set[1] == nil then return default end
	return set[1][2]
end


function Utils.randomRange(low, high)
    if low < 0 and high > 0 then
        local  value = math_random(math_abs(low), high+(high-low))
        return value - (high-low)
    else
        local value = math_random(math_abs(low), math_abs(high))
        if low < 0 and high < 0 then
            return -value
        else
            return value
        end
    end
end


return Utils