-- === Configuration ===
local length = 64
local sleepTime = 300

-- === State Tracking ===
local currentPos = 0
local fuelThreshold = turtle.getFuelLimit() / 2 

-- === Helper Functions ===

function goTo(target)
    while currentPos < target do
        if turtle.forward() then
            currentPos = currentPos + 1
        else
            print("Path blocked! Waiting...")
            os.sleep(2)
        end
    end
    while currentPos > target do
        if turtle.back() then
            currentPos = currentPos - 1
        else
            print("Cannot move back! Waiting...")
            os.sleep(2)
        end
    end
end

function tryRefuel()
    local currentFuel = turtle.getFuelLevel()
    if currentFuel == "unlimited" then return end
    
    if currentFuel < fuelThreshold then
        print("Low fuel! Drinking lava...")
        turtle.refuel()
        print("Fuel Level: " .. turtle.getFuelLevel())
        return true
    end
    return false
end

function countEmptyBuckets()
    local count = 0
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == "minecraft:bucket" then
            count = count + item.count
        end
    end
    return count
end

function getEmptyBucketSlot()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == "minecraft:bucket" then
            return i
        end
    end
    return -1
end

-- 存放岩浆桶到后面的箱子（假设机器人在原点，面朝前方）
function depositLava()
    print("Depositing lava buckets...")
    turtle.turnRight()
    turtle.turnRight()  -- 转180度，面朝后面的箱子
    
    for i = 1, 16 do
        turtle.select(i)
        local item = turtle.getItemDetail(i)
        if item and string.find(item.name, "lava_bucket") then
            turtle.drop()
        end
    end
    
    turtle.turnRight()
    turtle.turnRight()  -- 转回来，面朝前方
    turtle.select(1)
end

-- 从左边箱子拿取空桶（假设机器人在原点，面朝前方）
function getBuckets()
    print("Getting empty buckets...")
    turtle.turnLeft()  -- 转向左边的箱子
    
    while countEmptyBuckets() < 16 do
        if not turtle.suck() then
            if countEmptyBuckets() > 0 then
                break
            else
                print("No buckets in chest! Waiting 5s...")
                os.sleep(5)
            end
        end
    end
    
    turtle.turnRight()  -- 转回来，面朝前方
    turtle.select(1)
    print("Got " .. countEmptyBuckets() .. " empty buckets")
end

-- === Main Loop ===
while true do
    -- 在原点补给
    goTo(0)
    depositLava()
    getBuckets()
    
    print("Starting lava collection run...")
    
    local i = 1
    while i <= length do
        local slot = getEmptyBucketSlot()
        
        -- 没有空桶了，回去存放并补给
        if slot == -1 then
            print("Inventory full! Returning to deposit...")
            goTo(0)
            depositLava()
            getBuckets()
            -- 不增加 i，从当前位置继续
        else
            goTo(i)
            
            -- 转向右边面对炼药锅
            turtle.turnRight()
            
            local hasBlock, data = turtle.inspect()
            if hasBlock and (data.name == "minecraft:lava_cauldron" or (data.state and data.state.level == 3)) then
                turtle.select(slot)
                if turtle.place() then 
                    print("Collected lava at: " .. i)
                    tryRefuel()
                end
            end
            
            -- 转回来面朝前方
            turtle.turnLeft()
            
            i = i + 1
        end
    end
    
    -- 64格全部完成，返回存放
    goTo(0)
    depositLava()
    
    print("Run complete!")
    print("Sleeping for 5 minutes...")
    
    for t = sleepTime, 0, -1 do
        if t % 60 == 0 then
            print("Time remaining: " .. (t/60) .. " min")
        end
        os.sleep(1)
    end
end