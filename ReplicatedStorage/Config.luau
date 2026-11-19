-- ============================================================
-- Config.lua - Configuración central del juego
-- Edita los IDs de gamepasses/productos cuando los crees en Roblox.
-- ============================================================

local Config = {}

Config.Name = "Bobux Clicker Tycoon"
Config.SaveKey = "BobuxClickerTycoon_v4"
Config.LeaderboardKey = "BobuxClickerTycoon_LB_v4"

Config.BaseClickPower = 1
Config.MaxOfflineSeconds = 2 * 60 * 60 -- tope sin mejoras (2 horas)

-- Clics críticos: cada tanto un clic vale mucho más.
Config.Crit = {
	Chance = 0.08,     -- 8% de los clics
	Multiplier = 5,    -- x5
}

--Combo: clicar seguido sube un multiplicador temporal.
Config.Combo = {
	Window = 1.5,      -- segundos para mantener la cadena
	Max = 10,          -- tope de pasos
	Step = 0.15,       -- +15% por paso (x1.15 ... x2.5)
}

-- Regalo diario: racha de días consecutivos.
Config.Daily = {
	Base = 500,
	PerStreak = 500,
	MaxStreak = 7,
}

-- ---------------- Generadores ----------------
-- Coste = Cost * Growth ^ (unidades compradas)
Config.Generators = {
	{ Name = "Ayudante",        Cost = 15,      Growth = 1.15, CPS = 0.5,   Color = Color3.fromRGB(80, 220, 140) },
	{ Name = "Prensa",          Cost = 120,     Growth = 1.15, CPS = 3,     Color = Color3.fromRGB(80, 180, 255) },
	{ Name = "Fábrica",         Cost = 1200,    Growth = 1.15, CPS = 18,    Color = Color3.fromRGB(190, 120, 255) },
	{ Name = "Mina",            Cost = 14000,   Growth = 1.15, CPS = 110,   Color = Color3.fromRGB(255, 180, 70) },
	{ Name = "Banco",           Cost = 200000,  Growth = 1.15, CPS = 800,   Color = Color3.fromRGB(90, 255, 210) },
	{ Name = "Plataforma espacial", Cost = 3500000, Growth = 1.15, CPS = 6500, Color = Color3.fromRGB(255, 90, 150) },
}

-- ---------------- Mejoras ----------------
Config.Upgrades = {
	Click = {
		Name = "Clic potente",
		Desc = "+1 de fuerza por clic",
		BaseCost = 100,
		Growth = 2.1,
		Max = 60,
	},
	Generator = {
		Name = "Motores turbo",
		Desc = "+25% de producción",
		BaseCost = 750,
		Growth = 2.8,
		Max = 40,
	},
	Offline = {
		Name = "Café infinito",
		Desc = "+30 min de ganancias offline",
		BaseCost = 2500,
		Growth = 3.5,
		Max = 8,
	},
}

-- ---------------- Rebirth ----------------
Config.Rebirth = {
	RequiredClicksBase = 300,
	RequiredClicksPerLevel = 250,
	MinGenerators = 1,
	MultiplierPerLevel = 0.5, -- x1.5, x2.0, x2.5 ...
}

-- ---------------- Logros ----------------
-- Se otorgan automáticamente al cumplir la condición y dan monedas.
Config.Achievements = {
	{ Key = "FirstClick", Name = "Primer clic",     Desc = "Haz tu primer clic",        Reward = 50 },
	{ Key = "Click100",   Name = "Mano rápida",     Desc = "100 clics",                 Reward = 250 },
	{ Key = "Click1000",  Name = "Imparable",       Desc = "1,000 clics",               Reward = 2000 },
	{ Key = "FirstGen",   Name = "Primer negocio",  Desc = "Compra 1 generador",        Reward = 500 },
	{ Key = "Gen25",      Name = "Pequeño imperio", Desc = "25 generadores",            Reward = 5000 },
	{ Key = "Earn10K",    Name = "Primer millón",   Desc = "Gana 10K monedas",          Reward = 2500 },
	{ Key = "Earn1M",     Name = "Magnate",         Desc = "Gana 1M de monedas",        Reward = 50000 },
	{ Key = "Rebirth1",   Name = "Nuevo ciclo",     Desc = "Haz tu primer rebirth",     Reward = 10000 },
	{ Key = "Rebirth5",   Name = "Eterno",          Desc = "Haz 5 rebirths",            Reward = 100000 },
}

-- ============================================================
-- MONETIZACIÓN
-- 1) Crea los pases/productos en Roblox (Create > Store).
-- 2) Copia aquí los IDs numéricos.
-- 3) Mientras el ID sea 0, el botón aparece como "sin configurar".
-- ============================================================
Config.Gamepasses = {
	{ Key = "Double",    Id = 0, Name = "2x MONEDAS", Desc = "Duplica todo lo que ganas.", Color = Color3.fromRGB(255, 205, 70) },
	{ Key = "VIP",       Id = 0, Name = "VIP",        Desc = "+50% monedas, 20K al entrar y título dorado.", Color = Color3.fromRGB(190, 120, 255) },
	{ Key = "AutoClick", Id = 0, Name = "AUTOCLIC",   Desc = "+5 clics automáticos por segundo.", Color = Color3.fromRGB(85, 255, 175) },
}

Config.Products = {
	{ Key = "Coins10K",  Id = 0, Name = "10K Monedas",   Coins = 10000,  Price = "R$ 25" },
	{ Key = "Coins100K", Id = 0, Name = "100K Monedas",  Coins = 100000, Price = "R$ 100" },
	{ Key = "MegaPack",  Id = 0, Name = "Mega Pack",     Coins = 750000, Price = "R$ 250" },
}

return Config
