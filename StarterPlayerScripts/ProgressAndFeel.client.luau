--!strict
-- HUD de proximo objetivo y feedback visual para Bobux Clicker.
-- Solo usa el estado validado por servidor. No envia clics ni concede dinero.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local guiRoot = player:WaitForChild("PlayerGui")
local config = require(ReplicatedStorage:WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local State = remotes:WaitForChild("State") :: RemoteEvent
local ClickFX = remotes:WaitForChild("ClickFX") :: RemoteEvent

local CYAN = Color3.fromRGB(53, 216, 255)
local GOLD = Color3.fromRGB(255, 214, 107)
local PINK = Color3.fromRGB(255, 83, 173)
local function new(className: string, props: {[string]: any}, parent: Instance): Instance
    local object = Instance.new(className)
    for property, value in props do
        (object :: any)[property] = value
    end
    object.Parent = parent
    return object
end
local function tween(object: Instance, duration: number, props: {[string]: any})
    TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function fmt(n: number): string
    if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end

local gui = new("ScreenGui", {
    Name = "BobuxProgressPolish", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4,
}, guiRoot) :: ScreenGui

local goal = new("Frame", {
    Name = "NextGoal", Size = UDim2.fromOffset(320, 72),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 92),
    BackgroundColor3 = Color3.fromRGB(17, 25, 47),
    BackgroundTransparency = 0.07,
}, gui) :: Frame
new("UICorner", {CornerRadius = UDim.new(0, 13)}, goal)
new("UIStroke", {Color = CYAN, Thickness = 1.3, Transparency = 0.3}, goal)
local heading = new("TextLabel", {
    Name = "GoalHeading", Size = UDim2.new(1, -24, 0, 27),
    Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1,
    Text = "SIGUIENTE OBJETIVO", TextColor3 = GOLD,
    TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, goal) :: TextLabel
local detail = new("TextLabel", {
    Name = "GoalText", Size = UDim2.new(1, -24, 0, 23),
    Position = UDim2.fromOffset(12, 28), BackgroundTransparency = 1,
    Text = "Cargando progreso...", TextColor3 = Color3.fromRGB(235, 244, 255),
    TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, goal) :: TextLabel
local track = new("Frame", {
    Name = "ProgressTrack", Size = UDim2.new(1, -24, 0, 7),
    Position = UDim2.new(0, 12, 1, -14),
    BackgroundColor3 = Color3.fromRGB(48, 59, 83),
}, goal) :: Frame
new("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
local fill = new("Frame", {
    Name = "ProgressFill", Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = CYAN,
}, track) :: Frame
new("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

local settings = new("TextButton", {
    Name = "ReduceFX", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 170), Size = UDim2.fromOffset(122, 28),
    BackgroundColor3 = Color3.fromRGB(27, 35, 56), TextColor3 = Color3.fromRGB(220, 233, 255),
    TextSize = 11, Font = Enum.Font.GothamMedium,
    Text = "EFECTOS: SI", AutoButtonColor = true,
}, gui) :: TextButton
new("UICorner", {CornerRadius = UDim.new(0, 8)}, settings)
local reduced = false
settings.Activated:Connect(function()
    reduced = not reduced
    settings.Text = reduced and "EFECTOS: NO" or "EFECTOS: SI"
end)

local function resize()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if viewport.X < 820 then
        goal.Size = UDim2.new(0, math.min(300, viewport.X - 20), 0, 68)
        goal.Position = UDim2.new(0.5, 0, 0, 80)
        settings.Position = UDim2.new(1, -8, 0, 151)
    else
        goal.Size = UDim2.fromOffset(320, 72)
        goal.Position = UDim2.new(0.5, 0, 0, 92)
        settings.Position = UDim2.new(1, -12, 0, 170)
    end
end
local currentCamera = Workspace.CurrentCamera
if currentCamera then currentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()

State.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    local coins = tonumber(data.Coins) or 0
    local generatorCosts = data.GenCosts
    local generators = data.Generators
    local bestIndex, bestCost = nil, math.huge
    if type(generatorCosts) == "table" and type(generators) == "table" then
        for i, price in ipairs(generatorCosts) do
            local priceNumber = tonumber(price)
            if priceNumber and priceNumber > 0 and priceNumber < bestCost then
                bestCost = priceNumber
                bestIndex = i
            end
        end
    end
    if bestIndex and config.Generators[bestIndex] then
        local name = config.Generators[bestIndex].Name
        heading.Text = "PROXIMA COMPRA"
        detail.Text = name .. ": " .. fmt(coins) .. " / " .. fmt(bestCost) .. " monedas"
        tween(fill, reduced and 0 or 0.22, {Size = UDim2.fromScale(math.clamp(coins / bestCost, 0, 1), 1)})
        fill.BackgroundColor3 = coins >= bestCost and GOLD or CYAN
    else
        heading.Text = "SIGUE CRECIENDO"
        detail.Text = "Compra mejoras y alcanza tu siguiente Rebirth"
        tween(fill, 0.2, {Size = UDim2.fromScale(1, 1)})
    end
end)

-- Destello breve solo ante criticos confirmados; sin shake de camara intrusivo.
local particlesActive = 0
ClickFX.OnClientEvent:Connect(function(power, clickedPlayerName, critical)
    if reduced or not critical or clickedPlayerName ~= player.Name then return end
    if particlesActive >= 3 then return end
    local clicker = Workspace:FindFirstChild("Clicker")
    local button = clicker and clicker:FindFirstChild("Button")
    if not button or not button:IsA("BasePart") then return end
    particlesActive += 1
    local attachment = Instance.new("Attachment")
    attachment.Parent = button
    local burst = Instance.new("ParticleEmitter")
    burst.Rate = 0
    burst.Lifetime = NumberRange.new(0.28, 0.48)
    burst.Speed = NumberRange.new(4, 7)
    burst.SpreadAngle = Vector2.new(180, 180)
    burst.LightEmission = 0.85
    burst.Color = ColorSequence.new(GOLD, PINK)
    burst.Size = NumberSequence.new(0.25, 0)
    burst.Parent = attachment
    burst:Emit(10)
    Debris:AddItem(attachment, 1)
    task.delay(0.6, function() particlesActive = math.max(0, particlesActive - 1) end)
end)
