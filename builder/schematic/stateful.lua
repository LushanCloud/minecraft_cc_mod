-- Stateful wrapper for schematic builder
-- Non-invasive state management - just require("stateful") instead of require("lib")
-- Adds: progress saving, resume capability, improved fuel handling

local lib = require("lib")
local ui = require("ui")

-- State management
local STATE_DIR = "/.states/"

local function ensureStateDir()
  if not fs.exists(STATE_DIR) then fs.makeDir(STATE_DIR) end
end

local function getStateFile()
  local prog = shell.getRunningProgram()
  local name = fs.getName(prog):gsub("%.lua$", "")
  return STATE_DIR .. name .. ".state"
end

local function saveState(step)
  ensureStateDir()
  local file = fs.open(getStateFile(), "w")
  file.write(tostring(step))
  file.close()
end

local function loadState()
  local stateFile = getStateFile()
  if not fs.exists(stateFile) then return 0 end
  local file = fs.open(stateFile, "r")
  local step = tonumber(file.readAll()) or 0
  file.close()
  return step
end

local function clearState()
  local stateFile = getStateFile()
  if fs.exists(stateFile) then fs.delete(stateFile) end
end

-- Improved fuel handling - wait instead of error
local function waitForFuel()
  while true do
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" or fuelLevel > 0 then return end
    
    -- Try to consume fuel from inventory
    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.refuel(1) then
        ui.clear()
        return
      end
    end
    
    ui.clear()
    print("Out of fuel! Please add fuel...")
    print("Current level: " .. tostring(turtle.getFuelLevel()))
    sleep(2)
  end
end

-- Wrap the execute function with state tracking
local function statefulExecute(script)
  local savedStep = loadState()
  local currentStep = 0
  
  if savedStep > 0 then
    ui.clear()
    print("Resuming from step " .. savedStep)
    sleep(1)
  end
  
  local lines = {}
  for line in script:gmatch("([^\r\n]+)") do
    table.insert(lines, line)
  end
  
  for i, line in ipairs(lines) do
    currentStep = i
    
    -- Skip already completed steps
    if currentStep <= savedStep then
      -- Do nothing, skip this step
    else
      -- Check fuel before each move
      waitForFuel()
      
      -- Execute single line using original lib
      lib.execute(line)
      
      -- Save progress after each step
      saveState(currentStep)
    end
  end
  
  -- Build complete, clear state
  clearState()
end

-- Export wrapped module
return {
  refuel = lib.refuel,
  resupply = lib.resupply,
  dumpInventory = lib.dumpInventory,
  execute = statefulExecute,
  clear = lib.clear,
  -- Extra utilities
  clearState = clearState,
  getProgress = loadState,
}
