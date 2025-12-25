-- Stateful wrapper for schematic builder
-- Non-invasive state management - just require("stateful") instead of require("lib")
-- Adds: progress saving, resume capability, improved fuel handling

local lib = require("lib")
local ui = require("ui")

-- State management
local STATE_DIR = "/.states/"
local setupComplete = false
local isResuming = false

local function ensureStateDir()
  if not fs.exists(STATE_DIR) then fs.makeDir(STATE_DIR) end
end

local function getStateFile()
  local prog = shell.getRunningProgram()
  local name = fs.getName(prog):gsub("%.lua$", "")
  return STATE_DIR .. name .. ".state"
end

local function saveState(step, setupDone)
  ensureStateDir()
  local file = fs.open(getStateFile(), "w")
  file.write(textutils.serialise({ step = step, setupDone = setupDone }))
  file.close()
end

local function loadState()
  local stateFile = getStateFile()
  if not fs.exists(stateFile) then return { step = 0, setupDone = false } end
  local file = fs.open(stateFile, "r")
  local content = file.readAll()
  file.close()
  local state = textutils.unserialise(content)
  if type(state) == "number" then
    -- Legacy format: just a number
    return { step = state, setupDone = state > 0 }
  end
  return state or { step = 0, setupDone = false }
end

local function clearState()
  local stateFile = getStateFile()
  if fs.exists(stateFile) then fs.delete(stateFile) end
end

-- Check if we are resuming
local function checkResume()
  local state = loadState()
  if state.step > 0 then
    isResuming = true
    setupComplete = state.setupDone
    ui.clear()
    print("Resuming from step " .. state.step)
    print("Setup already complete, skipping init...")
    sleep(1)
  end
  return state.step
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

-- Wrapped functions that skip if resuming
local function statefulRefuel(amount)
  if isResuming and setupComplete then
    return -- Skip refuel when resuming
  end
  lib.refuel(amount)
end

local function statefulDumpInventory()
  if isResuming and setupComplete then
    return -- Skip dump when resuming
  end
  lib.dumpInventory()
end

local function statefulResupply(items)
  if isResuming and setupComplete then
    return -- Skip resupply when resuming
  end
  lib.resupply(items)
end

-- Wrap the execute function with state tracking
local function statefulExecute(script)
  local savedStep = checkResume()
  local currentStep = 0
  
  -- Mark setup as complete before execute
  setupComplete = true
  saveState(savedStep, true)
  
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
      saveState(currentStep, true)
    end
  end
  
  -- Build complete, clear state
  clearState()
  isResuming = false
  setupComplete = false
end

-- Export wrapped module
return {
  refuel = statefulRefuel,
  resupply = statefulResupply,
  dumpInventory = statefulDumpInventory,
  execute = statefulExecute,
  clear = lib.clear,
  -- Extra utilities
  clearState = clearState,
  getProgress = function() return loadState().step end,
}
