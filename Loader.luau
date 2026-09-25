local BASE_URL = "https://raw.githubusercontent.com/StarLight-scrpit/StarLight-Asset/refs/heads/main/Scrpit/"
local files = {"AntiLag.luau", "EspLibrary.luau", "NotifyLibrary.luau"}
local loaded = {}

for _, file in ipairs(files) do
    local url = BASE_URL .. file
    local success, result = pcall(function()
        local source = game:HttpGet(url)
        local chunk = loadstring(source, file)
        if chunk then
            return chunk()
        end
    end)
    if success then
        loaded[file] = result
        print("[Loader] Loaded: " .. file)
    else
        warn("[Loader] Failed: " .. file .. " | " .. tostring(result))
    end
end

local NotifyLibrary = loaded["NotifyLibrary.luau"]
if NotifyLibrary then
    local ok, err = pcall(function()
        NotifyLibrary:Notify("Abysall", "Loader ready. ESP and AnitLag are commented out.", 5)
    end)
    if not ok then
        warn("[Notify] Failed: " .. tostring(err))
    end
end

-- AnitLag usage example (commented out)
-- local AnitLag = loaded["AnitLag.Luau"]
-- if AnitLag then
--     AnitLag:Start()
-- end

--[[
ESP player ESP section (commented out by default)
Uncomment this block to enable the universal player ESP.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local EspLibrary = loaded["EspLibrary.luau"]

local espSettings = {
    Name = true,
    Health = true,
    Distance = true,
    Box = true,
    Tracer = true,
    Color = Color3.fromRGB(255, 80, 80),
    TextColor = Color3.fromRGB(255, 255, 255),
}

local function isAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    if not isAlive(player) then return end
    local ok, err = pcall(function()
        EspLibrary:AddPlayer(player, espSettings)
    end)
    if not ok then
        warn("[ESP] Add failed: " .. player.Name .. " | " .. tostring(err))
    end
end

local function removePlayer(player)
    pcall(function()
        EspLibrary:RemovePlayer(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

local function hookCharacter(player)
    if player == LocalPlayer then return end
    local char = player.Character or player.CharacterAdded:Wait()
    task.wait(0.5)
    if isAlive(player) then
        removePlayer(player)
        addPlayer(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(hookCharacter, player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if isAlive(player) then
            removePlayer(player)
            addPlayer(player)
        end
    end)
end)
]]
