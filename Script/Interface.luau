StarLight = {
    BaseUrl     = "https://raw.githubusercontent.com/StarLight-scrpit/StarLight-Asset/refs/heads/main/",
    ObsidianUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/",
    Theme = {
        FontColor       = "#FFFFFF",
        MainColor       = "#1E1E2E",
        AccentColor     = "#89B4FA",
        BackgroundColor = "#181825",
        OutlineColor    = "#313244",
    },
}

local function SafeLoad(url, label)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[StarLight/Interface] Failed: " .. (label or url))
        return nil
    end
    return result
end

local Library = SafeLoad(StarLight.ObsidianUrl .. "Library.lua", "Library")
if not Library then
    warn("[StarLight] UI Library completely failed. Script cannot continue.")
    return nil
end

local Interface = {
    Library      = Library,
    SaveManager  = SafeLoad(StarLight.ObsidianUrl .. "addons/SaveManager.lua",  "SaveManager"),
    ThemeManager = SafeLoad(StarLight.ObsidianUrl .. "addons/ThemeManager.lua", "ThemeManager"),
    EspLibrary   = SafeLoad(StarLight.BaseUrl .. "Script/EspLibrary.luau",      "EspLibrary"),
    NotifyLibrary= SafeLoad(StarLight.BaseUrl .. "Script/NotifyLibrary.luau",   "NotifyLibrary"),
}

if Interface.ThemeManager then
    Interface.ThemeManager.BuiltInThemes = {
        ["StarLight"] = {
            1, {
                FontColor       = StarLight.Theme.FontColor,
                MainColor       = StarLight.Theme.MainColor,
                AccentColor     = StarLight.Theme.AccentColor,
                BackgroundColor = StarLight.Theme.BackgroundColor,
                OutlineColor    = StarLight.Theme.OutlineColor,
            }
        },
    }
end

return Interface
