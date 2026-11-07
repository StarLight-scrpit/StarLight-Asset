local interface = {}

local Base = "https://raw.githubusercontent.com/StarLight-scrpit/StarLight-Asset/main/UI/"

local available = {
    ["LinoriaLib"] = true,
    ["Obsidan"] = true,
    ["OrionLib-Modded"] = true,
    ["WindUI"] = true,
}

local themes = {
    ["Default"]      = { 1,  { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "0055ff", BackgroundColor = "141414", OutlineColor = "323232" } },
    ["BBot"]         = { 2,  { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
    ["Fatality"]     = { 3,  { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
    ["Jester"]       = { 4,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
    ["Mint"]         = { 5,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
    ["Tokyo Night"]  = { 6,  { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
    ["Ubuntu"]       = { 7,  { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
    ["Quartz"]       = { 8,  { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
    ["Nord"]         = { 9,  { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" } },
    ["Dracula"]      = { 10, { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" } },
    ["Monokai"]      = { 11, { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" } },
    ["Gruvbox"]      = { 12, { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" } },
    ["Solarized"]    = { 13, { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75" } },
    ["Catppuccin"]   = { 14, { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268" } },
    ["One Dark"]     = { 15, { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370" } },
    ["Cyberpunk"]    = { 16, { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" } },
    ["Oceanic Next"] = { 17, { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46" } },
    ["Material"]     = { 18, { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242" } },
}

function interface.isAvailable(name)
    return available[name] == true
end

function interface.getAvailable()
    local out = {}
    for k in pairs(available) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

function interface.load(name)
    if not available[name] then
        return nil, "unknown UI: " .. tostring(name)
    end

    local url = Base .. name .. ".luau"
    local src = game:HttpGet(url)
    if not src or #src == 0 then
        return nil, "fetch failed: " .. url
    end

    local fn, err = loadstring(src)
    if not fn then
        return nil, "loadstring failed: " .. tostring(err)
    end

    local ok, lib = pcall(fn)
    if not ok then
        return nil, "runtime failed: " .. tostring(lib)
    end
    return lib
end

function interface.loadAsync(name, callback)
    task.spawn(function()
        local lib, err = interface.load(name)
        callback(lib, err)
    end)
end

function interface.getThemes()
    local out = {}
    for k in pairs(themes) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

function interface.getTheme(name)
    local t = themes[name]
    if not t then
        return nil
    end
    return t[2], t[1]
end

function interface.hexToColor(hex)
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end

function interface.setTheme(lib, name)
    local t = themes[name]
    if not t then
        return nil, "unknown theme: " .. tostring(name)
    end

    local manager = lib and lib.ThemeManager
    if not manager then
        return nil, "library has no ThemeManager"
    end

    manager.BuiltInThemes = themes

    if type(manager.SetTheme) == "function" then
        local ok, err = pcall(manager.SetTheme, manager, name)
        if not ok then
            return nil, "SetTheme failed: " .. tostring(err)
        end
    else
        manager.SelectedTheme = t[1]
    end
    return true
end

return interface
