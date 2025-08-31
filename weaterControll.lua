local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Settings for perfect sunny day
local WEATHER_SETTINGS = {
    -- Time settings
    ClockTime = 12, -- Noon (12:00)
    
    -- Lighting settings
    Brightness = 2,
    GlobalShadows = true,
    Ambient = Color3.fromRGB(128, 128, 128),
    OutdoorAmbient = Color3.fromRGB(128, 128, 128),
    
    -- Sky settings
    FogStart = 1000,
    FogEnd = 10000,
    FogColor = Color3.fromRGB(191, 191, 191),
    
    -- Color correction
    ExposureCompensation = 0,
    
    -- Atmosphere settings
    ColorShift_Top = Color3.fromRGB(255, 255, 255),
    ColorShift_Bottom = Color3.fromRGB(255, 255, 255),
    
    -- Sun properties
    SunAngle = 0, -- Directly overhead
}

-- Function to apply weather settings
local function applySunnyDaySettings()
    -- Apply all settings
    for property, value in pairs(WEATHER_SETTINGS) do
        pcall(function()
            Lighting[property] = value
        end)
    end
    
    -- Additional sky settings
    Lighting.GeographicLatitude = 0 -- Equator for consistent sun
    
    -- Disable weather effects
    if Lighting:FindFirstChild("Rain") then
        Lighting.Rain.Enabled = false
    end
    
    if Lighting:FindFirstChild("Snow") then
        Lighting.Snow.Enabled = false
    end
    
    -- Clear any existing clouds
    if Lighting:FindFirstChild("Clouds") then
        Lighting.Clouds.Enabled = false
    end
end

-- Function to create a beautiful sky
local function createBeautifulSky()
    -- Remove existing atmospheres
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Atmosphere") or child:IsA("Sky") then
            child:Destroy()
        end
    end
    
    -- Create perfect atmosphere
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "PerfectAtmosphere"
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 170, 107)
    atmosphere.Decay = Color3.fromRGB(106, 142, 192)
    atmosphere.Glare = 0
    atmosphere.Haze = 0
    atmosphere.Parent = Lighting
    
    -- Create beautiful sky
    local sky = Instance.new("Sky")
    sky.Name = "PerfectSky"
    sky.SkyboxBk = "rbxassetid://6444881965" -- Blue sky
    sky.SkyboxDn = "rbxassetid://6444881965" -- Blue sky
    sky.SkyboxFt = "rbxassetid://6444881965" -- Blue sky
    sky.SkyboxLf = "rbxassetid://6444881965" -- Blue sky
    sky.SkyboxRt = "rbxassetid://6444881965" -- Blue sky
    sky.SkyboxUp = "rbxassetid://6444881965" -- Blue sky
    sky.Parent = Lighting
end

-- Function to lock time and prevent changes
local function lockTime()
    Lighting.ClockTime = WEATHER_SETTINGS.ClockTime
    
    -- Disable time progression
    if Lighting:FindFirstChild("TimeOfDay") then
        Lighting:FindFirstChild("TimeOfDay"):Destroy()
    end
end

-- Main function to setup eternal sunny day
local function setupEternalSunnyDay()
    print("Setting up eternal sunny day...")
    
    -- Apply initial settings
    applySunnyDaySettings()
    createBeautifulSky()
    lockTime()
    
    -- Continuous enforcement
    local connection
    connection = RunService.Heartbeat:Connect(function()
        -- Keep time locked at noon
        Lighting.ClockTime = WEATHER_SETTINGS.ClockTime
        
        -- Re-apply settings periodically to prevent changes
        applySunnyDaySettings()
        
        -- Ensure sky remains perfect
        if not Lighting:FindFirstChild("PerfectAtmosphere") or not Lighting:FindFirstChild("PerfectSky") then
            createBeautifulSky()
        end
    end)
    
    -- Cleanup when script is destroyed
    game.Destroying:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)
    
    print("Eternal sunny day activated! Weather is now locked to perfect conditions.")
end

-- GUI for control (optional)
local function createControlGUI()
    local Player = game.Players.LocalPlayer
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WeatherControlGUI"
    ScreenGui.Parent = Player.PlayerGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 60)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 20)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Text = "Weather Control: ON"
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 14
    Title.Parent = MainFrame
    
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0, 20)
    Status.Position = UDim2.new(0, 0, 0, 20)
    Status.BackgroundTransparency = 1
    Status.TextColor3 = Color3.fromRGB(144, 238, 144) -- Light green
    Status.Text = "Sunny Day ☀️"
    Status.Font = Enum.Font.SourceSans
    Status.TextSize = 12
    Status.Parent = MainFrame
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(1, 0, 0, 20)
    TimeLabel.Position = UDim2.new(0, 0, 0, 40)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 150) -- Light yellow
    TimeLabel.Text = "Time: 12:00 (Noon)"
    TimeLabel.Font = Enum.Font.SourceSans
    TimeLabel.TextSize = 12
    TimeLabel.Parent = MainFrame
    
    return ScreenGui
end

-- Initialize
setupEternalSunnyDay()

-- Create control GUI (optional)
if game.Players.LocalPlayer then
    createControlGUI()
end

-- Handle player joining
game.Players.PlayerAdded:Connect(function(player)
    if player == game.Players.LocalPlayer then
        createControlGUI()
    end
end)

print("Eternal sunny day script loaded successfully!")
print("Weather is now locked to perfect sunny conditions")
