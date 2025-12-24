-- Download script for schematic builder runtime libraries
-- Run this ONCE on your turtle to fetch all required library files
-- Then download your build script separately

local baseUrl = "https://raw.githubusercontent.com/LushanCloud/minecraft_cc_mod/main/builder/schematic/"

local files = {
    "lib.lua",
    "inv.lua",
    "ui.lua",
    "stateful.lua"
}

print("Fetching schematic builder libraries...")
print("")

for _, filename in ipairs(files) do
    local url = baseUrl .. filename
    print("Downloading: " .. filename)
    shell.run("wget", url, filename)
end

print("")
print("Libraries downloaded!")
print("")
print("Now download your build script:")
print("  wget <url> build")
print("")
print("Then run: build")
