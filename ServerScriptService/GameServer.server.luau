-- ============================================================
-- Server.lua - Lógica del juego (solo servidor)
-- El cliente solo envía acciones; el servidor valida y calcula TODO.
-- ============================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local State = Remotes:WaitForChild("State")
local Notify = Remotes:WaitForChild("Notify")
local ClickFX = Remotes:WaitForChild("ClickFX")
local LeaderboardEvent = Remotes:WaitForChild("Leaderboard")

local sessions = {}        -- userId -> data
local clickTimes = {}      -- userId -> { timestamps }
local comboState = {}      -- userId -> { count, last }
local perkCache = {}       -- userId -> { Double = bool, VIP = bool, AutoClick = bool }
local nameCache = {}       -- userId -> nombre

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = deepCopy(child)
	end
	return result
end

-- DataStore falla en places locales sin publicar. Si pasa, usamos memoria
-- para que el juego siga siendo 100% jugable en Studio.
local memoryStore = {}
local memoryOrdered = {}

local function createStore(name)
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(name)
	end)
	if ok and result then
		return result
	end
	warn("[BobuxClicker] DataStore no disponible (place sin publicar). Usando guardado temporal.")
	return {
		GetAsync = function(_, key)
			return memoryStore[key]
		end,
		SetAsync = function(_, key, value)
			memoryStore[key] = deepCopy(value)
		end,
		UpdateAsync = function(_, key, transform)
			local updated = transform(memoryStore[key])
			memoryStore[key] = updated
			return updated
		end,
	}
end

local function createOrderedStore(name)
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(name)
	end)
	if ok and result then
		return result
	end
	return {
		SetAsync = function(_, key, value)
			memoryOrdered[key] = value
		end,
		GetSortedAsync = function(_, descending, count)
			local entries = {}
			for key, value in pairs(memoryOrdered) do
				table.insert(entries, { key = key, value = value })
			end
			table.sort(entries, function(a, b)
				return descending and a.value > b.value or a.value < b.value
			end)
			while #entries > count do
				table.remove(entries)
			end
			return { GetCurrentPage = function() return entries end }
		end,
	}
end

local store = createStore(Config.SaveKey)
local receiptStore = createStore(Config.SaveKey .. "_receipts")
local ordered = createOrderedStore(Config.LeaderboardKey)

local function fmt(value)
	value = math.floor(tonumber(value) or 0)
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local tier = 1
	while value >= 1000 and tier < #suffixes do
		value /= 1000
		tier += 1
	end
	return string.format("%.1f", value):gsub("%.0$", "") .. suffixes[tier]
end

local function todayId()
	return math.floor(os.time() / 86400)
end

-- ----------------------- Data -----------------------
local function defaultData()
	local data = {
		Coins = 0,
		TotalEarned = 0,
		TotalClicks = 0,
		Rebirths = 0,
		VIPBonus = false,
		Generators = {},
		Upgrades = { Click = 0, Generator = 0, Offline = 0 },
		Achievements = {},
		DailyStreak = 0,
		LastDaily = 0,
		TutorialSeen = false,
		LastSeen = os.time(),
	}
	for i = 1, #Config.Generators do
		data.Generators[i] = 0
	end
	return data
end

local function sanitize(raw)
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end

	data.Coins = math.max(0, math.floor(tonumber(raw.Coins) or 0))
	data.TotalEarned = math.max(data.Coins, math.floor(tonumber(raw.TotalEarned) or 0))
	data.TotalClicks = math.max(0, math.floor(tonumber(raw.TotalClicks) or 0))
	data.Rebirths = math.max(0, math.floor(tonumber(raw.Rebirths) or 0))
	data.VIPBonus = raw.VIPBonus == true
	data.TutorialSeen = raw.TutorialSeen == true
	data.DailyStreak = math.clamp(math.floor(tonumber(raw.DailyStreak) or 0), 0, Config.Daily.MaxStreak)
	data.LastDaily = math.max(0, math.floor(tonumber(raw.LastDaily) or 0))
	data.LastSeen = tonumber(raw.LastSeen) or os.time()

	if type(raw.Generators) == "table" then
		for i = 1, #Config.Generators do
			data.Generators[i] = math.max(0, math.floor(tonumber(raw.Generators[i]) or 0))
		end
	end

	if type(raw.Upgrades) == "table" then
		for key, upgrade in pairs(Config.Upgrades) do
			data.Upgrades[key] = math.clamp(
				math.floor(tonumber(raw.Upgrades[key]) or 0),
				0,
				upgrade.Max
			)
		end
	end

	if type(raw.Achievements) == "table" then
		for _, achievement in ipairs(Config.Achievements) do
			data.Achievements[achievement.Key] = raw.Achievements[achievement.Key] == true
		end
	end

	return data
end

local function loadData(player)
	local raw
	pcall(function()
		raw = store:GetAsync("p_" .. player.UserId)
	end)
	return sanitize(raw)
end

local function saveData(player)
	local data = sessions[player.UserId]
	if not data then
		return
	end
	data.LastSeen = os.time()
	local snapshot = deepCopy(data)
	pcall(function()
		store:SetAsync("p_" .. player.UserId, snapshot)
	end)
end

-- ----------------------- Perks / cálculos -----------------------
local function findGamepass(key)
	for _, pass in ipairs(Config.Gamepasses) do
		if pass.Key == key then
			return pass
		end
	end
	return nil
end

local function findGamepassById(id)
	for _, pass in ipairs(Config.Gamepasses) do
		if pass.Id == id then
			return pass
		end
	end
	return nil
end

local function findProduct(id)
	for _, product in ipairs(Config.Products) do
		if product.Id == id then
			return product
		end
	end
	return nil
end

local function getPerks(player)
	local cache = perkCache[player.UserId]
	if not cache then
		cache = {}
		perkCache[player.UserId] = cache
	end

	for _, pass in ipairs(Config.Gamepasses) do
		if cache[pass.Key] == nil then
			local owns = false
			if pass.Id > 0 then
				pcall(function()
					owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
				end)
			end
			cache[pass.Key] = owns
		end
	end

	return cache
end

local function generatorCost(index, owned)
	local gen = Config.Generators[index]
	return math.floor(gen.Cost * (gen.Growth ^ owned) + 0.5)
end

local function upgradeCost(key, level)
	local upgrade = Config.Upgrades[key]
	return math.floor(upgrade.BaseCost * (upgrade.Growth ^ level) + 0.5)
end

local function rebirthRequired(data)
	return Config.Rebirth.RequiredClicksBase + data.Rebirths * Config.Rebirth.RequiredClicksPerLevel
end

local function totalGenerators(data)
	local total = 0
	for _, amount in ipairs(data.Generators) do
		total += amount
	end
	return total
end

local function compute(data, perks)
	local multiplier = 1 + data.Rebirths * Config.Rebirth.MultiplierPerLevel
	if perks.Double then
		multiplier *= 2
	end
	if perks.VIP then
		multiplier *= 1.5
	end

	local clickPower = (Config.BaseClickPower + data.Upgrades.Click) * multiplier

	local baseCPS = 0
	for i, gen in ipairs(Config.Generators) do
		baseCPS += gen.CPS * data.Generators[i]
	end
	local cps = baseCPS * (1 + data.Upgrades.Generator * 0.25) * multiplier

	return {
		Multiplier = multiplier,
		ClickPower = clickPower,
		CPS = cps,
	}
end

local function addCoins(data, amount)
	amount = math.max(0, amount or 0)
	if amount ~= amount or amount == math.huge then
		return
	end
	data.Coins += amount
	data.TotalEarned += amount
end

local function currentCombo(userId)
	local cs = comboState[userId]
	if not cs then
		return 0, 1
	end
	if cs.count <= 0 or os.clock() - cs.last > Config.Combo.Window then
		return 0, 1
	end
	return cs.count, 1 + cs.count * Config.Combo.Step
end

local function sendState(player)
	local data = sessions[player.UserId]
	if not data then
		return
	end

	local perks = getPerks(player)
	local stats = compute(data, perks)
	local combo, comboMult = currentCombo(player.UserId)
	local payload = {
		Coins = math.floor(data.Coins),
		TotalEarned = math.floor(data.TotalEarned),
		TotalClicks = data.TotalClicks,
		Rebirths = data.Rebirths,
		Generators = deepCopy(data.Generators),
		Upgrades = deepCopy(data.Upgrades),
		ClickPower = stats.ClickPower,
		CPS = stats.CPS,
		Multiplier = stats.Multiplier,
		RebirthRequired = rebirthRequired(data),
		Perks = deepCopy(perks),
		GenCosts = {},
		UpCosts = {},
		Achievements = deepCopy(data.Achievements),
		DailyReady = data.LastDaily ~= todayId(),
		DailyStreak = data.DailyStreak,
		Combo = combo,
		ComboMultiplier = comboMult,
		TutorialSeen = data.TutorialSeen,
	}

	for i = 1, #Config.Generators do
		payload.GenCosts[i] = generatorCost(i, data.Generators[i])
	end
	for key in pairs(Config.Upgrades) do
		payload.UpCosts[key] = upgradeCost(key, data.Upgrades[key])
	end

	State:FireClient(player, payload)
end

-- ----------------------- Logros -----------------------
local achievementTests = {
	FirstClick = function(data) return data.TotalClicks >= 1 end,
	Click100 = function(data) return data.TotalClicks >= 100 end,
	Click1000 = function(data) return data.TotalClicks >= 1000 end,
	FirstGen = function(data) return totalGenerators(data) >= 1 end,
	Gen25 = function(data) return totalGenerators(data) >= 25 end,
	Earn10K = function(data) return data.TotalEarned >= 10000 end,
	Earn1M = function(data) return data.TotalEarned >= 1000000 end,
	Rebirth1 = function(data) return data.Rebirths >= 1 end,
	Rebirth5 = function(data) return data.Rebirths >= 5 end,
}

local function checkAchievements(player)
	local data = sessions[player.UserId]
	if not data then
		return
	end

	for _, achievement in ipairs(Config.Achievements) do
		if not data.Achievements[achievement.Key] then
			local test = achievementTests[achievement.Key]
			if test and test(data) then
				data.Achievements[achievement.Key] = true
				addCoins(data, achievement.Reward)
				Notify:FireClient(
					player,
					"LOGRO DESBLOQUEADO · " .. achievement.Name .. "  +" .. fmt(achievement.Reward),
					"achievement"
				)
				sendState(player)
			end
		end
	end
end

-- ----------------------- Acciones -----------------------
local function registerClick(player, data, respectSpam)
	local now = os.clock()

	if respectSpam then
		local times = clickTimes[player.UserId] or {}
		for i = #times, 1, -1 do
			if now - times[i] > 1 then
				table.remove(times, i)
			end
		end
		if #times >= 25 then
			return false
		end
		table.insert(times, now)
		clickTimes[player.UserId] = times
	end

	local cs = comboState[player.UserId] or { count = 0, last = 0 }
	if now - cs.last <= Config.Combo.Window then
		cs.count = math.min(cs.count + 1, Config.Combo.Max)
	else
		cs.count = 1
	end
	cs.last = now
	comboState[player.UserId] = cs

	local stats = compute(data, getPerks(player))
	local comboMult = 1 + cs.count * Config.Combo.Step
	local crit = math.random() < Config.Crit.Chance
	local critMult = crit and Config.Crit.Multiplier or 1
	local gained = stats.ClickPower * comboMult * critMult

	addCoins(data, gained)
	data.TotalClicks += 1

	sendState(player)
	ClickFX:FireAllClients(gained, player.Name, crit, cs.count, comboMult)
	checkAchievements(player)
	return true
end

local function handleClick(player)
	local data = sessions[player.UserId]
	if data then
		registerClick(player, data, true)
	end
end

local function buyGenerator(player, rawIndex, rawAmount)
	local index = tonumber(rawIndex)
	if not index or index < 1 or index > #Config.Generators then
		return
	end
	index = math.floor(index)

	local data = sessions[player.UserId]
	if not data then
		return
	end

	local desired = rawAmount == "max" and 500 or math.clamp(math.floor(tonumber(rawAmount) or 1), 1, 500)
	local gen = Config.Generators[index]
	local owned = data.Generators[index]
	local bought, spent = 0, 0

	for i = 1, desired do
		local cost = math.floor(gen.Cost * (gen.Growth ^ (owned + i - 1)) + 0.5)
		if cost <= 0 or cost ~= cost or cost == math.huge or data.Coins - spent < cost then
			break
		end
		spent += cost
		bought += 1
	end

	if bought == 0 then
		Notify:FireClient(player, "Te faltan monedas para comprar", "bad")
		return
	end

	data.Coins -= spent
	data.Generators[index] += bought
	Notify:FireClient(
		player,
		"+" .. bought .. " " .. gen.Name .. (bought > 1 and "es" or ""),
		"good"
	)
	sendState(player)
	checkAchievements(player)
end

local function buyUpgrade(player, key, rawAmount)
	local upgrade = Config.Upgrades[key]
	if not upgrade then
		return
	end

	local data = sessions[player.UserId]
	if not data then
		return
	end

	local level = data.Upgrades[key]
	if level >= upgrade.Max then
		Notify:FireClient(player, "¡Mejora al máximo!", "bad")
		return
	end

	local desired = rawAmount == "max" and upgrade.Max or math.clamp(math.floor(tonumber(rawAmount) or 1), 1, upgrade.Max)
	local bought, spent = 0, 0

	for i = 1, desired do
		local step = level + i - 1
		if step >= upgrade.Max then
			break
		end
		local cost = math.floor(upgrade.BaseCost * (upgrade.Growth ^ step) + 0.5)
		if cost <= 0 or cost ~= cost or cost == math.huge or data.Coins - spent < cost then
			break
		end
		spent += cost
		bought += 1
	end

	if bought == 0 then
		Notify:FireClient(player, "Te faltan monedas para mejorar", "bad")
		return
	end

	data.Coins -= spent
	data.Upgrades[key] += bought
	Notify:FireClient(player, upgrade.Name .. " +" .. bought, "good")
	sendState(player)
	checkAchievements(player)
end

local function claimDaily(player)
	local data = sessions[player.UserId]
	if not data then
		return
	end

	local today = todayId()
	if data.LastDaily == today then
		Notify:FireClient(player, "Ya reclamaste el regalo de hoy", "bad")
		return
	end

	local streak = (data.LastDaily == today - 1) and (data.DailyStreak + 1) or 1
	streak = math.min(streak, Config.Daily.MaxStreak)
	local reward = Config.Daily.Base + (streak - 1) * Config.Daily.PerStreak

	data.DailyStreak = streak
	data.LastDaily = today
	addCoins(data, reward)
	Notify:FireClient(player, "REGALO DIARIO · DÍA " .. streak .. "  +" .. fmt(reward), "daily")
	sendState(player)
	checkAchievements(player)
	saveData(player)
end

local function doRebirth(player)
	local data = sessions[player.UserId]
	if not data then
		return
	end

	local required = rebirthRequired(data)
	if data.TotalClicks < required or totalGenerators(data) < Config.Rebirth.MinGenerators then
		Notify:FireClient(player, "Necesitas " .. fmt(required) .. " clics y al menos 1 generador", "bad")
		return
	end

	data.Rebirths += 1
	data.Coins = 0
	data.TotalClicks = 0
	data.Generators = {}
	for i = 1, #Config.Generators do
		data.Generators[i] = 0
	end
	data.Upgrades = { Click = 0, Generator = 0, Offline = 0 }
	comboState[player.UserId] = nil

	local newMultiplier = 1 + data.Rebirths * Config.Rebirth.MultiplierPerLevel
	Notify:FireClient(player, "¡REBIRTH! Multiplicador x" .. string.format("%.1f", newMultiplier), "good")
	sendState(player)
	checkAchievements(player)
	saveData(player)
end

local function promptPurchase(player, key)
	for _, pass in ipairs(Config.Gamepasses) do
		if pass.Key == key then
			if pass.Id <= 0 then
				Notify:FireClient(player, "Ese pase todavía no tiene ID configurado", "bad")
				return
			end
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
			return
		end
	end

	for _, product in ipairs(Config.Products) do
		if product.Key == key then
			if product.Id <= 0 then
				Notify:FireClient(player, "Ese producto todavía no tiene ID configurado", "bad")
				return
			end
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, product.Id)
			end)
			return
		end
	end
end

Action.OnServerEvent:Connect(function(player, action)
	if type(action) ~= "table" then
		return
	end

	if action.type == "Ready" then
		sendState(player)
		checkAchievements(player)
	elseif action.type == "Click" then
		handleClick(player)
	elseif action.type == "BuyGenerator" then
		buyGenerator(player, action.index, action.amount)
	elseif action.type == "BuyUpgrade" then
		buyUpgrade(player, action.key, action.amount)
	elseif action.type == "Rebirth" then
		doRebirth(player)
	elseif action.type == "ClaimDaily" then
		claimDaily(player)
	elseif action.type == "TutorialDone" then
		local data = sessions[player.UserId]
		if data then
			data.TutorialSeen = true
			saveData(player)
		end
	elseif action.type == "Prompt" then
		promptPurchase(player, action.key)
	end
end)

-- ----------------------- Monetización -----------------------
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end

	local pass = findGamepassById(passId)
	if not pass then
		return
	end

	perkCache[player.UserId] = nil
	local data = sessions[player.UserId]
	if data and pass.Key == "VIP" and not data.VIPBonus then
		data.VIPBonus = true
		addCoins(data, 20000)
		Notify:FireClient(player, "¡Bienvenido VIP! +20.000 monedas", "good")
	end

	sendState(player)
	saveData(player)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local product = findProduct(receiptInfo.ProductId)
	local data = player and sessions[player.UserId] or nil

	if not player or not product or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, result = pcall(function()
		return receiptStore:UpdateAsync(receiptInfo.PurchaseId, function(alreadyGranted)
			if alreadyGranted then
				return "already"
			end
			return "granted"
		end)
	end)

	if not ok or (result ~= "granted" and result ~= "already") then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if result == "already" then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	addCoins(data, product.Coins)
	Notify:FireClient(player, "+" .. fmt(product.Coins) .. " monedas. ¡Gracias!", "good")
	sendState(player)
	checkAchievements(player)
	saveData(player)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ----------------------- Jugadores -----------------------
Players.PlayerAdded:Connect(function(player)
	perkCache[player.UserId] = {}
	clickTimes[player.UserId] = {}
	comboState[player.UserId] = { count = 0, last = 0 }

	local data = loadData(player)
	local perks = getPerks(player)
	local stats = compute(data, perks)

	local elapsed = math.clamp(os.time() - data.LastSeen, 0, Config.MaxOfflineSeconds + data.Upgrades.Offline * 1800)
	local offlineCoins = math.floor(stats.CPS * elapsed)
	if offlineCoins > 0 then
		addCoins(data, offlineCoins)
	end

	sessions[player.UserId] = data
	sendState(player)

	if offlineCoins > 0 then
		task.delay(1, function()
			if player.Parent then
				Notify:FireClient(player, "Ganaste " .. fmt(offlineCoins) .. " monedas mientras estabas fuera", "good")
			end
		end)
	end

	if perks.VIP and not data.VIPBonus then
		data.VIPBonus = true
		addCoins(data, 20000)
		sendState(player)
	end

	task.delay(1, function()
		if player.Parent then
			checkAchievements(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	sessions[player.UserId] = nil
	perkCache[player.UserId] = nil
	clickTimes[player.UserId] = nil
	comboState[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- ----------------------- Ingreso pasivo y visuals -----------------------
local generatorsFolder = Workspace:FindFirstChild("Generators")
local clickerModel = Workspace:FindFirstChild("Clicker")
local clickButton = clickerModel and clickerModel:FindFirstChild("Button")
local clickDetector = clickButton and clickButton:FindFirstChild("ClickDetector")

if clickDetector then
	clickDetector.MouseClick:Connect(function(player)
		handleClick(player)
	end)
end

local dailyStand = Workspace:FindFirstChild("DailyStand")
local dailyPad = dailyStand and dailyStand:FindFirstChild("Pad")
local dailyDetector = dailyPad and dailyPad:FindFirstChild("Detector")
if dailyDetector then
	dailyDetector.MouseClick:Connect(function(player)
		claimDaily(player)
	end)
end

-- Animación ambiente: aros del botón, portal y monedas flotantes
local clickRings = {}
if clickerModel then
	for index = 1, 4 do
		local ring = clickerModel:FindFirstChild("Ring" .. index)
		if ring then
			table.insert(clickRings, ring)
		end
	end
end

local portal = Workspace:FindFirstChild("RebirthPortal")
local portalRings = {}
if portal then
	for index = 1, 10 do
		local ring = portal:FindFirstChild("Ring" .. index)
		if ring then
			table.insert(portalRings, ring)
		end
	end
end

local floatingCoins = Workspace:FindFirstChild("FloatingCoins")
local coinParts = floatingCoins and floatingCoins:GetChildren() or {}

task.spawn(function()
	local clock = 0
	while true do
		task.wait(0.05)
		clock += 0.05

		for index, ring in ipairs(clickRings) do
			ring.CFrame = ring.CFrame * CFrame.Angles(0, (index % 2 == 0 and -1 or 1) * 0.012, 0)
		end
		for index, ring in ipairs(portalRings) do
			ring.CFrame = ring.CFrame * CFrame.Angles(0, 0.006, 0)
		end
		for index, coin in ipairs(coinParts) do
			local angle = clock * 0.7 + (index - 1) / #coinParts * math.pi * 2
			coin.Position = Vector3.new(
				math.cos(angle) * 10,
				4 + math.sin(clock * 1.6 + index) * 1.2,
				math.sin(angle) * 10
			)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		for userId, data in pairs(sessions) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				local perks = getPerks(player)

				-- Pase AUTOCLIC: 5 clics automáticos por segundo.
				if perks.AutoClick then
					local power = compute(data, perks).ClickPower
					addCoins(data, power * 5)
					data.TotalClicks += 5
					sendState(player)
					ClickFX:FireAllClients(power * 5, player.Name, false, 0, 1)
					checkAchievements(player)
				end

				local cps = compute(data, perks).CPS
				if cps > 0 then
					addCoins(data, cps)
					sendState(player)
				end
			end
		end

		-- El combo se apaga solo cuando dejas de clicar.
		for userId, cs in pairs(comboState) do
			if cs.count > 0 and os.clock() - cs.last > Config.Combo.Window then
				cs.count = 0
				local player = Players:GetPlayerByUserId(userId)
				if player then
					sendState(player)
				end
			end
		end

		-- Visuales de los generadores según cuántos haya comprado la comunidad
		if generatorsFolder then
			local totals = {}
			for i = 1, #Config.Generators do
				totals[i] = 0
			end
			for _, data in pairs(sessions) do
				for i = 1, #Config.Generators do
					totals[i] += data.Generators[i]
				end
			end

			for i = 1, #Config.Generators do
				local model = generatorsFolder:FindFirstChild("Generator" .. i)
				local core = model and model:FindFirstChild("Core")
				if core then
					core.Transparency = totals[i] > 0 and 0.05 or 0.75
					core.Size = Vector3.new(2.2, 1.2 + math.min(totals[i], 12) * 0.18, 2.2)
					core.CFrame = core.CFrame * CFrame.Angles(0, 0.04, 0)
				end
			end
		end
	end
end)

-- ----------------------- Leaderboard -----------------------
local function updateLeaderboard()
	for userId, data in pairs(sessions) do
		pcall(function()
			ordered:SetAsync(tostring(userId), math.floor(data.TotalEarned))
		end)
	end

	local ok, pages = pcall(function()
		return ordered:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then
		return
	end

	local entries = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key)
		if userId then
			local name = nameCache[userId]
			if not name then
				pcall(function()
					name = Players:GetNameFromUserIdAsync(userId)
				end)
				nameCache[userId] = name or ("Jugador " .. tostring(userId))
			end
			table.insert(entries, {
				Name = nameCache[userId],
				Value = math.floor(entry.value),
			})
		end
	end

	LeaderboardEvent:FireAllClients(entries)
end

task.spawn(function()
	task.wait(5)
	updateLeaderboard()
	while true do
		task.wait(60)
		updateLeaderboard()
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

print("[BobuxClicker] Servidor listo ✔")
