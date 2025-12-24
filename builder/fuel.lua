-- fuel.lua
-- Fuel management module
-- Provides fuel checking and warning functions

local fuel = {
    safetyMargin = 10  -- Safety margin
}

-- Get current fuel level
function fuel.getLevel()
    return turtle.getFuelLevel()
end

-- Get fuel limit
function fuel.getLimit()
    return turtle.getFuelLimit()
end

-- Check if refuel needed
function fuel.needsRefuel(threshold)
    threshold = threshold or 100
    return fuel.getLevel() < threshold
end

-- Check if can reach target and return to origin
-- distance: distance to target
-- returnDistance: distance from target back to origin
function fuel.canReachAndReturn(distance, returnDistance)
    local required = distance + returnDistance + fuel.safetyMargin
    local current = fuel.getLevel()
    return current >= required, current, required
end

-- Check if can safely return to origin from current position
function fuel.canReturnHome(distanceToHome)
    local required = distanceToHome + fuel.safetyMargin
    local current = fuel.getLevel()
    return current >= required, current, required
end

-- Check if should return immediately
-- pos: position module
function fuel.shouldReturnNow(pos)
    local distHome = pos.distanceToHome()
    local canReturn, current, required = fuel.canReturnHome(distHome)
    
    if not canReturn then
        print(string.format("Warning: Low fuel! Have:%d Need:%d", current, required))
        return true
    end
    return false
end

-- Try to refuel from inventory
function fuel.refuelFromInventory()
    local refueled = false
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then  -- Check if fuel item
            local count = turtle.getItemCount(slot)
            if count > 0 then
                turtle.refuel(count)
                refueled = true
                print("Refueled, now: " .. fuel.getLevel())
            end
        end
    end
    turtle.select(1)
    return refueled
end

-- Set safety margin
function fuel.setSafetyMargin(margin)
    fuel.safetyMargin = margin
end

-- Print fuel status
function fuel.print()
    local level = fuel.getLevel()
    local limit = fuel.getLimit()
    if limit == "unlimited" then
        print("Fuel: unlimited")
    else
        print(string.format("Fuel: %d / %d", level, limit))
    end
end

return fuel
