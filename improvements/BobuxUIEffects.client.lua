-- UI polish no destructivo para StarterPlayerScripts
-- Detecta los botones ya existentes del juego, sin reemplazar Client.lua.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACCENT = Color3.fromRGB(53, 216, 255)
local configs = setmetatable({}, {__mode = "k"})
local sound = SoundService:FindFirstChild("BobuxUiClick")
if not sound then
    sound = Instance.new("Sound")
    sound.Name = "BobuxUiClick"
    sound.Volume = 0.18
    -- Asigna aqui un ID de audio propio/permitido cuando este disponible.
    sound.SoundId = ""
    sound.Parent = SoundService
end

local function tween(target, duration, style, direction, props)
    local animation = TweenService:Create(target,
        TweenInfo.new(duration, style, direction), props)
    animation:Play()
    return animation
end

local function polish(button)
    if configs[button] or not button:IsA("GuiButton") then return end
    configs[button] = true
    button.AutoButtonColor = false
    local scale = button:FindFirstChild("BobuxHoverScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = "BobuxHoverScale"
        scale.Parent = button
    end
    local originalColor = button.BackgroundColor3
    local hovered = false
    local function updateHover(active)
        hovered = active
        tween(scale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            {Scale = active and 1.045 or 1})
        if button.BackgroundTransparency < 0.95 then
            tween(button, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                {BackgroundColor3 = active and originalColor:Lerp(ACCENT, 0.13) or originalColor})
        end
    end
    button.MouseEnter:Connect(function()
        if not UserInputService.TouchEnabled then updateHover(true) end
    end)
    button.MouseLeave:Connect(function() updateHover(false) end)
    button.Activated:Connect(function()
        if sound.SoundId ~= "" then sound:Play() end
        scale.Scale = 0.94
        tween(scale, 0.31, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
            {Scale = hovered and 1.045 or 1})
    end)
end
for _, descendant in ipairs(playerGui:GetDescendants()) do polish(descendant) end
playerGui.DescendantAdded:Connect(polish)
