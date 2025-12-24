while true do
  -- 1. 检查前方是否有树苗，没有就种
  turtle.select(1) -- 假设树苗放在第1格
  if not turtle.detect() then
    turtle.place()
  end

  -- 2. 检查前方是不是木头（检测是否有方块且不是树苗）
  turtle.select(1)
  local hasBlock, data = turtle.inspect()
  
  -- 如果前方有方块，且名称里包含 "log" (原木)，就开始砍
  if hasBlock and string.find(data.name, "log") then
    
    -- 3. 开始砍树流程
    print("Found tree! Chopping...")
    turtle.dig() -- 砍掉底部的木头
    turtle.forward() -- 走进树干的位置
    
    -- 向上砍，直到头顶没有木头
    while turtle.detectUp() do
      turtle.digUp()
      turtle.up()
    end
    
    -- 4. 砍完下楼
    while not turtle.detectDown() do
      turtle.down()
    end
    
    turtle.back() -- 退回原位
    
    -- 5. (可选) 把木头倒进身后的箱子
    -- 假设木头在第2格及以后，树苗保留在第1格
    for i = 2, 16 do
      turtle.select(i)
      turtle.dropDown() -- 向身后扔东西
    end
    turtle.select(1) -- 切回树苗格
    
  else
    -- 如果还是树苗或空气，就睡觉等待
    print("Waiting for tree to grow...")
    os.sleep(5) 
  end
end