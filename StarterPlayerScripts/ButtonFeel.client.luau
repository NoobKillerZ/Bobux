--!strict
-- Animaciones discretas de botones para el HUD existente.
-- No crea botones nuevos ni dispara acciones de compra/click.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local hooked: {[GuiButton]: boolean} = {}

local function animate(scale: UIScale, target: number, duration: number, style: Enum.EasingStyle)
    TweenService:Create(scale, TweenInfo.new(duration, style, Enum.EasingDirection.Out), {
        Scale = target,
    }):Play()
end

local function attach(inst: Instance)
    if not inst:IsA("GuiButton") then return end
    local button = inst :: GuiButton
    -- Solo al HUD principal. No interferir con botones de sistemas externos.
    if not button:FindFirstAncestor("SimulatorGui") then return end
    if hooked[button] then return end
    hooked[button] = true

    local scale: UIScale
    local existing = button:FindFirstChild("BobuxButtonScale")
    if existing and existing:IsA("UIScale") then
        scale = existing
    else
        scale = Instance.new("UIScale")
        scale.Name = "BobuxButtonScale"
        scale.Scale = 1
        scale.Parent = button
    end
    local hovered = false
    button.MouseEnter:Connect(function()
        if UserInputService.TouchEnabled then return end
        hovered = true
        animate(scale, 1.035, 0.15, Enum.EasingStyle.Quad)
    end)
    button.MouseLeave:Connect(function()
        hovered = false
        animate(scale, 1, 0.15, Enum.EasingStyle.Quad)
    end)
    button.Activated:Connect(function()
        scale.Scale = 0.94
        animate(scale, hovered and 1.035 or 1, 0.26, Enum.EasingStyle.Back)
    end)
    button.Destroying:Connect(function()
        hooked[button] = nil
    end)
end

for _, inst in playerGui:GetDescendants() do
    attach(inst)
end
playerGui.DescendantAdded:Connect(attach)
