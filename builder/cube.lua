-- cube.lua
-- Cube frame builder script
-- Usage: cube <size>
-- Example: cube 5 (builds a 5x5x5 cube frame)

local pos = require("position")
local fuel = require("fuel")

-- Config
local PROGRESS_FILE = "cube_progress.dat"
local MIN_FUEL = 100          -- Minimum fuel warning threshold
local MIN_BLOCKS = 16         -- Minimum blocks warning threshold

-- Supply layout:
-- Turtle start position = origin (0,0,0)
-- Above: Fuel chest
-- Below: Block chest

-- State
local state = {
    size = 5,
    phase = 1,      -- 1=bottom edges, 2=pillars, 3=top edges
    step = 0,       -- Current step within phase
    paused = false  -- Paused due to low fuel/materials
}

-- Save progress
local function saveProgress()
    local file = fs.open(PROGRESS_FILE, "w")
    file.write(textutils.serialize({
        state = state,
        pos = pos.get()
    }))
    file.close()
    print("Progress saved")
end

-- Load progress
local function loadProgress()
    if fs.exists(PROGRESS_FILE) then
        local file = fs.open(PROGRESS_FILE, "r")
        local data = textutils.unserialize(file.readAll())
        file.close()
        if data then
            state = data.state
            pos.set(data.pos.x, data.pos.y, data.pos.z, data.pos.facing)
            print("Progress restored")
            return true
        end
    end
    return false
end

-- Delete progress file
local function clearProgress()
    if fs.exists(PROGRESS_FILE) then
        fs.delete(PROGRESS_FILE)
    end
end

-- Count blocks in inventory
local function countBlocks()
    local total = 0
    for slot = 1, 16 do
        total = total + turtle.getItemCount(slot)
    end
    return total
end

-- Get fuel from chest above
local function refuelFromAbove()
    print("Getting fuel from above...")
    local refueled = false
    
    while turtle.suckUp() do
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
                refueled = true
            end
        end
        
        if fuel.getLevel() >= turtle.getFuelLimit() * 0.9 then
            break
        end
    end
    
    turtle.select(1)
    if refueled then
        print("Fuel refilled: " .. fuel.getLevel())
    else
        print("Warning: No fuel found above")
    end
    return refueled
end

-- Get blocks from chest below
local function getBlocksFromBelow()
    print("Getting blocks from below...")
    local gotBlocks = false
    
    while turtle.suckDown() do
        gotBlocks = true
        local totalSlots = 0
        for slot = 1, 16 do
            if turtle.getItemCount(slot) > 0 then
                totalSlots = totalSlots + 1
            end
        end
        if totalSlots >= 14 then
            break
        end
    end
    
    if gotBlocks then
        print("Blocks loaded: " .. countBlocks())
    else
        print("Warning: No blocks found below")
    end
    return gotBlocks
end

-- Execute full resupply
local function doResupply()
    print("\n=== Resupplying ===")
    
    if fuel.getLevel() < MIN_FUEL then
        refuelFromAbove()
    end
    
    if countBlocks() < MIN_BLOCKS then
        getBlocksFromBelow()
    end
    
    fuel.print()
    print("Blocks: " .. countBlocks())
    print("=== Done ===\n")
end

-- Check if resupply needed
local function needsResupply()
    if fuel.shouldReturnNow(pos) then
        return true, "Low fuel"
    end
    
    if countBlocks() < 4 then
        return true, "Low blocks"
    end
    
    return false, ""
end

-- Check and resupply if needed
local function checkAndResupply()
    local needs, reason = needsResupply()
    if needs then
        print(reason .. ", returning to base...")
        saveProgress()
        pos.goHome()
        doResupply()
        state.paused = true
        return true
    end
    return false
end

-- Safe place block (checks resources first)
local function safePlaceDown()
    if checkAndResupply() then
        return false
    end
    
    -- Find a slot with blocks
    local foundSlot = nil
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            foundSlot = slot
            turtle.select(slot)
            break
        end
    end
    
    if not foundSlot then
        print("Error: No blocks in inventory!")
        return false
    end
    
    local success = turtle.placeDown()
    if success then
        print(string.format("Placed block at (%d,%d,%d)", pos.x, pos.y - 1, pos.z))
    else
        print("Warning: Could not place block!")
    end
    return true
end

-- Safe movement (checks resources first)
local function safeForward()
    if checkAndResupply() then
        return false
    end
    return pos.forward()
end

local function safeUp()
    if checkAndResupply() then
        return false
    end
    return pos.up()
end

-- Build a line of length-1 blocks
local function buildLine(length)
    for i = 1, length - 1 do
        if not safePlaceDown() then return false end
        if i < length - 1 then
            if not safeForward() then return false end
        end
    end
    return true
end

-- Phase 1: Build bottom edges
local function buildBottomEdges()
    print("Building bottom edges...")
    local size = state.size
    
    -- Start at (1,1,0) to avoid fuel chest at origin
    -- First move forward, then up
    pos.goTo(1, 0, 0)  -- Move forward first
    pos.goTo(1, 1, 0)  -- Then go up
    pos.goTo(0, 1, 0)  -- Go back to corner
    
    for edge = 1, 4 do
        if not buildLine(size) then return false end
        if edge < 4 then
            pos.turnRight()
            if not safeForward() then return false end
        end
    end
    
    return true
end

-- Phase 2: Build pillars
local function buildPillars()
    print("Building pillars...")
    local size = state.size
    
    local corners = {
        {x = 0, z = 0},
        {x = size - 1, z = 0},
        {x = size - 1, z = size - 1},
        {x = 0, z = size - 1}
    }
    
    for i, corner in ipairs(corners) do
        print(string.format("Pillar %d/4 at (%d, %d)", i, corner.x, corner.z))
        pos.goTo(corner.x, 1, corner.z)
        
        -- Build upward
        for h = 2, size - 1 do
            if not safeUp() then return false end
            if not safePlaceDown() then return false end
        end
        
        -- Return to bottom
        print("Descending...")
        local retries = 0
        while pos.y > 1 do
            if not pos.down() then
                turtle.digDown()
                sleep(0.3)
                if not pos.down() then
                    retries = retries + 1
                    if retries > 10 then
                        print("Error: Stuck going down in pillar!")
                        return false
                    end
                    sleep(0.5)
                else
                    retries = 0
                end
            else
                retries = 0
            end
        end
        print(string.format("Pillar %d complete", i))
    end
    
    return true
end

-- Phase 3: Build top edges
local function buildTopEdges()
    print("Building top edges...")
    local size = state.size
    
    pos.goTo(0, size, 0)
    
    for edge = 1, 4 do
        if not buildLine(size) then return false end
        if edge < 4 then
            pos.turnRight()
            if not safeForward() then return false end
        end
    end
    
    return true
end

-- Main build function
local function build()
    print(string.format("Building %dx%dx%d cube frame", state.size, state.size, state.size))
    fuel.print()
    pos.print()
    
    local phases = {
        {name = "Bottom edges", func = buildBottomEdges},
        {name = "Pillars",      func = buildPillars},
        {name = "Top edges",    func = buildTopEdges}
    }
    
    for i = state.phase, #phases do
        state.phase = i
        print(string.format("Phase %d/3: %s", i, phases[i].name))
        
        if not phases[i].func() then
            print("Build interrupted, please resupply")
            return false
        end
    end
    
    print("Build complete! Returning home...")
    pos.goHome()
    clearProgress()
    
    return true
end

-- Wait for resupply
local function waitForResupply()
    print("\n=== Supply Check ===")
    print("Fuel: " .. fuel.getLevel())
    print("Blocks: " .. countBlocks())
    
    if fuel.getLevel() < MIN_FUEL or countBlocks() < MIN_BLOCKS then
        print("\nResources still low!")
        print("Please check:")
        print("  - Fuel chest above")
        print("  - Block chest below")
        print("Press any key to retry...")
        os.pullEvent("key")
        doResupply()
    end
    
    if fuel.getLevel() >= MIN_FUEL and countBlocks() >= MIN_BLOCKS then
        print("Resources OK, continuing...")
        state.paused = false
    else
        print("Warning: Resources still low, will try anyway")
        state.paused = false
    end
end

-- Main program
local function main(args)
    local size = tonumber(args[1]) or 5
    if size < 3 then
        print("Error: Size must be at least 3")
        return
    end
    
    if loadProgress() then
        print("Found unfinished build")
        print(string.format("Size: %d, Phase: %d", state.size, state.phase))
        print("Press R to resume, N for new")
        
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.r then
                print("Resuming...")
                break
            elseif key == keys.n then
                print("Starting new...")
                clearProgress()
                state = {size = size, phase = 1, step = 0, paused = false}
                pos.reset()
                break
            end
        end
    else
        state.size = size
    end
    -- Initial resupply first
    print("\nInitial supply check...")
    doResupply()
    
    -- Now check if we have blocks (after resupply)
    local hasBlocks = false
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            hasBlocks = true
            break
        end
    end
    
    if not hasBlocks then
        print("Error: No blocks available!")
        print("Check the chest below and try again")
        return
    end
    
    while true do
        if state.paused then
            waitForResupply()
            local saved = loadProgress()
            if saved then
                pos.goTo(pos.x, pos.y, pos.z)
            end
        end
        
        if build() then
            print("\n=== Build Complete! ===")
            break
        end
    end
end

-- Run
main({...})
