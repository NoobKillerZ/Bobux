-- Neon Arcade: script para ServerScriptService
-- Se ejecuta una sola vez por servidor. No modifica economia.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

Lighting.ClockTime = 17.25
Lighting.Brightness = 2.2
Lighting.ExposureCompensation = 0.05
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(62, 75, 116)
Lighting.OutdoorAmbient = Color3.fromRGB(96, 112, 154)
Lighting.ColorShift_Top = Color3.fromRGB(255, 205, 231)
Lighting.ColorShift_Bottom = Color3.fromRGB(35, 66, 100)
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.5
pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Realistic end)
pcall(function() Lighting.Technology = Enum.Technology.Future end)

local function effect(className, name, props)
    local instance = Lighting:FindFirstChild(name)
    if not instance or not instance:IsA(className) then
        if instance then instance:Destroy() end
        instance = Instance.new(className)
        instance.Name = name
        instance.Parent = Lighting
    end
    for property, value in pairs(props) do
        pcall(function() instance[property] = value end)
    end
    return instance
end

effect("Atmosphere", "BobuxAtmosphere", {
    Density = 0.19, Offset = 0.08,
    Color = Color3.fromRGB(175, 198, 255),
    Decay = Color3.fromRGB(70, 75, 118),
    Glare = 0.09, Haze = 0.75,
})
effect("BloomEffect", "BobuxBloom", {
    Intensity = 0.28, Threshold = 1.12, Size = 18,
})
effect("ColorCorrectionEffect", "BobuxColorGrade", {
    Brightness = 0.015, Contrast = 0.11,
    Saturation = 0.12, TintColor = Color3.fromRGB(235, 242, 255),
})
effect("SunRaysEffect", "BobuxSunRays", {
    Intensity = 0.035, Spread = 0.75,
})
-- DOF desactivado: la nitidez de la UI y del clicker es prioritaria.
effect("DepthOfFieldEffect", "BobuxDOF", {Enabled = false})

-- Importante: no modificar Terrain ni StreamingEnabled en runtime.
