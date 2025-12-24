-- fuel.lua
-- 燃料管理模块
-- 提供燃料检查和预警功能

local fuel = {
    safetyMargin = 10  -- 安全余量
}

-- 获取当前燃料
function fuel.getLevel()
    return turtle.getFuelLevel()
end

-- 获取燃料上限
function fuel.getLimit()
    return turtle.getFuelLimit()
end

-- 检查是否需要补给
function fuel.needsRefuel(threshold)
    threshold = threshold or 100
    return fuel.getLevel() < threshold
end

-- 判断是否能到达目标并安全返回原点
-- distance: 到目标的距离
-- returnDistance: 从目标返回原点的距离
function fuel.canReachAndReturn(distance, returnDistance)
    local required = distance + returnDistance + fuel.safetyMargin
    local current = fuel.getLevel()
    return current >= required, current, required
end

-- 判断从当前位置是否能安全返回原点
function fuel.canReturnHome(distanceToHome)
    local required = distanceToHome + fuel.safetyMargin
    local current = fuel.getLevel()
    return current >= required, current, required
end

-- 判断是否应该立即返回
-- pos: position 模块
function fuel.shouldReturnNow(pos)
    local distHome = pos.distanceToHome()
    local canReturn, current, required = fuel.canReturnHome(distHome)
    
    if not canReturn then
        print(string.format("警告: 燃料不足! 当前:%d 返回需要:%d", current, required))
        return true
    end
    return false
end

-- 尝试从背包补充燃料
function fuel.refuelFromInventory()
    local refueled = false
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then  -- 检查是否是燃料
            local count = turtle.getItemCount(slot)
            if count > 0 then
                turtle.refuel(count)
                refueled = true
                print("已补充燃料，当前: " .. fuel.getLevel())
            end
        end
    end
    turtle.select(1)
    return refueled
end

-- 设置安全余量
function fuel.setSafetyMargin(margin)
    fuel.safetyMargin = margin
end

-- 打印燃料状态
function fuel.print()
    local level = fuel.getLevel()
    local limit = fuel.getLimit()
    if limit == "unlimited" then
        print("燃料: 无限")
    else
        print(string.format("燃料: %d / %d", level, limit))
    end
end

return fuel
