-- position.lua
-- Turtle position tracking module
-- Maintains position relative to origin (0,0,0)

local position = {
    x = 0,
    y = 0,
    z = 0,
    facing = 0  -- 0=north(z-), 1=east(x+), 2=south(z+), 3=west(x-)
}

-- Direction names
local DIRECTIONS = {"north", "east", "south", "west"}

-- Get current position
function position.get()
    return {x = position.x, y = position.y, z = position.z, facing = position.facing}
end

-- Set position (for restoring progress)
function position.set(x, y, z, facing)
    position.x = x or position.x
    position.y = y or position.y
    position.z = z or position.z
    position.facing = facing or position.facing
end

-- Reset to origin
function position.reset()
    position.x = 0
    position.y = 0
    position.z = 0
    position.facing = 0
end

-- Calculate Manhattan distance
function position.distanceTo(x, y, z)
    return math.abs(position.x - x) + math.abs(position.y - y) + math.abs(position.z - z)
end

-- Calculate distance to origin
function position.distanceToHome()
    return position.distanceTo(0, 0, 0)
end

-- Move forward
function position.forward()
    if turtle.forward() then
        if position.facing == 0 then
            position.z = position.z - 1
        elseif position.facing == 1 then
            position.x = position.x + 1
        elseif position.facing == 2 then
            position.z = position.z + 1
        elseif position.facing == 3 then
            position.x = position.x - 1
        end
        return true
    end
    return false
end

-- Move back
function position.back()
    if turtle.back() then
        if position.facing == 0 then
            position.z = position.z + 1
        elseif position.facing == 1 then
            position.x = position.x - 1
        elseif position.facing == 2 then
            position.z = position.z - 1
        elseif position.facing == 3 then
            position.x = position.x + 1
        end
        return true
    end
    return false
end

-- Move up
function position.up()
    if turtle.up() then
        position.y = position.y + 1
        return true
    end
    return false
end

-- Move down
function position.down()
    if turtle.down() then
        position.y = position.y - 1
        return true
    end
    return false
end

-- Turn left
function position.turnLeft()
    turtle.turnLeft()
    position.facing = (position.facing - 1) % 4
end

-- Turn right
function position.turnRight()
    turtle.turnRight()
    position.facing = (position.facing + 1) % 4
end

-- Face specified direction
function position.face(dir)
    while position.facing ~= dir do
        position.turnRight()
    end
end

-- Return to origin (simple: Y first, then X, then Z)
function position.goHome()
    print("Returning home...")
    
    -- First go to y=0
    while position.y > 0 do
        if not position.down() then
            turtle.digDown()
            position.down()
        end
    end
    while position.y < 0 do
        if not position.up() then
            turtle.digUp()
            position.up()
        end
    end
    
    -- Move to x=0
    if position.x > 0 then
        position.face(3)  -- west
    elseif position.x < 0 then
        position.face(1)  -- east
    end
    while position.x ~= 0 do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- Move to z=0
    if position.z > 0 then
        position.face(0)  -- north
    elseif position.z < 0 then
        position.face(2)  -- south
    end
    while position.z ~= 0 do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- Face north
    position.face(0)
    print("Home reached")
end

-- Move to specified coordinates
-- IMPORTANT: Moves X/Z first, then Y, to avoid chest above origin
function position.goTo(targetX, targetY, targetZ)
    -- Handle X axis first (move away from origin)
    if position.x < targetX then
        position.face(1)  -- east
    elseif position.x > targetX then
        position.face(3)  -- west
    end
    while position.x ~= targetX do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- Handle Z axis
    if position.z < targetZ then
        position.face(2)  -- south
    elseif position.z > targetZ then
        position.face(0)  -- north
    end
    while position.z ~= targetZ do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- Handle Y axis last (now safe from chest)
    while position.y < targetY do
        if not position.up() then
            turtle.digUp()
            position.up()
        end
    end
    while position.y > targetY do
        if not position.down() then
            turtle.digDown()
            position.down()
        end
    end
end

-- Print current position
function position.print()
    print(string.format("Pos: (%d, %d, %d) Facing: %s", 
        position.x, position.y, position.z, DIRECTIONS[position.facing + 1]))
end

return position
