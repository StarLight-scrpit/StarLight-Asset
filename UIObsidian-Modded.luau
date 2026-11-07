local repo = "https://raw.githubusercontent.com/tanhoangviet/Obsidian-UI-Modded/main/"
local repoCacheKey = tostring(os.time())
local function RepoAsset(Path)
    return repo .. Path .. "?v=" .. repoCacheKey
end

local Library = loadstring(game:HttpGet(RepoAsset("Library.lua")))()
local ThemeManager = loadstring(game:HttpGet(RepoAsset("addons/ThemeManager.lua")))()
local SaveManager = loadstring(game:HttpGet(RepoAsset("addons/SaveManager.lua")))()
