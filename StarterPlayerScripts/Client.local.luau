-- ============================================================
-- Client.lua - Interfaz estilo simulador de Roblox
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local State = Remotes:WaitForChild("State")
local Notify = Remotes:WaitForChild("Notify")
local ClickFX = Remotes:WaitForChild("ClickFX")
local Leaderboard = Remotes:WaitForChild("Leaderboard")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_HEAVY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)

local C = {
	bg = Color3.fromRGB(9, 12, 24),
	panel = Color3.fromRGB(20, 26, 46),
	card = Color3.fromRGB(28, 36, 62),
	cyan = Color3.fromRGB(70, 220, 255),
	pink = Color3.fromRGB(255, 75, 160),
	gold = Color3.fromRGB(255, 205, 70),
	green = Color3.fromRGB(85, 255, 175),
	purple = Color3.fromRGB(175, 110, 255),
	red = Color3.fromRGB(255, 100, 120),
	text = Color3.fromRGB(240, 245, 255),
	muted = Color3.fromRGB(150, 165, 200),
}

local GEN_ICONS = { "✦", "⚙", "⬢", "◆", "★", "✧" }
local UP_ICONS = { Click = "✚", Generator = "⚡", Offline = "☕" }
local UP_KEYS = { "Click", "Generator", "Offline" }
local UP_COLORS = { Click = C.gold, Generator = C.cyan, Offline = C.purple }
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function fmt(value)
	value = tonumber(value) or 0
	local negative = value < 0
	value = math.abs(value)
	local tier = 1
	while value >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	local text
	if value >= 100 then
		text = string.format("%.0f", value)
	elseif value >= 10 then
		text = string.format("%.1f", value)
	else
		text = string.format("%.2f", value)
	end
	return (negative and "-" or "") .. text .. SUFFIXES[tier]
end

local function new(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		inst[key] = value
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function gradient(parent, from, to, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, from),
		ColorSequenceKeypoint.new(1, to),
	})
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

local function tween(instance, time, props, style, direction)
	return TweenService:Create(instance, TweenInfo.new(
		time,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	), props)
end

local function hover(button, normal, highlighted)
	button.MouseEnter:Connect(function()
		tween(button, 0.12, { BackgroundColor3 = highlighted }):Play()
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.12, { BackgroundColor3 = normal }):Play()
	end)
end

-- ----------------------- GUI base -----------------------
local gui = new("ScreenGui", {
	Name = "SimulatorGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, playerGui)

local uiScale = new("UIScale", { Scale = 1 }, gui)
local camera = Workspace.CurrentCamera
if camera then
	local function resize()
		local vp = camera.ViewportSize
		uiScale.Scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1)
	end
	resize()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end

-- GUI separada para el texto flotante (coordenadas reales del mouse)
local fxGui = new("ScreenGui", {
	Name = "ClickFxGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, playerGui)

local ui = {}
local latest = {
	Coins = 0, CPS = 0, Multiplier = 1, ClickPower = 1,
	TotalEarned = 0, TotalClicks = 0, Rebirths = 0,
	Generators = {}, Upgrades = {}, GenCosts = {}, UpCosts = {},
	Perks = {}, Achievements = {},
	DailyReady = true, DailyStreak = 0,
	Combo = 0, ComboMultiplier = 1, TutorialSeen = false,
}

-- ----------------------- Barra superior -----------------------
local top = new("Frame", {
	Size = UDim2.new(1, -24, 0, 70),
	Position = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.08,
}, gui)
corner(top, 18)
stroke(top, Color3.fromRGB(60, 80, 130), 1.5)
gradient(top, Color3.fromRGB(24, 32, 58), Color3.fromRGB(14, 18, 36), 0)

new("TextLabel", {
	Size = UDim2.new(0, 250, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	BackgroundTransparency = 1,
	Text = "BOBUX  CLICKER",
	TextColor3 = C.gold,
	TextSize = 22,
	FontFace = FONT_HEAVY,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local function pill(parent, x, width, color, icon)
	local frame = new("Frame", {
		Size = UDim2.new(0, width, 0, 44),
		Position = UDim2.new(0, x, 0, 13),
		BackgroundColor3 = Color3.fromRGB(12, 16, 32),
	}, parent)
	corner(frame, 22)
	stroke(frame, color, 1.5)
	new("TextLabel", {
		Size = UDim2.new(0, 34, 1, 0),
		Position = UDim2.new(0, 9, 0, 0),
		BackgroundTransparency = 1,
		Text = icon,
		TextColor3 = color,
		TextSize = 21,
		FontFace = FONT_HEAVY,
	}, frame)
	return frame
end

local function pillText(parent, x, width, color, icon, text, size)
	local frame = pill(parent, x, width, color, icon)
	local label = new("TextLabel", {
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = C.text,
		TextSize = size or 19,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)
	return frame, label
end

_, ui.coins = pillText(top, 268, 185, C.gold, "◆", "0", 20)
_, ui.cps = pillText(top, 463, 185, C.cyan, "⚡", "0/s", 19)
_, ui.mult = pillText(top, 658, 175, C.purple, "✦", "x1.0", 19)
_, ui.rebirths = pillText(top, 843, 155, C.pink, "♻", "RB 0", 17)

ui.achButton = new("TextButton", {
	Size = UDim2.new(0, 44, 0, 48),
	Position = UDim2.new(1, -254, 0, 11),
	BackgroundColor3 = Color3.fromRGB(70, 50, 20),
	TextColor3 = C.gold,
	Text = "★",
	TextSize = 22,
	FontFace = FONT_HEAVY,
}, top)
corner(ui.achButton, 13)
stroke(ui.achButton, C.gold, 1.5)
hover(ui.achButton, Color3.fromRGB(70, 50, 20), Color3.fromRGB(105, 75, 28))

ui.shopButton = new("TextButton", {
	Size = UDim2.new(0, 186, 0, 48),
	Position = UDim2.new(1, -202, 0, 11),
	BackgroundColor3 = C.gold,
	TextColor3 = Color3.fromRGB(35, 22, 0),
	Text = "★  TIENDA ROBUX",
	TextSize = 15,
	FontFace = FONT_HEAVY,
}, top)
corner(ui.shopButton, 14)
stroke(ui.shopButton, Color3.fromRGB(255, 240, 170), 2)
gradient(ui.shopButton, Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 150, 60), 90)

-- ----------------------- Regalo diario -----------------------
local daily = new("Frame", {
	Size = UDim2.new(0, 300, 0, 46),
	Position = UDim2.new(0.5, -150, 0, 94),
	BackgroundColor3 = Color3.fromRGB(18, 24, 44),
}, gui)
corner(daily, 14)
stroke(daily, C.gold, 1.5)

new("TextLabel", {
	Size = UDim2.new(0, 150, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = "◆  REGALO DIARIO",
	TextColor3 = C.gold,
	TextSize = 14,
	FontFace = FONT_HEAVY,
	TextXAlignment = Enum.TextXAlignment.Left,
}, daily)
ui.dailyStreak = new("TextLabel", {
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 158, 0, 0),
	BackgroundTransparency = 1,
	Text = "RACHA 1",
	TextColor3 = C.muted,
	TextSize = 12,
	FontFace = FONT,
	TextXAlignment = Enum.TextXAlignment.Right,
}, daily)
ui.dailyButton = new("TextButton", {
	Size = UDim2.new(0, 92, 0, 34),
	Position = UDim2.new(1, -100, 0, 6),
	BackgroundColor3 = C.gold,
	TextColor3 = Color3.fromRGB(35, 22, 0),
	Text = "RECLAMAR",
	TextSize = 11,
	FontFace = FONT_HEAVY,
}, daily)
corner(ui.dailyButton, 10)
ui.dailyButton.MouseButton1Click:Connect(function()
	Action:FireServer({ type = "ClaimDaily" })
end)

-- ----------------------- Combo / crítico -----------------------
ui.combo = new("TextLabel", {
	Size = UDim2.new(0, 360, 0, 48),
	Position = UDim2.new(0.5, -180, 1, -196),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = C.pink,
	TextSize = 30,
	FontFace = FONT_HEAVY,
	TextTransparency = 1,
}, gui)

ui.crit = new("TextLabel", {
	Size = UDim2.new(0, 300, 0, 42),
	Position = UDim2.new(0.5, -150, 1, -150),
	BackgroundTransparency = 1,
	Text = "¡CRÍTICO  x5!",
	TextColor3 = C.gold,
	TextSize = 28,
	FontFace = FONT_HEAVY,
	TextTransparency = 1,
}, gui)

local lastCombo = 0
local function showCombo(count, mult)
	if count <= 0 then
		ui.combo.TextTransparency = 1
		lastCombo = 0
		return
	end
	ui.combo.Text = "COMBO ×" .. count .. "   x" .. string.format("%.2f", mult)
	ui.combo.TextColor3 = count >= 8 and C.gold or (count >= 4 and C.pink or C.cyan)
	tween(ui.combo, 0.12, { TextTransparency = 0 }):Play()
	if count ~= lastCombo then
		ui.combo.Size = UDim2.new(0, 390, 0, 52)
		ui.combo.Position = UDim2.new(0.5, -195, 1, -196)
		tween(ui.combo, 0.25, {
			Size = UDim2.new(0, 360, 0, 48),
			Position = UDim2.new(0.5, -180, 1, -196),
		}, Enum.EasingStyle.Elastic):Play()
		lastCombo = count
	end
end

local function showCrit()
	ui.crit.TextTransparency = 0
	ui.crit.Size = UDim2.new(0, 360, 0, 50)
	ui.crit.Position = UDim2.new(0.5, -180, 1, -150)
	tween(ui.crit, 0.25, {
		Size = UDim2.new(0, 300, 0, 42),
		Position = UDim2.new(0.5, -150, 1, -150),
	}, Enum.EasingStyle.Elastic):Play()
	task.delay(0.45, function()
		tween(ui.crit, 0.3, { TextTransparency = 1 }):Play()
	end)
end

-- ----------------------- Compra múltiple -----------------------
local buyMode = 1
local bulkButtons = {}
local bulkModes = {}
local bulkStrokes = {}

local function setBuyMode(value)
	buyMode = value
	for _, button in ipairs(bulkButtons) do
		local active = bulkModes[button] == buyMode
		button.BackgroundColor3 = active and C.gold or Color3.fromRGB(16, 22, 40)
		button.TextColor3 = active and Color3.fromRGB(35, 22, 0) or C.muted
		local outline = bulkStrokes[button]
		if outline then
			outline.Color = active and C.gold or Color3.fromRGB(55, 70, 110)
			outline.Thickness = active and 2 or 1
		end
	end
	if render then
		render(latest)
	end
end

local function makeBulkToggle(parent, y)
	local holder = new("Frame", {
		Size = UDim2.new(1, -18, 0, 30),
		Position = UDim2.new(0, 9, 0, y),
		BackgroundTransparency = 1,
	}, parent)
	for index, value in ipairs({ 1, 10, "max" }) do
		local label = value == "max" and "MAX" or ("x" .. value)
		local button = new("TextButton", {
			LayoutOrder = index,
			Size = UDim2.new(1 / 3, -4, 1, 0),
			Position = UDim2.new((index - 1) / 3 + 0.006, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(16, 22, 40),
			Text = label,
			TextColor3 = C.muted,
			TextSize = 12,
			FontFace = FONT_HEAVY,
		}, holder)
		corner(button, 9)
		bulkStrokes[button] = stroke(button, Color3.fromRGB(55, 70, 110), 1)
		bulkModes[button] = value
		button.MouseButton1Click:Connect(function()
			setBuyMode(value)
		end)
		table.insert(bulkButtons, button)
	end
end

-- ----------------------- Generadores -----------------------
local left = new("Frame", {
	Size = UDim2.new(0.31, 0, 1, -200),
	Position = UDim2.new(0, 12, 0, 94),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.12,
}, gui)
corner(left, 18)
stroke(left, Color3.fromRGB(55, 75, 125), 1.5)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Text = "GENERADORES",
	TextColor3 = C.cyan,
	TextSize = 18,
	FontFace = FONT_HEAVY,
}, left)
makeBulkToggle(left, 36)

local genScroll = new("ScrollingFrame", {
	Size = UDim2.new(1, -18, 1, -76),
	Position = UDim2.new(0, 9, 0, 72),
	BackgroundTransparency = 1,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(0, 0, 0, #Config.Generators * 86),
}, left)
local genList = new("Frame", { Size = UDim2.new(1, -6, 1, 0), BackgroundTransparency = 1 }, genScroll)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, genList)

local genCards = {}
for index, gen in ipairs(Config.Generators) do
	local card = new("TextButton", {
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundColor3 = C.card,
		Text = "",
		AutoButtonColor = false,
	}, genList)
	corner(card, 14)
	local cardStroke = stroke(card, gen.Color, 1.5)

	local icon = new("Frame", {
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0, 12, 0, 15),
		BackgroundColor3 = gen.Color,
	}, card)
	corner(icon, 12)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = GEN_ICONS[index],
		TextColor3 = Color3.fromRGB(10, 12, 22),
		TextSize = 24,
		FontFace = FONT_HEAVY,
	}, icon)

	new("TextLabel", {
		Size = UDim2.new(1, -150, 0, 26),
		Position = UDim2.new(0, 70, 0, 10),
		BackgroundTransparency = 1,
		Text = gen.Name,
		TextColor3 = C.text,
		TextSize = 15,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local owned = new("TextLabel", {
		Size = UDim2.new(0, 54, 0, 22),
		Position = UDim2.new(1, -60, 0, 10),
		BackgroundColor3 = Color3.fromRGB(10, 14, 28),
		Text = "x0",
		TextColor3 = gen.Color,
		TextSize = 14,
		FontFace = FONT_HEAVY,
	}, card)
	corner(owned, 11)

	new("TextLabel", {
		Size = UDim2.new(1, -150, 0, 22),
		Position = UDim2.new(0, 70, 0, 40),
		BackgroundTransparency = 1,
		Text = "+" .. fmt(gen.CPS) .. "/s",
		TextColor3 = C.green,
		TextSize = 13,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local cost = new("TextLabel", {
		Size = UDim2.new(0, 74, 0, 26),
		Position = UDim2.new(1, -80, 0, 42),
		BackgroundColor3 = Color3.fromRGB(12, 16, 30),
		Text = "◆ " .. fmt(gen.Cost),
		TextColor3 = C.gold,
		TextSize = 13,
		FontFace = FONT_HEAVY,
	}, card)
	corner(cost, 12)

	card.MouseButton1Click:Connect(function()
		Action:FireServer({ type = "BuyGenerator", index = index, amount = buyMode })
	end)
	hover(card, C.card, Color3.fromRGB(40, 52, 88))

	genCards[index] = { owned = owned, cost = cost, stroke = cardStroke, color = gen.Color }
end

-- ----------------------- Mejoras + rebirth -----------------------
local right = new("Frame", {
	Size = UDim2.new(0.31, 0, 1, -200),
	Position = UDim2.new(1, -12, 0, 94),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.12,
}, gui)
corner(right, 18)
stroke(right, Color3.fromRGB(55, 75, 125), 1.5)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Text = "MEJORAS",
	TextColor3 = C.gold,
	TextSize = 18,
	FontFace = FONT_HEAVY,
}, right)
makeBulkToggle(right, 36)

local upScroll = new("ScrollingFrame", {
	Size = UDim2.new(1, -18, 1, -190),
	Position = UDim2.new(0, 9, 0, 72),
	BackgroundTransparency = 1,
	ScrollBarThickness = 5,
	CanvasSize = UDim2.new(0, 0, 0, 3 * 88),
}, right)
local upList = new("Frame", { Size = UDim2.new(1, -6, 1, 0), BackgroundTransparency = 1 }, upScroll)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, upList)

local upCards = {}
for index, key in ipairs(UP_KEYS) do
	local upgrade = Config.Upgrades[key]
	local color = UP_COLORS[key]
	local card = new("TextButton", {
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundColor3 = C.card,
		Text = "",
		AutoButtonColor = false,
	}, upList)
	corner(card, 14)
	stroke(card, color, 1.5)

	local icon = new("Frame", {
		Size = UDim2.new(0, 46, 0, 46),
		Position = UDim2.new(0, 12, 0, 17),
		BackgroundColor3 = color,
	}, card)
	corner(icon, 12)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = UP_ICONS[key],
		TextColor3 = Color3.fromRGB(10, 12, 22),
		TextSize = 22,
		FontFace = FONT_HEAVY,
	}, icon)

	new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 25),
		Position = UDim2.new(0, 68, 0, 9),
		BackgroundTransparency = 1,
		Text = upgrade.Name,
		TextColor3 = C.text,
		TextSize = 15,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local level = new("TextLabel", {
		Size = UDim2.new(0, 60, 0, 22),
		Position = UDim2.new(1, -66, 0, 10),
		BackgroundColor3 = Color3.fromRGB(10, 14, 28),
		Text = "Lv.0",
		TextColor3 = color,
		TextSize = 13,
		FontFace = FONT_HEAVY,
	}, card)
	corner(level, 11)

	new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 20),
		Position = UDim2.new(0, 68, 0, 35),
		BackgroundTransparency = 1,
		Text = upgrade.Desc,
		TextColor3 = C.muted,
		TextSize = 12,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local cost = new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 20),
		Position = UDim2.new(0, 68, 0, 56),
		BackgroundTransparency = 1,
		Text = "◆ " .. fmt(upgrade.BaseCost),
		TextColor3 = C.gold,
		TextSize = 13,
		FontFace = FONT_HEAVY,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	card.MouseButton1Click:Connect(function()
		Action:FireServer({ type = "BuyUpgrade", key = key, amount = buyMode })
	end)
	hover(card, C.card, Color3.fromRGB(40, 52, 88))

	upCards[key] = { level = level, cost = cost }
end

local rebirthCard = new("TextButton", {
	Size = UDim2.new(1, -18, 0, 108),
	Position = UDim2.new(0, 9, 1, -116),
	BackgroundColor3 = Color3.fromRGB(70, 25, 85),
	Text = "",
	AutoButtonColor = false,
}, right)
corner(rebirthCard, 16)
stroke(rebirthCard, C.pink, 2)
gradient(rebirthCard, Color3.fromRGB(110, 35, 140), Color3.fromRGB(55, 20, 90), 90)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 0, 8),
	BackgroundTransparency = 1,
	Text = "REBIRTH  ·  +50% PARA SIEMPRE",
	TextColor3 = Color3.fromRGB(255, 220, 255),
	TextSize = 15,
	FontFace = FONT_HEAVY,
}, rebirthCard)

ui.rebirthInfo = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 0, 38),
	BackgroundTransparency = 1,
	Text = "0 / 300 clics",
	TextColor3 = C.text,
	TextSize = 13,
	FontFace = FONT,
}, rebirthCard)

local barBg = new("Frame", {
	Size = UDim2.new(1, -28, 0, 14),
	Position = UDim2.new(0, 14, 0, 74),
	BackgroundColor3 = Color3.fromRGB(15, 10, 30),
}, rebirthCard)
corner(barBg, 7)
ui.rebirthFill = new("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = C.pink,
}, barBg)
corner(ui.rebirthFill, 7)
gradient(ui.rebirthFill, C.pink, C.purple, 90)

rebirthCard.MouseButton1Click:Connect(function()
	Action:FireServer({ type = "Rebirth" })
end)

-- ----------------------- Botón de clic -----------------------
ui.click = new("TextButton", {
	Name = "ClickButton",
	Size = UDim2.new(0, 300, 0, 84),
	Position = UDim2.new(0.5, -150, 1, -92),
	BackgroundColor3 = C.pink,
	Text = "",
	AutoButtonColor = false,
}, gui)
corner(ui.click, 24)
stroke(ui.click, Color3.fromRGB(255, 210, 235), 3)
gradient(ui.click, Color3.fromRGB(255, 90, 170), Color3.fromRGB(155, 70, 255), 90)

new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 46),
	Position = UDim2.new(0, 0, 0, 8),
	BackgroundTransparency = 1,
	Text = "¡CLIC!",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 34,
	FontFace = FONT_HEAVY,
}, ui.click)
ui.clickPower = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 0, 52),
	BackgroundTransparency = 1,
	Text = "+1 por clic",
	TextColor3 = Color3.fromRGB(255, 235, 250),
	TextSize = 13,
	FontFace = FONT,
}, ui.click)

ui.stats = new("TextLabel", {
	Size = UDim2.new(0, 420, 0, 22),
	Position = UDim2.new(0.5, -210, 1, -44),
	BackgroundTransparency = 1,
	Text = "TOTAL 0   ·   REBIRTHS 0   ·   CLICS 0",
	TextColor3 = C.muted,
	TextSize = 11,
	FontFace = FONT,
}, gui)

new("TextLabel", {
	Size = UDim2.new(0, 360, 0, 20),
	Position = UDim2.new(0.5, -180, 1, -22),
	BackgroundTransparency = 1,
	Text = "ESPACIO = CLIC   •   CLIC EN EL MUNDO   •   x1 / x10 / MAX",
	TextColor3 = Color3.fromRGB(140, 155, 190),
	TextSize = 10,
	FontFace = FONT,
}, gui)

local clickHome = ui.click.Position
local function clickFeedback()
	local down = tween(ui.click, 0.05, {
		Position = UDim2.new(0.5, -150, 1, -86),
	})
	down:Play()
	down.Completed:Wait()
	tween(ui.click, 0.18, { Position = clickHome }, Enum.EasingStyle.Elastic):Play()
end

ui.click.MouseButton1Click:Connect(function()
	Action:FireServer({ type = "Click" })
	clickFeedback()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space then
		Action:FireServer({ type = "Click" })
		clickFeedback()
	end
end)

task.spawn(function()
	while ui.click.Parent do
		tween(ui.click, 0.9, { Size = UDim2.new(0, 310, 0, 88) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
		task.wait(0.9)
		tween(ui.click, 0.9, { Size = UDim2.new(0, 300, 0, 84) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
		task.wait(0.9)
	end
end)

-- ----------------------- Avisos -----------------------
local toastHolder = new("Frame", {
	Size = UDim2.new(0, 520, 0, 60),
	Position = UDim2.new(0.5, -260, 0, 150),
	BackgroundTransparency = 1,
}, gui)

local function toast(text, kind)
	local color = C.green
	local prefix = "✓  "
	if kind == "bad" then
		color, prefix = C.red, "✕  "
	elseif kind == "achievement" then
		color, prefix = C.gold, "★  "
	elseif kind == "daily" then
		color, prefix = C.cyan, "◆  "
	end

	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Color3.fromRGB(12, 16, 30),
		BackgroundTransparency = 0.15,
		Text = prefix .. text,
		TextColor3 = color,
		TextSize = 14,
		FontFace = FONT,
		TextWrapped = true,
	}, toastHolder)
	corner(label, 14)
	stroke(label, color, 1.5)
	label.TextTransparency = 1
	tween(label, 0.18, { TextTransparency = 0 }):Play()
	task.delay(kind == "achievement" and 3.4 or 2.4, function()
		local fade = tween(label, 0.35, { TextTransparency = 1, BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		label:Destroy()
	end)
end

Notify.OnClientEvent:Connect(function(text, kind)
	toast(text, kind)
end)

-- ----------------------- Modales -----------------------
local function modal(width, height)
	local shade = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(4, 6, 16),
		BackgroundTransparency = 0.45,
		Visible = false,
	}, gui)
	local card = new("Frame", {
		Size = UDim2.new(0, width, 0, height),
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		BackgroundColor3 = C.panel,
	}, shade)
	corner(card, 22)
	stroke(card, C.gold, 2)
	return shade, card
end

local function closeButton(parent)
	local button = new("TextButton", {
		Size = UDim2.new(0, 42, 0, 42),
		Position = UDim2.new(1, -52, 0, 5),
		BackgroundColor3 = Color3.fromRGB(190, 45, 75),
		TextColor3 = Color3.new(1, 1, 1),
		Text = "X",
		TextSize = 18,
		FontFace = FONT_HEAVY,
	}, parent)
	corner(button, 12)
	return button
end

-- Logros
local achShade, achCard = modal(640, 540)
new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
	Text = "★  LOGROS  ★",
	TextColor3 = C.gold,
	TextSize = 24,
	FontFace = FONT_HEAVY,
}, achCard)
closeButton(achCard).MouseButton1Click:Connect(function()
	achShade.Visible = false
end)
ui.achButton.MouseButton1Click:Connect(function()
	achShade.Visible = not achShade.Visible
end)

local achScroll = new("ScrollingFrame", {
	Size = UDim2.new(1, -28, 1, -66),
	Position = UDim2.new(0, 14, 0, 58),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(0, 0, 0, #Config.Achievements * 74 + 10),
}, achCard)
local achRows = {}
for index, achievement in ipairs(Config.Achievements) do
	local row = new("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 66),
		BackgroundColor3 = Color3.fromRGB(30, 38, 66),
	}, achScroll)
	corner(row, 12)
	local mark = new("TextLabel", {
		Size = UDim2.new(0, 50, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "○",
		TextColor3 = C.muted,
		TextSize = 26,
		FontFace = FONT_HEAVY,
	}, row)
	new("TextLabel", {
		Size = UDim2.new(1, -180, 0, 28),
		Position = UDim2.new(0, 62, 0, 8),
		BackgroundTransparency = 1,
		Text = achievement.Name,
		TextColor3 = C.text,
		TextSize = 16,
		FontFace = FONT_HEAVY,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	new("TextLabel", {
		Size = UDim2.new(1, -180, 0, 22),
		Position = UDim2.new(0, 62, 0, 36),
		BackgroundTransparency = 1,
		Text = achievement.Desc,
		TextColor3 = C.muted,
		TextSize = 12,
		FontFace = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local reward = new("TextLabel", {
		Size = UDim2.new(0, 110, 1, 0),
		Position = UDim2.new(1, -118, 0, 0),
		BackgroundTransparency = 1,
		Text = "◆ " .. fmt(achievement.Reward),
		TextColor3 = C.gold,
		TextSize = 14,
		FontFace = FONT_HEAVY,
	}, row)
	achRows[achievement.Key] = { row = row, mark = mark, reward = reward }
end

-- Tienda
local shopShade, shopCard = modal(640, 560)
new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
	Text = "★  TIENDA ROBUX  ★",
	TextColor3 = C.gold,
	TextSize = 24,
	FontFace = FONT_HEAVY,
}, shopCard)
closeButton(shopCard).MouseButton1Click:Connect(function()
	shopShade.Visible = false
end)
ui.shopButton.MouseButton1Click:Connect(function()
	shopShade.Visible = not shopShade.Visible
end)

local shopScroll = new("ScrollingFrame", {
	Size = UDim2.new(1, -28, 1, -66),
	Position = UDim2.new(0, 14, 0, 58),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(0, 0, 0, (#Config.Gamepasses + #Config.Products) * 112 + 30),
}, shopCard)
local shopList = new("Frame", { Size = UDim2.new(1, -8, 1, 0), BackgroundTransparency = 1 }, shopScroll)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, shopList)

local shopItems = {}
local function shopCardButton(icon, title, subtitle, badge, color, key, order, isPass)
	local card = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundColor3 = Color3.fromRGB(30, 38, 66),
		Text = "",
		AutoButtonColor = false,
	}, shopList)
	corner(card, 14)
	stroke(card, color, 2)

	new("TextLabel", {
		Size = UDim2.new(0, 56, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = icon,
		TextColor3 = color,
		TextSize = 30,
		FontFace = FONT_HEAVY,
	}, card)

	new("TextLabel", {
		Size = UDim2.new(1, -200, 0, 30),
		Position = UDim2.new(0, 80, 0, 16),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C.text,
		TextSize = 18,
		FontFace = FONT_HEAVY,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	new("TextLabel", {
		Size = UDim2.new(1, -200, 0, 42),
		Position = UDim2.new(0, 80, 0, 48),
		BackgroundTransparency = 1,
		Text = subtitle,
		TextColor3 = C.muted,
		TextSize = 13,
		FontFace = FONT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local badgeFrame = new("Frame", {
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(1, -110, 0, 14),
		BackgroundColor3 = color,
	}, card)
	corner(badgeFrame, 15)
	local badgeLabel = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = badge,
		TextColor3 = Color3.fromRGB(12, 14, 26),
		TextSize = 12,
		FontFace = FONT_HEAVY,
	}, badgeFrame)

	card.MouseButton1Click:Connect(function()
		if isPass and latest.Perks[key] then
			toast("Ya tienes este pase", "bad")
			return
		end
		Action:FireServer({ type = "Prompt", key = key })
	end)
	hover(card, Color3.fromRGB(30, 38, 66), Color3.fromRGB(44, 56, 96))

	shopItems[key] = { badge = badgeLabel, frame = badgeFrame, isPass = isPass, color = color }
end

local order = 1
for _, pass in ipairs(Config.Gamepasses) do
	local configured = pass.Id > 0
	local subtitle = configured and (pass.Desc .. "  •  Pase Roblox") or "⚠ Configura el ID en Config.lua"
	shopCardButton("★", pass.Name, subtitle, configured and "PASE" or "SIN ID", pass.Color, pass.Key, order, true)
	order += 1
end
for _, product in ipairs(Config.Products) do
	local configured = product.Id > 0
	local subtitle = configured and ("+" .. fmt(product.Coins) .. " monedas  •  " .. product.Price) or "⚠ Configura el ID en Config.lua"
	shopCardButton("◆", product.Name, subtitle, configured and product.Price or "SIN ID", C.green, product.Key, order, false)
	order += 1
end

-- Tutorial
local tutShade, tutCard = modal(540, 380)
local tutClose
new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundTransparency = 1,
	Text = "BIENVENIDO A BOBUX CLICKER",
	TextColor3 = C.gold,
	TextSize = 22,
	FontFace = FONT_HEAVY,
}, tutCard)
tutClose = closeButton(tutCard)

local steps = {
	{ "1", "CLIC", "Haz clic en el botón rosa o en la barra espaciadora. Clika seguido para subir el COMBO." },
	{ "2", "CONSTRUYE", "Compra generadores con la izquierda. Usa x10 o MAX para comprar de golpe." },
	{ "3", "CRECE", "Mejora, reclama el regalo diario y haz REBIRTH para ganar multiplicadores." },
}
for index, step in ipairs(steps) do
	local y = 62 + (index - 1) * 78
	local row = new("Frame", {
		Size = UDim2.new(1, -36, 0, 68),
		Position = UDim2.new(0, 18, 0, y),
		BackgroundColor3 = Color3.fromRGB(30, 38, 66),
	}, tutCard)
	corner(row, 12)
	stroke(row, C.cyan, 1)
	new("TextLabel", {
		Size = UDim2.new(0, 44, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = step[1],
		TextColor3 = C.cyan,
		TextSize = 28,
		FontFace = FONT_HEAVY,
	}, row)
	new("TextLabel", {
		Size = UDim2.new(1, -180, 0, 26),
		Position = UDim2.new(0, 58, 0, 8),
		BackgroundTransparency = 1,
		Text = step[2],
		TextColor3 = C.text,
		TextSize = 16,
		FontFace = FONT_HEAVY,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	new("TextLabel", {
		Size = UDim2.new(1, -75, 0, 32),
		Position = UDim2.new(0, 58, 0, 34),
		BackgroundTransparency = 1,
		Text = step[3],
		TextColor3 = C.muted,
		TextSize = 12,
		FontFace = FONT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
end

local tutStart = new("TextButton", {
	Size = UDim2.new(0, 200, 0, 46),
	Position = UDim2.new(0.5, -100, 1, -58),
	BackgroundColor3 = C.gold,
	TextColor3 = Color3.fromRGB(35, 22, 0),
	Text = "¡A JUGAR!",
	TextSize = 18,
	FontFace = FONT_HEAVY,
}, tutCard)
corner(tutStart, 14)
stroke(tutStart, Color3.fromRGB(255, 240, 170), 2)

local tutorialChecked = false
local function finishTutorial()
	if tutShade.Visible then
		Action:FireServer({ type = "TutorialDone" })
	end
	tutShade.Visible = false
end
tutClose.MouseButton1Click:Connect(finishTutorial)
tutStart.MouseButton1Click:Connect(finishTutorial)

-- ----------------------- Efectos -----------------------
local clickerModel = Workspace:WaitForChild("Clicker")
local worldButton = clickerModel:WaitForChild("Button")
local worldButtonSize = worldButton.Size
local worldPressing = false

local function screenText(text, color, big)
	local mouse = UserInputService:GetMouseLocation()
	local label = new("TextLabel", {
		Size = UDim2.new(0, big and 220 or 150, 0, big and 70 or 50),
		Position = UDim2.new(0, mouse.X - (big and 110 or 75), 0, mouse.Y - (big and 55 or 40)),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		TextSize = big and 42 or 30,
		FontFace = FONT_HEAVY,
	}, fxGui)
	local rise = tween(label, 0.7, {
		Position = UDim2.new(0, label.Position.X.Offset, 0, mouse.Y - (big and 130 or 100)),
	}, Enum.EasingStyle.Quad)
	local fade = tween(label, 0.7, { TextTransparency = 1 })
	rise:Play()
	fade:Play()
	rise.Completed:Wait()
	label:Destroy()
end

local function worldText(text, color)
	local billboard = new("BillboardGui", {
		Size = UDim2.new(0, 170, 0, 60),
		AlwaysOnTop = true,
		StudsOffset = Vector3.new(0, 2, 0),
	}, worldButton)
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color or C.green,
		TextSize = 40,
		FontFace = FONT_HEAVY,
	}, billboard)
	local rise = tween(billboard, 0.8, { StudsOffset = Vector3.new(0, 5.5, 0) })
	local fade = tween(label, 0.8, { TextTransparency = 1 })
	rise:Play()
	fade:Play()
	rise.Completed:Wait()
	billboard:Destroy()
end

local function pressWorldButton()
	if worldPressing then
		return
	end
	worldPressing = true
	local down = tween(worldButton, 0.05, {
		Size = worldButtonSize - Vector3.new(0.6, 0.3, 0.6),
	})
	down:Play()
	down.Completed:Wait()
	local up = tween(worldButton, 0.2, { Size = worldButtonSize }, Enum.EasingStyle.Elastic)
	up:Play()
	up.Completed:Wait()
	worldPressing = false
end

ClickFX.OnClientEvent:Connect(function(power, playerName, crit, combo)
	local color = crit and C.gold or (combo >= 6 and C.pink or C.green)
	local text = "+" .. fmt(power) .. (crit and "!" or "")
	if playerName == localPlayer.Name then
		task.spawn(screenText, text, color, crit)
		if crit then
			showCrit()
		end
	else
		task.spawn(worldText, text, color)
	end
	pressWorldButton()
end)

-- Leaderboard 3D
local boardModel = Workspace:FindFirstChild("Leaderboard")
local boardLabel = boardModel
	and boardModel:FindFirstChild("Board")
	and boardModel.Board:FindFirstChild("BillboardGui")
	and boardModel.Board.BillboardGui:FindFirstChild("Label")

Leaderboard.OnClientEvent:Connect(function(entries)
	if not boardLabel or type(entries) ~= "table" then
		return
	end
	local lines = { "TOP GANADORES", "" }
	for index, entry in ipairs(entries) do
		table.insert(lines, string.format("%d.  %s   %s", index, entry.Name, fmt(entry.Value)))
	end
	if #entries == 0 then
		table.insert(lines, "Sé el primero ✦")
	end
	boardLabel.Text = table.concat(lines, "\n")
end)

-- ----------------------- Render -----------------------
function render(data)
	latest = data
	ui.coins.Text = fmt(data.Coins)
	ui.cps.Text = fmt(data.CPS) .. "/s"
	ui.mult.Text = "x" .. string.format("%.1f", data.Multiplier)
	ui.rebirths.Text = "RB " .. (data.Rebirths or 0)
	ui.clickPower.Text = "+" .. fmt(data.ClickPower) .. " por clic"
	ui.stats.Text = "TOTAL " .. fmt(data.TotalEarned)
		.. "   ·   REBIRTHS " .. (data.Rebirths or 0)
		.. "   ·   CLICS " .. fmt(data.TotalClicks or 0)

	local bulkTag = buyMode == "max" and " MAX" or (buyMode == 1 and "" or " x" .. buyMode)
	for index, refs in ipairs(genCards) do
		local gen = Config.Generators[index]
		local owned = data.Generators[index] or 0
		local cost = data.GenCosts[index] or gen.Cost
		refs.owned.Text = "x" .. owned
		refs.cost.Text = "◆ " .. fmt(cost) .. bulkTag
		refs.cost.TextColor3 = data.Coins >= cost and C.green or C.muted
		refs.stroke.Color = data.Coins >= cost and gen.Color or Color3.fromRGB(60, 70, 100)
	end

	for _, key in ipairs(UP_KEYS) do
		local upgrade = Config.Upgrades[key]
		local level = data.Upgrades[key] or 0
		local cost = data.UpCosts[key] or upgrade.BaseCost
		local maxed = level >= upgrade.Max
		local refs = upCards[key]
		refs.level.Text = "Lv." .. level
		refs.cost.Text = maxed and "MAX" or ("◆ " .. fmt(cost) .. bulkTag)
		refs.cost.TextColor3 = (not maxed and data.Coins >= cost) and C.green or C.muted
	end

	local required = data.RebirthRequired or Config.Rebirth.RequiredClicksBase
	local progress = math.clamp((data.TotalClicks or 0) / math.max(1, required), 0, 1)
	ui.rebirthInfo.Text = fmt(data.TotalClicks or 0) .. " / " .. fmt(required) .. " clics"
	tween(ui.rebirthFill, 0.25, { Size = UDim2.new(progress, 0, 1, 0) }):Play()

	ui.dailyStreak.Text = "RACHA " .. ((data.DailyStreak or 0) + 1)
	if data.DailyReady then
		ui.dailyButton.BackgroundColor3 = C.gold
		ui.dailyButton.TextColor3 = Color3.fromRGB(35, 22, 0)
		ui.dailyButton.Text = "RECLAMAR"
	else
		ui.dailyButton.BackgroundColor3 = Color3.fromRGB(50, 60, 90)
		ui.dailyButton.TextColor3 = C.muted
		ui.dailyButton.Text = "YA TOMADO"
	end

	showCombo(data.Combo or 0, data.ComboMultiplier or 1)

	if achShade.Visible then
		for _, achievement in ipairs(Config.Achievements) do
			local refs = achRows[achievement.Key]
			local done = data.Achievements[achievement.Key] == true
			refs.mark.Text = done and "✓" or "○"
			refs.mark.TextColor3 = done and C.gold or C.muted
			refs.reward.TextColor3 = done and C.green or C.gold
			refs.row.BackgroundColor3 = done and Color3.fromRGB(38, 46, 50) or Color3.fromRGB(30, 38, 66)
		end
	end

	if shopShade.Visible then
		for key, refs in pairs(shopItems) do
			if refs.isPass and data.Perks[key] then
				refs.badge.Text = "TUYO"
				refs.frame.BackgroundColor3 = C.green
			end
		end
	end

	if not tutorialChecked then
		tutorialChecked = true
		if not data.TutorialSeen then
			tutShade.Visible = true
		end
	end
end

setBuyMode(1)

State.OnClientEvent:Connect(render)
Action:FireServer({ type = "Ready" })

print("[BobuxClicker] Cliente listo ✔")
