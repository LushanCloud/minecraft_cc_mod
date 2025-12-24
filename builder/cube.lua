-- cube.lua
-- 立方体框架建造脚本
-- 用法: cube <size>
-- 例如: cube 5 (建造5x5x5的立方体框架)

local pos = require("position")
local fuel = require("fuel")

-- 配置
local PROGRESS_FILE = "cube_progress.dat"
local MIN_FUEL = 100          -- 最低燃料警戒值
local MIN_BLOCKS = 16          -- 最低方块数警戒值

-- 补给布局说明:
-- 海龟起始位置 = 原点(0,0,0)
-- 上方: 燃料箱子
-- 下方: 方块箱子

-- 状态
local state = {
    size = 5,
    phase = 1,      -- 1=底边, 2=立柱, 3=顶边
    step = 0,       -- 当前阶段内的步骤
    paused = false  -- 是否因燃料/材料不足暂停
}

-- 保存进度
local function saveProgress()
    local file = fs.open(PROGRESS_FILE, "w")
    file.write(textutils.serialize({
        state = state,
        pos = pos.get()
    }))
    file.close()
    print("进度已保存")
end

-- 加载进度
local function loadProgress()
    if fs.exists(PROGRESS_FILE) then
        local file = fs.open(PROGRESS_FILE, "r")
        local data = textutils.unserialize(file.readAll())
        file.close()
        if data then
            state = data.state
            pos.set(data.pos.x, data.pos.y, data.pos.z, data.pos.facing)
            print("已恢复进度")
            return true
        end
    end
    return false
end

-- 删除进度文件
local function clearProgress()
    if fs.exists(PROGRESS_FILE) then
        fs.delete(PROGRESS_FILE)
    end
end

-- 统计背包中的方块数量
local function countBlocks()
    local total = 0
    for slot = 1, 16 do
        total = total + turtle.getItemCount(slot)
    end
    return total
end

-- 从上方箱子取燃料并加油
local function refuelFromAbove()
    print("从上方箱子取燃料...")
    local refueled = false
    
    -- 从上方箱子取物品
    while turtle.suckUp() do
        -- 尝试将取到的物品作为燃料
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then  -- 检查是否是燃料
                turtle.refuel()        -- 消耗燃料
                refueled = true
            end
        end
        
        -- 如果燃料已满，停止取
        if fuel.getLevel() >= turtle.getFuelLimit() * 0.9 then
            break
        end
    end
    
    turtle.select(1)
    if refueled then
        print("燃料补充完成，当前: " .. fuel.getLevel())
    else
        print("警告: 未能补充燃料，请检查上方箱子")
    end
    return refueled
end

-- 从下方箱子取建筑方块
local function getBlocksFromBelow()
    print("从下方箱子取方块...")
    local gotBlocks = false
    
    -- 取方块直到背包满或箱子空
    while turtle.suckDown() do
        gotBlocks = true
        -- 检查背包是否接近满
        local totalSlots = 0
        for slot = 1, 16 do
            if turtle.getItemCount(slot) > 0 then
                totalSlots = totalSlots + 1
            end
        end
        if totalSlots >= 14 then  -- 保留2个空槽
            break
        end
    end
    
    if gotBlocks then
        print("方块补充完成，当前: " .. countBlocks() .. " 个")
    else
        print("警告: 未能补充方块，请检查下方箱子")
    end
    return gotBlocks
end

-- 执行完整补给流程
local function doResupply()
    print("\n=== 开始补给 ===")
    
    -- 补充燃料
    if fuel.getLevel() < MIN_FUEL then
        refuelFromAbove()
    end
    
    -- 补充方块
    if countBlocks() < MIN_BLOCKS then
        getBlocksFromBelow()
    end
    
    fuel.print()
    print("方块数量: " .. countBlocks())
    print("=== 补给完成 ===\n")
end

-- 检查是否需要返回补给
local function needsResupply()
    -- 检查燃料
    if fuel.shouldReturnNow(pos) then
        return true, "燃料不足"
    end
    
    -- 检查方块
    if countBlocks() < 4 then
        return true, "方块不足"
    end
    
    return false, ""
end

-- 检查并在必要时返回补给
local function checkAndResupply()
    local needs, reason = needsResupply()
    if needs then
        print(reason .. "，返回基地补给...")
        saveProgress()
        pos.goHome()
        doResupply()
        state.paused = true
        return true
    end
    return false
end

-- 安全放置方块（检查资源后）
local function safePlaceDown()
    if checkAndResupply() then
        return false
    end
    
    -- 选择有方块的槽位
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            break
        end
    end
    
    turtle.placeDown()
    return true
end

-- 安全移动（检查资源后）
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

-- 建造一条线（长度为 length-1 个方块）
local function buildLine(length)
    for i = 1, length - 1 do
        if not safePlaceDown() then return false end
        if i < length - 1 then
            if not safeForward() then return false end
        end
    end
    return true
end

-- 阶段1: 建造底面四条边
local function buildBottomEdges()
    print("建造底面边框...")
    local size = state.size
    
    -- 移动到起始位置（角落）
    pos.goTo(0, 1, 0)  -- 升高一格以便放置方块
    
    for edge = 1, 4 do
        if not buildLine(size) then return false end
        if edge < 4 then
            pos.turnRight()
            if not safeForward() then return false end
        end
    end
    
    return true
end

-- 阶段2: 建造四个立柱
local function buildPillars()
    print("建造立柱...")
    local size = state.size
    
    -- 四个角落的相对坐标
    local corners = {
        {x = 0, z = 0},
        {x = size - 1, z = 0},
        {x = size - 1, z = size - 1},
        {x = 0, z = size - 1}
    }
    
    for _, corner in ipairs(corners) do
        pos.goTo(corner.x, 1, corner.z)
        
        -- 向上建造立柱
        for h = 2, size - 1 do
            if not safeUp() then return false end
            if not safePlaceDown() then return false end
        end
        
        -- 回到底部
        while pos.y > 1 do
            pos.down()
        end
    end
    
    return true
end

-- 阶段3: 建造顶面四条边
local function buildTopEdges()
    print("建造顶面边框...")
    local size = state.size
    
    -- 移动到顶面起始位置
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

-- 主建造函数
local function build()
    print(string.format("开始建造 %dx%dx%d 立方体框架", state.size, state.size, state.size))
    fuel.print()
    pos.print()
    
    local phases = {
        {name = "底面边框", func = buildBottomEdges},
        {name = "立柱",     func = buildPillars},
        {name = "顶面边框", func = buildTopEdges}
    }
    
    for i = state.phase, #phases do
        state.phase = i
        print(string.format("阶段 %d/3: %s", i, phases[i].name))
        
        if not phases[i].func() then
            print("建造中断，请补充燃料后重新运行")
            return false
        end
    end
    
    -- 完成，返回基地
    print("建造完成！返回基地...")
    pos.goHome()
    clearProgress()
    
    return true
end

-- 等待补给完成后继续
local function waitForResupply()
    print("\n=== 补给检查 ===")
    print("当前燃料: " .. fuel.getLevel())
    print("当前方块: " .. countBlocks())
    
    -- 检查是否还需要手动补给
    if fuel.getLevel() < MIN_FUEL or countBlocks() < MIN_BLOCKS then
        print("\n资源仍不足！")
        print("请确保：")
        print("  - 上方箱子有燃料")
        print("  - 下方箱子有方块")
        print("按任意键重试补给...")
        os.pullEvent("key")
        doResupply()
    end
    
    if fuel.getLevel() >= MIN_FUEL and countBlocks() >= MIN_BLOCKS then
        print("资源充足，继续建造...")
        state.paused = false
    else
        print("警告: 资源仍然不足，将尝试继续")
        state.paused = false
    end
end

-- 主程序
local function main(args)
    -- 解析参数
    local size = tonumber(args[1]) or 5
    if size < 3 then
        print("错误: 尺寸至少为3")
        return
    end
    
    -- 检查是否有未完成的进度
    if loadProgress() then
        print("发现未完成的建造任务")
        print(string.format("尺寸: %d, 阶段: %d", state.size, state.phase))
        print("按 R 继续, 按 N 重新开始")
        
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.r then
                print("继续上次的建造...")
                break
            elseif key == keys.n then
                print("重新开始...")
                clearProgress()
                state = {size = size, phase = 1, step = 0, paused = false}
                pos.reset()
                break
            end
        end
    else
        state.size = size
    end
    
    -- 检查背包是否有建筑材料
    local hasBlocks = false
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            hasBlocks = true
            break
        end
    end
    
    if not hasBlocks then
        print("错误: 背包中没有建筑材料！")
        print("请在背包中放入方块后重新运行")
        return
    end
    
    -- 起始补给
    print("\n初始补给检查...")
    doResupply()
    
    -- 主循环
    while true do
        if state.paused then
            waitForResupply()
            -- 返回到保存的位置继续
            local saved = loadProgress()
            if saved then
                pos.goTo(pos.x, pos.y, pos.z)
            end
        end
        
        if build() then
            print("\n=== 建造完成！ ===")
            break
        end
    end
end

-- 运行
main({...})
