local interface = {}

local baseurl = "https://raw.githubusercontent.com/StarLight-scrpit/StarLight-Asset/main/UI/"

local available = {
    ["LinoriaLib"] = true,
    ["Obsidan"] = true,
    ["OrionLib-Modded"] = true,
    ["WindUI"] = true,
}

local schemeIndexes = {
    "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor",
}

local builtInThemes = {
    ["Default"]      = { 1,  { FontColor = "ffffff", MainColor = "191919", AccentColor = "7d55ff", BackgroundColor = "0f0f0f", OutlineColor = "282828", BackgroundImage = "" } },
    ["BBot"]         = { 2,  { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414", BackgroundImage = "" } },
    ["Fatality"]     = { 3,  { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d", BackgroundImage = "" } },
    ["Jester"]       = { 4,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737", BackgroundImage = "" } },
    ["Mint"]         = { 5,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737", BackgroundImage = "" } },
    ["Tokyo Night"]  = { 6,  { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232", BackgroundImage = "" } },
    ["Ubuntu"]       = { 7,  { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919", BackgroundImage = "" } },
    ["Quartz"]       = { 8,  { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f", BackgroundImage = "" } },
    ["Nord"]         = { 9,  { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a", BackgroundImage = "" } },
    ["Dracula"]      = { 10, { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4", BackgroundImage = "" } },
    ["Monokai"]      = { 11, { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e", BackgroundImage = "" } },
    ["Gruvbox"]      = { 12, { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945", BackgroundImage = "" } },
    ["Solarized"]    = { 13, { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75", BackgroundImage = "" } },
    ["Catppuccin"]   = { 14, { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268", BackgroundImage = "" } },
    ["One Dark"]     = { 15, { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370", BackgroundImage = "" } },
    ["Cyberpunk"]    = { 16, { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e", BackgroundImage = "" } },
    ["Oceanic Next"] = { 17, { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46", BackgroundImage = "" } },
    ["Material"]     = { 18, { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242", BackgroundImage = "" } },
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

    local url = baseurl .. name .. ".luau"
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
    for k in pairs(builtInThemes) do
        out[#out + 1] = k
    end
    table.sort(out)
    return out
end

function interface.getTheme(name)
    local t = builtInThemes[name]
    if not t then
        return nil
    end
    return t[2], t[1]
end

function interface.setTheme(lib, name)
    local t = builtInThemes[name]
    if not t then
        return nil, "unknown theme: " .. tostring(name)
    end

    local data = t[2]
    if not lib or not lib.Scheme or not lib.Options then
        return nil, "invalid library"
    end

    if data.BackgroundImage and data.BackgroundImage ~= "" then
        if type(lib.SetBackgroundImage) == "function" then
            pcall(lib.SetBackgroundImage, lib, data.BackgroundImage)
        end
    end

    for _, index in ipairs(schemeIndexes) do
        local hex = data[index]
        if not hex or hex == "" then
            continue
        end

        local ok, color = pcall(Color3.fromHex, hex)
        if not ok then
            continue
        end

        lib.Scheme[index] = color

        local element = lib.Options[index]
        if element and type(element.SetValue) == "function" then
            element:SetValue(color)
        end
    end

    if type(lib.UpdateColorsUsingRegistry) == "function" then
        pcall(lib.UpdateColorsUsingRegistry, lib)
    end

    return true
end

return interface
