StarLight = StarLight or {}
StarLight.BaseUrl = "https://raw.githubusercontent.com/StarLight-scrpit/StarLight-Asset/refs/heads/main/"
StarLight.DefaultLocale = "en"

local function SafeLoad(url, label)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[StarLight/Translator] Failed: " .. (label or url))
        return nil
    end
    return result
end

local GameMap = {
    [920587237]   = "Doors",
    [11660010588] = "Forsaken",
}

local Translator = {}

Translator.SupportedLocales = {
    ["en"]    = true,
    ["pt"]    = true,
    ["zh-cn"] = true,
    ["zh-tw"] = true,
}

function Translator:_resolveGame()
    if self.manualGame then
        return self.manualGame
    end
    return GameMap[game.PlaceId]
end

function Translator:_load(locale)
    if not self.SupportedLocales[locale] then
        warn("[StarLight/Translator] Unsupported locale: " .. tostring(locale))
        return {}
    end

    local gameName = self:_resolveGame()
    if not gameName then
        warn("[StarLight/Translator] Unknown PlaceId: " .. tostring(game.PlaceId))
        return {}
    end

    local url = StarLight.BaseUrl .. "Translate/" .. gameName .. "/" .. locale .. ".luau"
    return SafeLoad(url, "Translate/" .. gameName .. "/" .. locale) or {}
end

function Translator:init(defaultLocale)
    self.currentLocale = defaultLocale or StarLight.DefaultLocale
    self.table         = self:_load(self.currentLocale)
    return self
end

function Translator:t(key)
    local value = self.table[key]
    if value == nil then
        warn("[StarLight/Translator] Missing key: " .. tostring(key))
        return key
    end
    return value
end

function Translator:has(key)
    return self.table[key] ~= nil
end

function Translator:tOrDefault(key, fallback)
    local value = self.table[key]
    if value == nil then
        return fallback
    end
    return value
end

function Translator:setLocale(locale)
    if not self.SupportedLocales[locale] then
        return false
    end
    self.currentLocale = locale
    self.table         = self:_load(locale)
    return true
end

function Translator:setGame(gameName)
    self.manualGame = gameName
    self.table      = self:_load(self.currentLocale)
end

function Translator:getLocale()
    return self.currentLocale
end

function Translator:getGame()
    return self:_resolveGame() or "Unknown"
end

function Translator:getLocales()
    local list = {}
    for locale in pairs(self.SupportedLocales) do
        table.insert(list, locale)
    end
    table.sort(list)
    return list
end

return function(defaultLocale)
    return Translator:init(defaultLocale)
end
