-- position.lua
-- 海龟位置追踪模块
-- 维护相对于起点(0,0,0)的坐标和朝向

local position = {
    x = 0,
    y = 0,
    z = 0,
    facing = 0  -- 0=北(z-), 1=东(x+), 2=南(z+), 3=西(x-)
}

-- 方向名称
local DIRECTIONS = {"north", "east", "south", "west"}

-- 获取当前位置
function position.get()
    return {x = position.x, y = position.y, z = position.z, facing = position.facing}
end

-- 设置位置（用于恢复进度）
function position.set(x, y, z, facing)
    position.x = x or position.x
    position.y = y or position.y
    position.z = z or position.z
    position.facing = facing or position.facing
end

-- 重置到原点
function position.reset()
    position.x = 0
    position.y = 0
    position.z = 0
    position.facing = 0
end

-- 计算曼哈顿距离
function position.distanceTo(x, y, z)
    return math.abs(position.x - x) + math.abs(position.y - y) + math.abs(position.z - z)
end

-- 计算到原点的距离
function position.distanceToHome()
    return position.distanceTo(0, 0, 0)
end

-- 向前移动
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

-- 向后移动
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

-- 向上移动
function position.up()
    if turtle.up() then
        position.y = position.y + 1
        return true
    end
    return false
end

-- 向下移动
function position.down()
    if turtle.down() then
        position.y = position.y - 1
        return true
    end
    return false
end

-- 左转
function position.turnLeft()
    turtle.turnLeft()
    position.facing = (position.facing - 1) % 4
end

-- 右转
function position.turnRight()
    turtle.turnRight()
    position.facing = (position.facing + 1) % 4
end

-- 转向指定方向
function position.face(dir)
    while position.facing ~= dir do
        position.turnRight()
    end
end

-- 返回原点（简单版：先Y轴，再X轴，最后Z轴）
function position.goHome()
    print("返回基地...")
    
    -- 先降到 y=0
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
    
    -- 移动到 x=0
    if position.x > 0 then
        position.face(3)  -- 西
    elseif position.x < 0 then
        position.face(1)  -- 东
    end
    while position.x ~= 0 do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- 移动到 z=0
    if position.z > 0 then
        position.face(0)  -- 北
    elseif position.z < 0 then
        position.face(2)  -- 南
    end
    while position.z ~= 0 do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- 面向北方
    position.face(0)
    print("已返回基地")
end

-- 移动到指定坐标
function position.goTo(targetX, targetY, targetZ)
    -- 先处理Y轴
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
    
    -- 处理X轴
    if position.x < targetX then
        position.face(1)  -- 东
    elseif position.x > targetX then
        position.face(3)  -- 西
    end
    while position.x ~= targetX do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
    
    -- 处理Z轴
    if position.z < targetZ then
        position.face(2)  -- 南
    elseif position.z > targetZ then
        position.face(0)  -- 北
    end
    while position.z ~= targetZ do
        if not position.forward() then
            turtle.dig()
            position.forward()
        end
    end
end

-- 打印当前位置
function position.print()
    print(string.format("位置: (%d, %d, %d) 朝向: %s", 
        position.x, position.y, position.z, DIRECTIONS[position.facing + 1]))
end

return position
