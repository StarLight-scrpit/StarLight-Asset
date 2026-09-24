local HttpService = game:GetService("HttpService")

local TranslationSettings = {}

local CONFIG = {
	BaseUrl = "https://raw.githubusercontent.com/StarLight-scrpit/StarLight-Asset/main/Translate/",
	ContentsUrl = "https://api.github.com/repos/StarLight-scrpit/StarLight-Asset/contents/Translate",
	DefaultLanguage = "en",
	FallbackLanguage = "en",
	UseCache = true,
}

local LANGUAGES = {
	en = "English",
	pt = "Portugues",
	zh = "Chinese",
}

local cache = {}
local listeners = {}
local currentGame = nil
local currentLanguage = CONFIG.DefaultLanguage
local discoveredGames = {}

local function fireChanged(game, newLanguage, oldLanguage)
	for _, callback in ipairs(listeners) do
		local ok, err = pcall(callback, game, newLanguage, oldLanguage)
		if not ok then
			warn(string.format("[TranslationSettings] Callback error: %s", tostring(err)))
		end
	end
end

local function buildUrl(game, language)
	return CONFIG.BaseUrl .. game .. "/" .. language .. ".luau"
end

local function fetchRemote(game, language)
	local url = buildUrl(game, language)
	local ok, response = pcall(function()
		return HttpService:GetAsync(url, true)
	end)

	if not ok or type(response) ~= "string" or response == "" then
		warn(string.format("[TranslationSettings] Failed to fetch %s/%s from %s", game, language, url))
		return nil
	end

	local chunk = loadstring(response)
	if type(chunk) ~= "function" then
		warn(string.format("[TranslationSettings] Failed to compile %s/%s", game, language))
		return nil
	end

	local success, result = pcall(chunk)
	if not success or type(result) ~= "table" then
		warn(string.format("[TranslationSettings] %s/%s did not return a table", game, language))
		return nil
	end

	return result
end

local function discoverGames()
	local ok, response = pcall(function()
		return HttpService:GetAsync(CONFIG.ContentsUrl, true)
	end)

	if not ok or type(response) ~= "string" or response == "" then
		warn("[TranslationSettings] Failed to discover games from GitHub Contents API")
		return {}
	end

	local success, decoded = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not success or type(decoded) ~= "table" then
		warn("[TranslationSettings] Failed to decode GitHub Contents response")
		return {}
	end

	local games = {}
	for _, entry in ipairs(decoded) do
		if type(entry) == "table" and entry.type == "dir" and type(entry.name) == "string" then
			table.insert(games, entry.name)
		end
	end

	table.sort(games)
	return games
end

function TranslationSettings.getGames()
	return discoveredGames
end

function TranslationSettings.refreshGames()
	discoveredGames = discoverGames()
	return discoveredGames
end

function TranslationSettings.load(game, language, force)
	if type(game) ~= "string" or game == "" then
		return false
	end
	if type(language) ~= "string" or LANGUAGES[language] == nil then
		warn(string.format("[TranslationSettings] Unknown language: %s", tostring(language)))
		return false
	end

	if CONFIG.UseCache and not force and cache[game] and cache[game][language] then
		return true
	end

	local data = fetchRemote(game, language)
	if not data then
		return false
	end

	cache[game] = cache[game] or {}
	cache[game][language] = data
	return true
end

function TranslationSettings.loadAll(force)
	local results = {}
	for _, game in ipairs(discoveredGames) do
		results[game] = {}
		for code in pairs(LANGUAGES) do
			results[game][code] = TranslationSettings.load(game, code, force)
		end
	end
	return results
end

function TranslationSettings.register(game, language, translationTable)
	if type(game) ~= "string" or type(language) ~= "string" or type(translationTable) ~= "table" then
		return false
	end
	cache[game] = cache[game] or {}
	cache[game][language] = translationTable
	return true
end

function TranslationSettings.setGame(game)
	if type(game) ~= "string" or game == "" then
		return false
	end
	if currentGame == game then
		return true
	end
	currentGame = game
	fireChanged(currentGame, currentLanguage, currentLanguage)
	return true
end

function TranslationSettings.getGame()
	return currentGame
end

function TranslationSettings.setLanguage(language)
	if type(language) ~= "string" or LANGUAGES[language] == nil then
		warn(string.format("[TranslationSettings] Unknown language: %s", tostring(language)))
		return false
	end

	if not (cache[currentGame] and cache[currentGame][language]) then
		if not TranslationSettings.load(currentGame, language) then
			return false
		end
	end

	if currentLanguage == language then
		return true
	end

	local previous = currentLanguage
	currentLanguage = language
	fireChanged(currentGame, language, previous)
	return true
end

function TranslationSettings.getLanguage()
	return currentLanguage
end

function TranslationSettings.getLanguageName()
	return LANGUAGES[currentLanguage] or currentLanguage
end

function TranslationSettings.getLanguages()
	local list = {}
	for code, name in pairs(LANGUAGES) do
		table.insert(list, { code = code, name = name })
	end
	table.sort(list, function(a, b)
		return a.code < b.code
	end)
	return list
end

function TranslationSettings.get(key)
	if key == nil then
		return ""
	end

	local active = cache[currentGame]
	if active and active[currentLanguage] and active[currentLanguage][key] ~= nil then
		return active[currentLanguage][key]
	end

	if active and active[CONFIG.FallbackLanguage] and active[CONFIG.FallbackLanguage][key] ~= nil then
		return active[CONFIG.FallbackLanguage][key]
	end

	return key
end

function TranslationSettings.getConfig()
	return CONFIG
end

function TranslationSettings.setBaseUrl(url)
	if type(url) ~= "string" or url == "" then
		return false
	end
	CONFIG.BaseUrl = url
	return true
end

function TranslationSettings.clearCache()
	cache = {}
end

function TranslationSettings.onChanged(callback)
	table.insert(listeners, callback)
	return function()
		for index, entry in ipairs(listeners) do
			if entry == callback then
				table.remove(listeners, index)
				break
			end
		end
	end
end

discoveredGames = discoverGames()

if #discoveredGames > 0 then
	currentGame = discoveredGames[1]
	TranslationSettings.load(currentGame, currentLanguage)
end

return TranslationSettings
