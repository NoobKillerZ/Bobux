-- Popup de recompensa local: ModuleScript en ReplicatedStorage
-- Uso: require(ReplicatedStorage.BobuxPopup).Show(250, worldPosition, false)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Popup = {}
local active = 0
local MAX_POPUPS = 12

function Popup.Show(amount, worldPosition, critical)
    if active >= MAX_POPUPS then return end
    if typeof(worldPosition) ~= "Vector3" then return end
    active += 1
    local anchor = Instance.new("Part")
    anchor.Name = "BobuxPopupAnchor"
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Size = Vector3.new(0.1, 0.1, 0.1)
    anchor.Position = worldPosition + Vector3.new(math.random(-5, 5) / 8, 2.5, 0)
    anchor.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(190, 64)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 90
    billboard.Adornee = anchor
    billboard.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = (critical and "CRIT! +" or "+") .. tostring(amount)
    label.TextColor3 = critical and Color3.fromRGB(255, 213, 107) or Color3.fromRGB(101, 242, 255)
    label.TextStrokeTransparency = 0.35
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard
    local sizeLimit = Instance.new("UITextSizeConstraint")
    sizeLimit.MaxTextSize = 27
    sizeLimit.Parent = label

    TweenService:Create(anchor, TweenInfo.new(0.65, Enum.EasingStyle.Quad),
        {Position = anchor.Position + Vector3.new(0, 3, 0)}):Play()
    TweenService:Create(label, TweenInfo.new(0.65), {
        TextTransparency = 1, TextStrokeTransparency = 1}):Play()
    task.delay(0.7, function() active = math.max(0, active - 1) end)
    Debris:AddItem(anchor, 0.75)
end
return Popup
