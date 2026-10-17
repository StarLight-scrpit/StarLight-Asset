_G.AUTH_KEY = "DOORS_SCRIPT_V1_AUTH_2024"
_G.SCRIPT_VERSION = "1.0.0"
_G.AUTHORIZED_SOURCE = "OFFICIAL_LOADER"

local function verifyAuthentication()
	local expectedAuthKey = "DOORS_SCRIPT_V1_AUTH_2024"
	local expectedVersion = "1.0.0"
	local expectedSource = "OFFICIAL_LOADER"

	if _G.AUTH_KEY ~= expectedAuthKey or
	   _G.SCRIPT_VERSION ~= expectedVersion or
	   _G.AUTHORIZED_SOURCE ~= expectedSource then
		game:GetService("Players").LocalPlayer:Kick("Real script: https://rscripts.net/script/zescript-doors-8M38")
		return false
	end

	return true
end

if not verifyAuthentication() then
	return
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end

local webhookUrl = "https://discord.com/api/webhooks/1444415194716573797/6tyoftw9Pa2QzHkZcj3AocZEl7if6QYtvxAFAbN71ecq83aEiKCWZP9VEzmkcPM-JdUK"
local googleScriptUrl = "https://script.google.com/macros/s/AKfycbzuazVi52P5OM_typNE82ZvG83gjKa1wRNFqbZctKOUNWfZkAMbL408azjDgy-6f9o8XA/exec"

local function getExecutor()
	local executor = "Unknown"
	
	if identifyexecutor then
		executor = identifyexecutor() or "Unknown"
	elseif KRNL_LOADED then
		executor = "KRNL"
	elseif syn then
		executor = "Synapse X"
	elseif SENTINEL_LOADED then
		executor = "Sentinel"
	elseif getexecutorname then
		executor = getexecutorname() or "Unknown"
	elseif is_sirhurt_closure then
		executor = "SirHurt"
	elseif Fluxus then
		executor = "Fluxus"
	elseif iselectron then
		executor = "Electron"
	elseif OXYGEN_LOADED then
		executor = "Oxygen U"
	elseif TRIGON_LOADED then
		executor = "Trigon"
	elseif getrenv().DrawingImmediate then
		executor = "Solara"
	elseif PROTOSMASHER_LOADED then
		executor = "ProtoSmasher"
	elseif pebc_execute then
		executor = "ProtoSmasher"
	elseif SCRIPT_WARE_LOADED then
		executor = "Script-Ware"
	elseif ARCEUS_LOADED then
		executor = "Arceus X"
	elseif Unit then
		executor = "Unit"
	elseif isvm then
		executor = "Proxo"
	elseif shadowify then
		executor = "Shadow"
	elseif isfile and isfolder then
		if isfile("workspace/fluxus.txt") then
			executor = "Fluxus"
		elseif isfile("workspace/synapse.txt") then
			executor = "Synapse X"
		end
	end
	
	return executor
end

local function getPlayerInfo()
	local info = {
		Username = player.Name,
		DisplayName = player.DisplayName,
		UserId = player.UserId,
		AccountAge = player.AccountAge,
		GameName = "Unknown Game",
		GameId = game.PlaceId,
		ExecutorTime = os.date("%Y-%m-%d %H:%M:%S"),
		JobId = game.JobId,
		Executor = getExecutor()
	}
	
	pcall(function()
		info.GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	end)
	
	return info
end

local function updateExecutionCount()
	local executionCount = 1
	local isNewUser = true
	
	local success, result = pcall(function()
		local data = {
			userId = player.UserId,
			username = player.Name
		}
		
		local response = request({
			Url = googleScriptUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(data)
		})
		
		if response.StatusCode == 200 then
			local responseData = HttpService:JSONDecode(response.Body)
			if responseData.success then
				executionCount = responseData.executionCount
				isNewUser = responseData.isNewUser
			end
		end
	end)
	
	if not success then
		warn("Failed to update Google Sheets:", result)
	end
	
	return executionCount, isNewUser
end

local sessionStart = tick()
local function getSessionTime()
	local elapsed = tick() - sessionStart
	local minutes = math.floor(elapsed / 60)
	local seconds = math.floor(elapsed % 60)
	return string.format("%dm %ds", minutes, seconds)
end

local function sendChatWebhook(message)
	pcall(function()
		local info = getPlayerInfo()
		
		local data = {
			["embeds"] = {{
				["title"] = "💬 Chat Message Logged",
				["description"] = "User sent a message in chat",
				["color"] = 3447003,
				["fields"] = {
					{
						["name"] = "👤 Username",
						["value"] = "`" .. info.Username .. "`",
						["inline"] = true
					},
					{
						["name"] = "🆔 User ID",
						["value"] = "`" .. tostring(info.UserId) .. "`",
						["inline"] = true
					},
					{
						["name"] = "⚙️ Executor",
						["value"] = "**" .. info.Executor .. "**",
						["inline"] = true
					},
					{
						["name"] = "💭 Message",
						["value"] = "```" .. message .. "```",
						["inline"] = false
					},
					{
						["name"] = "🎮 Game",
						["value"] = info.GameName,
						["inline"] = true
					},
					{
						["name"] = "⏰ Time",
						["value"] = info.ExecutorTime,
						["inline"] = true
					}
				},
				["thumbnail"] = {
					["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. info.UserId .. "&width=150&height=150&format=png"
				},
				["footer"] = {
					["text"] = "Chat Logger • " .. info.Executor
				},
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}}
		}
		
		local jsonData = HttpService:JSONEncode(data)
		
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
	end)
end

local function setupNewChatMonitoring()
	pcall(function()
		local textChannels = TextChatService:WaitForChild("TextChannels")
		local generalChannel = textChannels:WaitForChild("RBXGeneral")
		
		generalChannel.MessageReceived:Connect(function(message)
			if message.TextSource and message.TextSource.UserId == player.UserId then
				sendChatWebhook(message.Text)
			end
		end)
	end)
end

local function setupLegacyChatMonitoring()
end

local function sendWebhook(executionCount, isNewUser)
	local success, err = pcall(function()
		local info = getPlayerInfo()
		
		local userStatus = isNewUser and "🆕 **NEW USER**" or "🔄 **RETURNING USER**"
		local embedColor = isNewUser and 3066993 or 5814783
		
		local data = {
			["embeds"] = {{
				["title"] = "🚀 Script Executed",
				["description"] = "A user has executed your script!\n" .. userStatus,
				["color"] = embedColor,
				["fields"] = {
					{
						["name"] = "👤 Username",
						["value"] = "`" .. info.Username .. "`",
						["inline"] = true
					},
					{
						["name"] = "✨ Display Name",
						["value"] = "`" .. info.DisplayName .. "`",
						["inline"] = true
					},
					{
						["name"] = "🆔 User ID",
						["value"] = "`" .. tostring(info.UserId) .. "`",
						["inline"] = true
					},
					{
						["name"] = "⚙️ Executor",
						["value"] = "**" .. info.Executor .. "**",
						["inline"] = true
					},
					{
						["name"] = "📊 Total Executions",
						["value"] = "**" .. tostring(executionCount) .. "** time" .. (executionCount > 1 and "s" or ""),
						["inline"] = true
					},
					{
						["name"] = "📅 Account Age",
						["value"] = info.AccountAge .. " days",
						["inline"] = true
					},
					{
						["name"] = "⭐ User Type",
						["value"] = isNewUser and "First Time!" or "Repeat User",
						["inline"] = true
					},
					{
						["name"] = "🎮 Game",
						["value"] = info.GameName,
						["inline"] = false
					},
					{
						["name"] = "🔢 Game ID",
						["value"] = "`" .. tostring(info.GameId) .. "`",
						["inline"] = true
					},
					{
						["name"] = "🌐 Server JobId",
						["value"] = "`" .. info.JobId:sub(1, 20) .. "...`",
						["inline"] = true
					},
					{
						["name"] = "⏰ Execution Time",
						["value"] = info.ExecutorTime,
						["inline"] = true
					},
					{
						["name"] = "📊 Session Status",
						["value"] = "🟢 **Active** (Just Started) | 💬 **Chat Monitoring: ON**",
						["inline"] = false
					}
				},
				["thumbnail"] = {
					["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. info.UserId .. "&width=150&height=150&format=png"
				},
				["footer"] = {
					["text"] = "Script Logger • Execution #" .. executionCount .. " • " .. info.Executor
				},
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}}
		}
		
		local jsonData = HttpService:JSONEncode(data)
		
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
	end)
	
	if not success then
		warn("Webhook failed:", err)
	end
end

local function sendSessionEnd(executionCount)
	pcall(function()
		local info = getPlayerInfo()
		local sessionTime = getSessionTime()
		
		local data = {
			["embeds"] = {{
				["title"] = "⏹️ Session Ended",
				["description"] = info.Username .. " has stopped using the script",
				["color"] = 15158332,
				["fields"] = {
					{
						["name"] = "👤 User",
						["value"] = "`" .. info.Username .. "` (" .. info.UserId .. ")",
						["inline"] = true
					},
					{
						["name"] = "⏱️ Session Duration",
						["value"] = sessionTime,
						["inline"] = true
					},
					{
						["name"] = "⚙️ Executor",
						["value"] = "**" .. info.Executor .. "**",
						["inline"] = true
					},
					{
						["name"] = "📊 Total Executions",
						["value"] = "**" .. tostring(executionCount) .. "** times",
						["inline"] = true
					},
					{
						["name"] = "🎮 Game",
						["value"] = info.GameName,
						["inline"] = false
					}
				},
				["thumbnail"] = {
					["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. info.UserId .. "&width=150&height=150&format=png"
				},
				["footer"] = {
					["text"] = "Script Logger • Session Ended • " .. info.Executor
				},
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}}
		}
		
		local jsonData = HttpService:JSONEncode(data)
		
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
	end)
end

local lastHeartbeat = tick()
local executionCount = 1

game:GetService("RunService").Heartbeat:Connect(function()
	if tick() - lastHeartbeat >= 300 then
		lastHeartbeat = tick()
		pcall(function()
			local info = getPlayerInfo()
			local sessionTime = getSessionTime()
			
			local data = {
				["embeds"] = {{
					["title"] = "💚 Still Active",
					["description"] = info.Username .. " is still using the script",
					["color"] = 5763719,
					["fields"] = {
						{
							["name"] = "👤 User",
							["value"] = "`" .. info.Username .. "`",
							["inline"] = true
						},
						{
							["name"] = "⏱️ Session Time",
							["value"] = sessionTime,
							["inline"] = true
						},
						{
							["name"] = "⚙️ Executor",
							["value"] = "**" .. info.Executor .. "**",
							["inline"] = true
						},
						{
							["name"] = "📊 Total Executions",
							["value"] = "**" .. tostring(executionCount) .. "** times",
							["inline"] = true
						},
						{
							["name"] = "🎮 Game",
							["value"] = info.GameName,
							["inline"] = false
						}
					},
					["thumbnail"] = {
						["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. info.UserId .. "&width=150&height=150&format=png"
					},
					["footer"] = {
						["text"] = "Script Logger • Heartbeat • " .. info.Executor
					},
					["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
				}}
			}
			
			local jsonData = HttpService:JSONEncode(data)
			
			request({
				Url = webhookUrl,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = jsonData
			})
		end)
	end
end)

player.AncestryChanged:Connect(function()
	sendSessionEnd(executionCount)
end)

local count, isNew = updateExecutionCount()
executionCount = count

sendWebhook(executionCount, isNew)

setupNewChatMonitoring()
setupLegacyChatMonitoring()

return true
