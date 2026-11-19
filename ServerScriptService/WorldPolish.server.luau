--!strict
-- Bobux Neon Arcade: atmosfera y detalles del mundo.
-- Script independiente: no altera monedas, DataStores ni RemoteEvents.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

Lighting.ClockTime = 17.25
Lighting.Brightness = 2.1
Lighting.ExposureCompensation = 0.05
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(63, 75, 115)
Lighting.OutdoorAmbient = Color3.fromRGB(92, 111, 150)
Lighting.ColorShift_Top = Color3.fromRGB(255, 211, 239)
Lighting.ColorShift_Bottom = Color3.fromRGB(35, 64, 103)
Lighting.EnvironmentDiffuseScale = 0.38
Lighting.EnvironmentSpecularScale = 0.48
pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Realistic end)

local function upsert(className: string, name: string): Instance
    local found = Lighting:FindFirstChild(name)
    if found and found.ClassName == className then
        return found
    end
    if found then found:Destroy() end
    local created = Instance.new(className)
    created.Name = name
    created.Parent = Lighting
    return created
end

local atmosphere = upsert("Atmosphere", "BobuxPolishAtmosphere") :: Atmosphere
atmosphere.Density = 0.17
atmosphere.Offset = 0.05
atmosphere.Color = Color3.fromRGB(178, 203, 255)
atmosphere.Decay = Color3.fromRGB(79, 86, 131)
atmosphere.Glare = 0.08
atmosphere.Haze = 0.65

local bloom = upsert("BloomEffect", "BobuxPolishBloom") :: BloomEffect
bloom.Intensity = 0.22
bloom.Threshold = 1.1
bloom.Size = 16

local grading = upsert("ColorCorrectionEffect", "BobuxPolishColor") :: ColorCorrectionEffect
grading.Brightness = 0.01
grading.Contrast = 0.1
grading.Saturation = 0.1
grading.TintColor = Color3.fromRGB(237, 244, 255)

local rays = upsert("SunRaysEffect", "BobuxPolishRays") :: SunRaysEffect
rays.Intensity = 0.025
rays.Spread = 0.7

local clicker = Workspace:FindFirstChild("Clicker")
if not clicker then
    warn("[BobuxPolish] No se encontro Clicker: se aplico solo la atmosfera.")
    return
end
local button = clicker:FindFirstChild("Button")
if not button or not button:IsA("BasePart") then return end

button.Material = Enum.Material.Neon
local light = button:FindFirstChildOfClass("PointLight")
if light then
    light.Brightness = 1.35
    light.Range = 18
end

local attachment = button:FindFirstChild("BobuxSparkAttachment")
if not attachment then
    attachment = Instance.new("Attachment")
    attachment.Name = "BobuxSparkAttachment"
    attachment.Position = Vector3.new(0, button.Size.Y * 0.55, 0)
    attachment.Parent = button
end
local sparks = attachment:FindFirstChild("IdleSparks")
if not sparks then
    sparks = Instance.new("ParticleEmitter")
    sparks.Name = "IdleSparks"
    sparks.Parent = attachment
end
if sparks:IsA("ParticleEmitter") then
    sparks.Enabled = true
    sparks.Rate = 2
    sparks.Lifetime = NumberRange.new(0.5, 0.9)
    sparks.Speed = NumberRange.new(0.6, 1.5)
    sparks.SpreadAngle = Vector2.new(35, 35)
    sparks.LightEmission = 0.75
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0)
    })
    sparks.Transparency = NumberSequence.new(0.25, 1)
    sparks.Color = ColorSequence.new(Color3.fromRGB(255, 196, 243), Color3.fromRGB(83, 225, 255))
end

for _, part in clicker:GetDescendants() do
    if part:IsA("BasePart") and string.find(part.Name, "Ring") then
        part.Material = Enum.Material.Neon
        part.CanCollide = false
        part.CanTouch = false
    end
end
local portal = Workspace:FindFirstChild("RebirthPortal")
if portal then
    for _, descendant in portal:GetDescendants() do
        if descendant:IsA("BasePart") and string.find(descendant.Name, "Ring") then
            descendant.Material = Enum.Material.Neon
            descendant.CanCollide = false
            descendant.CanTouch = false
        end
    end
end
print("[BobuxPolish] Atmo y detalles neon cargados.")
