-- ============================================================
-- build.lua - Genera Place1.rbxl desde Place1.original.rbxl
-- Uso: lune run build.lua  (o doble clic en build.bat)
-- ============================================================

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local V3 = roblox.Vector3
local C3 = roblox.Color3
local CF = roblox.CFrame
local UDim2 = roblox.UDim2
local Enum = roblox.Enum
local Font = roblox.Font
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_HEAVY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)

local INPUT = "Place1.original.rbxl"
local OUTPUT = "Place1.rbxl"

if pcall(fs.readFile, "Place1.rbxl.lock") then
	error("Cierra Roblox Studio antes de regenerar el place.")
end

local function make(className, properties, parent)
	local inst = Instance.new(className)
	for key, value in pairs(properties or {}) do
		inst[key] = value
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function sign(parent, text, color, size, yOffset)
	local gui = make("BillboardGui", {
		Name = "SignGui",
		Size = size or UDim2.new(0, 300, 0, 90),
		AlwaysOnTop = true,
		StudsOffset = V3.new(0, yOffset or 2, 0),
	}, parent)
	make("TextLabel", {
		Name = "SignText",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = C3.fromRGB(12, 14, 28),
		BackgroundTransparency = 0.2,
		Text = text,
		TextColor3 = color or C3.fromRGB(255, 255, 255),
		TextSize = 30,
		FontFace = FONT_HEAVY,
	}, gui)
	return gui
end

print("Leyendo " .. INPUT .. " ...")
local game = roblox.deserializePlace(fs.readFile(INPUT))

local workspace = game:GetService("Workspace")
local serverScripts = game:GetService("ServerScriptService")
local replicated = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")
local starterPlayer = game:GetService("StarterPlayer")
local lighting = game:GetService("Lighting")

local playerScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
if not playerScripts then
	playerScripts = make("StarterPlayerScripts", { Name = "StarterPlayerScripts" }, starterPlayer)
end

for _, service in ipairs({ workspace, serverScripts, replicated, starterGui, playerScripts, lighting }) do
	service:ClearAllChildren()
end

pcall(function()
	lighting.Ambient = C3.fromRGB(70, 75, 110)
	lighting.Brightness = 1.5
	lighting.Color = C3.fromRGB(200, 215, 255)
end)

pcall(function()
	make("BloomEffect", {
		Name = "NeonBloom",
		Intensity = 0.35,
		Threshold = 0.85,
		Size = 22,
	}, lighting)
	make("ColorCorrectionEffect", {
		Name = "ColorGrade",
		Saturation = 0.12,
		Contrast = 0.08,
		Brightness = 0.03,
	}, lighting)
end)

-- ----------------------- Suelo -----------------------
make("Part", {
	Name = "Baseplate",
	Size = V3.new(160, 2, 160),
	Position = V3.new(0, -1, 0),
	Color = C3.fromRGB(14, 17, 32),
	Anchored = true,
}, workspace)

local tiles = make("Folder", { Name = "Tiles" }, workspace)
for x = -60, 60, 12 do
	for z = -60, 60, 12 do
		make("Part", {
			Name = "Tile",
			Size = V3.new(10, 0.2, 10),
			Position = V3.new(x, 0.1, z),
			Color = (x + z) % 24 == 0 and C3.fromRGB(32, 40, 70) or C3.fromRGB(22, 27, 48),
			Anchored = true,
		}, tiles)
	end
end

local decorations = make("Folder", { Name = "Decorations" }, workspace)
for index = 1, 14 do
	local angle = (index - 1) / 14 * math.pi * 2
	local x = math.cos(angle) * 62
	local z = math.sin(angle) * 62
	make("Part", {
		Name = "Pillar",
		Size = V3.new(1.4, 12, 1.4),
		Position = V3.new(x, 6, z),
		Color = C3.fromRGB(55, 40, 95),
		Anchored = true,
	}, decorations)
	make("Part", {
		Name = "PillarGlow",
		Size = V3.new(1.8, 0.5, 1.8),
		Position = V3.new(x, 12.2, z),
		Color = index % 2 == 0 and C3.fromRGB(80, 220, 255) or C3.fromRGB(255, 80, 170),
		Anchored = true,
	}, decorations)
end

make("SpawnLocation", {
	Name = "SpawnLocation",
	Size = V3.new(10, 1, 10),
	Position = V3.new(0, 1.5, 12),
	Color = C3.fromRGB(45, 110, 150),
	Anchored = true,
}, workspace)

-- ----------------------- Clicker central -----------------------
local clicker = make("Model", { Name = "Clicker" }, workspace)

make("Part", {
	Name = "Stage",
	Size = V3.new(16, 1, 16),
	Position = V3.new(0, 0.5, 0),
	Color = C3.fromRGB(28, 34, 62),
	Anchored = true,
}, clicker)

for index = 1, 4 do
	local angle = (index - 1) * math.pi / 2
	make("Part", {
		Name = "StageEdge" .. index,
		Size = V3.new(16, 0.3, 0.5),
		Position = V3.new(math.sin(angle) * 8, 1.05, math.cos(angle) * 8),
		Rotation = V3.new(0, (index - 1) * 90, 0),
		Color = C3.fromRGB(80, 220, 255),
		Anchored = true,
	}, clicker)
end

make("Part", {
	Name = "Pedestal",
	Size = V3.new(9, 2, 9),
	Position = V3.new(0, 2.2, 0),
	Color = C3.fromRGB(70, 45, 120),
	Anchored = true,
}, clicker)

local button = make("Part", {
	Name = "Button",
	Size = V3.new(6, 1.3, 6),
	Position = V3.new(0, 3.8, 0),
	Color = C3.fromRGB(255, 80, 165),
	Anchored = true,
}, clicker)
make("ClickDetector", { Name = "ClickDetector", MaxActivationDistance = 25 }, button)
make("PointLight", {
	Name = "Glow",
	Color = C3.fromRGB(255, 90, 180),
	Brightness = 2.5,
	Range = 28,
}, button)

make("Part", {
	Name = "Ring1", Size = V3.new(8, 0.3, 0.4), Position = V3.new(0, 4, 4.2),
	Color = C3.fromRGB(255, 215, 90), Anchored = true,
}, clicker)
make("Part", {
	Name = "Ring2", Size = V3.new(8, 0.3, 0.4), Position = V3.new(0, 4, -4.2),
	Color = C3.fromRGB(255, 215, 90), Anchored = true,
}, clicker)
make("Part", {
	Name = "Ring3", Size = V3.new(0.4, 0.3, 8), Position = V3.new(4.2, 4, 0),
	Color = C3.fromRGB(255, 215, 90), Anchored = true,
}, clicker)
make("Part", {
	Name = "Ring4", Size = V3.new(0.4, 0.3, 8), Position = V3.new(-4.2, 4, 0),
	Color = C3.fromRGB(255, 215, 90), Anchored = true,
}, clicker)

sign(button, "¡HAZ CLIC!", C3.fromRGB(255, 240, 140), UDim2.new(0, 320, 0, 80), 3.2)

-- ----------------------- Generadores -----------------------
local generators = make("Folder", { Name = "Generators" }, workspace)
local genNames = { "AYUDANTE", "PRENSA", "FÁBRICA", "MINA", "BANCO", "ESPACIO" }
local genRates = { "+0.5/s", "+3/s", "+18/s", "+110/s", "+800/s", "+6500/s" }
local genColors = {
	C3.fromRGB(80, 220, 140),
	C3.fromRGB(80, 180, 255),
	C3.fromRGB(190, 120, 255),
	C3.fromRGB(255, 180, 70),
	C3.fromRGB(90, 255, 210),
	C3.fromRGB(255, 90, 150),
}

for index = 1, 6 do
	local angle = (index - 1) / 6 * math.pi * 2
	local x = math.cos(angle) * 24
	local z = math.sin(angle) * 24
	local model = make("Model", { Name = "Generator" .. index }, generators)

	make("Part", {
		Name = "Base", Size = V3.new(6, 1, 6), Position = V3.new(x, 0.5, z),
		Color = C3.fromRGB(30, 38, 68), Anchored = true,
	}, model)

	local core = make("Part", {
		Name = "Core", Size = V3.new(2.4, 1.6, 2.4), Position = V3.new(x, 2, z),
		Color = genColors[index], Transparency = 0.7, Anchored = true,
	}, model)

	make("Part", {
		Name = "Terminal", Size = V3.new(1.6, 2, 0.8),
		Position = V3.new(x + math.cos(angle) * 2.4, 1.8, z + math.sin(angle) * 2.4),
		Color = C3.fromRGB(18, 22, 40), Anchored = true,
	}, model)

	sign(core, genNames[index] .. "\n" .. genRates[index], genColors[index], UDim2.new(0, 230, 0, 70), 2.4)
end

-- ----------------------- Portal de Rebirth -----------------------
local portal = make("Model", { Name = "RebirthPortal", Parent = workspace })
for index = 1, 10 do
	local angle = (index - 1) / 10 * math.pi * 2
	make("Part", {
		Name = "Ring" .. index,
		Size = V3.new(3, 0.6, 0.5),
		Position = V3.new(math.cos(angle) * 5, 5, -18 + math.sin(angle) * 5),
		Rotation = V3.new(0, -(index - 1) * 36, 0),
		Color = C3.fromRGB(255, 90, 200),
		Anchored = true,
	}, portal)
end
local portalAnchor = make("Part", {
	Name = "SignAnchor", Size = V3.new(1, 1, 1), Position = V3.new(0, 5, -18),
	Transparency = 1, Anchored = true,
}, portal)
make("PointLight", {
	Name = "PortalLight",
	Color = C3.fromRGB(255, 90, 200), Brightness = 2, Range = 22,
}, portalAnchor)
sign(portalAnchor, "REBIRTH  x1.5", C3.fromRGB(255, 170, 255), UDim2.new(0, 340, 0, 80), 9)

-- ----------------------- Puesto del regalo diario -----------------------
local dailyStand = make("Model", { Name = "DailyStand", Parent = workspace })
make("Part", {
	Name = "Base", Size = V3.new(5, 1, 5), Position = V3.new(-14, 0.5, 14),
	Color = C3.fromRGB(45, 38, 24), Anchored = true,
}, dailyStand)
local dailyPad = make("Part", {
	Name = "Pad", Size = V3.new(3.6, 0.6, 3.6), Position = V3.new(-14, 1.3, 14),
	Color = C3.fromRGB(255, 205, 70), Anchored = true,
}, dailyStand)
make("ClickDetector", { Name = "Detector", MaxActivationDistance = 20 }, dailyPad)
make("PointLight", {
	Name = "DailyGlow", Color = C3.fromRGB(255, 200, 80), Brightness = 1.8, Range = 16,
}, dailyPad)
sign(dailyPad, "REGALO DIARIO\n¡CLIC!", C3.fromRGB(255, 235, 150), UDim2.new(0, 300, 0, 90), 3)

-- ----------------------- Monedas flotantes -----------------------
local coins = make("Folder", { Name = "FloatingCoins", Parent = workspace })
for index = 1, 12 do
	make("Part", {
		Name = "Coin" .. index,
		Size = V3.new(0.8, 0.8, 0.25),
		Position = V3.new(0, 4 + index * 0.15, 0),
		Color = C3.fromRGB(255, 215, 80),
		Anchored = true,
	}, coins)
end

-- ----------------------- Leaderboard -----------------------
local leaderboard = make("Model", { Name = "Leaderboard", Parent = workspace })
local board = make("Part", {
	Name = "Board", Size = V3.new(14, 9, 0.8), Position = V3.new(0, 8, -32),
	Color = C3.fromRGB(16, 20, 38), Anchored = true,
}, leaderboard)
local boardGui = make("BillboardGui", {
	Name = "BillboardGui", Size = UDim2.new(0, 520, 0, 340), AlwaysOnTop = true,
}, board)
make("TextLabel", {
	Name = "Label", Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = C3.fromRGB(10, 13, 28), BackgroundTransparency = 0.15,
	Text = "TOP GANADORES\n\nCargando...",
	TextColor3 = C3.fromRGB(255, 220, 120), TextSize = 24, FontFace = FONT,
	TextWrapped = true,
}, boardGui)

-- ----------------------- Remotes y scripts -----------------------
local remotes = make("Folder", { Name = "Remotes" }, replicated)
for _, name in ipairs({ "Action", "State", "Notify", "ClickFX", "Leaderboard" }) do
	make("RemoteEvent", { Name = name }, remotes)
end

-- Los archivos .luau son los mismos que sincroniza Script Sync con Studio.
-- Se agregan todos los que haya en cada carpeta, asi cualquier script nuevo
-- que llegue desde GitHub queda incluido al regenerar el place.
local function scriptsIn(folder, suffix)
	local result = {}
	local ok, entries = pcall(fs.readDir, folder)
	if not ok then return result end
	for _, entry in ipairs(entries) do
		if #entry > #suffix and entry:sub(-#suffix) == suffix then
			table.insert(result, entry)
		end
	end
	table.sort(result)
	return result
end

local function scriptName(file, suffix)
	return file:sub(1, -#suffix - 1)
end

for _, file in ipairs(scriptsIn("ReplicatedStorage", ".luau")) do
	make("ModuleScript", {
		Name = scriptName(file, ".luau"),
		Source = fs.readFile("ReplicatedStorage/" .. file),
	}, replicated)
end

for _, file in ipairs(scriptsIn("ServerScriptService", ".server.luau")) do
	make("Script", {
		Name = scriptName(file, ".server.luau"),
		Source = fs.readFile("ServerScriptService/" .. file),
	}, serverScripts)
end

for _, suffix in ipairs({ ".client.luau", ".local.luau" }) do
	for _, file in ipairs(scriptsIn("StarterPlayerScripts", suffix)) do
		make("LocalScript", {
			Name = scriptName(file, suffix),
			Source = fs.readFile("StarterPlayerScripts/" .. file),
		}, playerScripts)
	end
end

local output = roblox.serializePlace(game)
fs.writeFile(OUTPUT, output)
fs.writeFile("BobuxClicker.rbxl", output)
print("Listo: " .. OUTPUT .. " y BobuxClicker.rbxl (" .. #output .. " bytes)")
