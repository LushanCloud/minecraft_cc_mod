-- Download script for builder modules
-- Run this on your turtle to fetch all required files

local baseUrl = "https://raw.githubusercontent.com/LushanCloud/minecraft_cc_mod/main/builder/"

local files = {
    "cube.lua",
    "fuel.lua",
    "position.lua"
}

print("Fetching builder modules from GitHub...")
print("")

for _, filename in ipairs(files) do
    local url = baseUrl .. filename
    print("Downloading: " .. filename)
    shell.run("wget", url, filename)
end

print("")
print("All modules downloaded!")
print("Usage: cube 5")
