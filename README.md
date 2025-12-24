# 我的世界 CC 模组仓库

这是一个我的世界（Minecraft）CC（ComputerCraft）模组的代码仓库，主要用来编写游戏中**海龟（Turtle）**的程序代码。

## 📁 项目结构

```
我的世界cc模组/
├── README.md          # 项目说明（本文件）
├── 使用说明.md        # 详细的脚本使用说明和注意事项
└── scripts/           # 所有海龟脚本存放目录
    ├── tree.lua       # 自动砍树脚本
    └── lava.lua       # 自动岩浆收集脚本
```

## 🚀 快速开始

### 1. 查看详细使用说明

**阅读 [使用说明.md](使用说明.md) 获取每个脚本的详细使用方法、建筑布局要求和注意事项。**

### 2. 上传脚本到游戏

在游戏中右键海龟，然后：
```lua
edit tree        -- 创建砍树脚本
edit lava        -- 创建岩浆收集脚本
```
将对应脚本从 `scripts/` 目录复制粘贴到编辑器中，按 `Ctrl` 保存。

### 3. 运行脚本

```lua
tree             -- 运行砍树脚本
lava             -- 运行岩浆收集脚本
```

## 📖 简介

ComputerCraft 是我的世界中的一个模组，它添加了可编程的计算机和机器人（海龟）。海龟是可以移动、挖掘、建造和与世界互动的智能机器人，通过 Lua 脚本进行编程控制。

## 📜 可用脚本

### 🌲 tree.lua - 自动砍树机
- **功能**：自动种树、等待生长、砍伐并存储木头
- **适用场景**：无人值守的木材收集系统
- **详细说明**：见 [使用说明.md - tree.lua](使用说明.md#treelua---自动砍树机)

### 🔥 lava.lua - 自动岩浆收集机
- **功能**：从炼药锅自动收集岩浆，支持自动补给和燃料管理
- **适用场景**：滴石锥岩浆收集、火山群系岩浆采集
- **详细说明**：见 [使用说明.md - lava.lua](使用说明.md#lavalua---自动岩浆收集机)

## ⚙️ 关于 ComputerCraft

ComputerCraft 使用 Lua 编程语言，提供了丰富的 API 来控制海龟的行为：

- **移动**：`turtle.forward()`, `turtle.back()`, `turtle.up()`, `turtle.down()`
- **转向**：`turtle.turnLeft()`, `turtle.turnRight()`
- **挖掘**：`turtle.dig()`, `turtle.digUp()`, `turtle.digDown()`
- **放置**：`turtle.place()`, `turtle.placeUp()`, `turtle.placeDown()`
- **物品管理**：`turtle.select()`, `turtle.drop()`, `turtle.suck()`
- **检测**：`turtle.detect()`, `turtle.inspect()`
- **燃料管理**：`turtle.getFuelLevel()`, `turtle.refuel()`

## 💡 通用提示

- **查看燃料**：`turtle.getFuelLevel()`
- **停止脚本**：按住 `Ctrl + T` 约2秒
- **调试模式**：建议先在创造模式下测试脚本

## 🤝 贡献

欢迎添加更多有用的海龟程序！请将新脚本放在 `scripts/` 目录中，并在 `使用说明.md` 中添加相应的使用说明。
