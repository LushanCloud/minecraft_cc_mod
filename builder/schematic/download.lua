-- Download script for schematic builder modules
-- Run this on your turtle to fetch all required files

local baseUrl = "https://raw.githubusercontent.com/LushanCloud/minecraft_cc_mod/main/builder/schematic/"

local files = {
    "lib.lua",
    "inv.lua",
    "ui.lua",
    "build.lua"
}

print("Fetching schematic builder modules...")
print("")

for _, filename in ipairs(files) do
    local url = baseUrl .. filename
    print("Downloading: " .. filename)
    shell.run("wget", url, filename)
end

print("")
print("All modules downloaded!")
print("Usage: build")
