local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Default values
local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPHEIGHT = 50.0

-- Mode values
local speedModes = {
    Slow = 8,
    Normal = 16,
    Fast  = 32,
    Super = 46
}

local jumpModes = {
    Normal = 50.0,
    Medium = 100.0,
    High = 400.0,
    Super = 1200.0
}

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedJumpGUI"
ScreenGui.Parent = Player.PlayerGui

-- Main Frame - POSISI DI TENGAH SIMPLE
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Posisi di tengah
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Anchor point di tengah
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 0.4
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true

-- Add rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title Bar untuk draggable area yang lebih baik
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BackgroundTransparency = 0.6
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

-- Add rounded corners to title bar
local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 8)
TitleBarCorner.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 2)
CloseButton.BackgroundColor3 = Color3.fromRGB(215, 60, 60)
CloseButton.BackgroundTransparency = 0.4
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 16
CloseButton.Parent = TitleBar

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(0, 12)
CloseButtonCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Speed & Jump Controller"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Walk Speed Section
local SpeedTitle = Instance.new("TextLabel")
SpeedTitle.Size = UDim2.new(1, -20, 0, 20)
SpeedTitle.Position = UDim2.new(0, 10, 0, 40)
SpeedTitle.BackgroundTransparency = 1
SpeedTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedTitle.Text = "Walk Speed"
SpeedTitle.Font = Enum.Font.SourceSansBold
SpeedTitle.TextSize = 16
SpeedTitle.TextXAlignment = Enum.TextXAlignment.Left
SpeedTitle.Parent = MainFrame

-- Speed Buttons Container
local SpeedButtonsFrame = Instance.new("Frame")
SpeedButtonsFrame.Size = UDim2.new(1, -20, 0, 30)
SpeedButtonsFrame.Position = UDim2.new(0, 10, 0, 65)
SpeedButtonsFrame.BackgroundTransparency = 1
SpeedButtonsFrame.Parent = MainFrame

-- UIListLayout for speed buttons
local SpeedUIListLayout = Instance.new("UIListLayout")
SpeedUIListLayout.FillDirection = Enum.FillDirection.Horizontal
SpeedUIListLayout.Padding = UDim.new(0, 2)
SpeedUIListLayout.Parent = SpeedButtonsFrame

-- Speed Buttons
local speedButtons = {}
local speedModeNames = {"Slow", "Normal", "Double", "Triple"}

for _, modeName in ipairs(speedModeNames) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1 / #speedModeNames, -2, 1, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    button.BackgroundTransparency = 0.4
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = modeName
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.Name = modeName
    button.Parent = SpeedButtonsFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        Humanoid.WalkSpeed = speedModes[modeName]
    end)
    
    speedButtons[modeName] = button
end

-- Jump Power Section
local JumpTitle = Instance.new("TextLabel")
JumpTitle.Size = UDim2.new(1, -20, 0, 20)
JumpTitle.Position = UDim2.new(0, 10, 0, 100)
JumpTitle.BackgroundTransparency = 1
JumpTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
JumpTitle.Text = "Jump Power"
JumpTitle.Font = Enum.Font.SourceSansBold
JumpTitle.TextSize = 16
JumpTitle.TextXAlignment = Enum.TextXAlignment.Left
JumpTitle.Parent = MainFrame

-- Jump Buttons Container
local JumpButtonsFrame = Instance.new("Frame")
JumpButtonsFrame.Size = UDim2.new(1, -20, 0, 30)
JumpButtonsFrame.Position = UDim2.new(0, 10, 0, 125)
JumpButtonsFrame.BackgroundTransparency = 1
JumpButtonsFrame.Parent = MainFrame

-- UIListLayout for jump buttons
local JumpUIListLayout = Instance.new("UIListLayout")
JumpUIListLayout.FillDirection = Enum.FillDirection.Horizontal
JumpUIListLayout.Padding = UDim.new(0, 2)
JumpUIListLayout.Parent = JumpButtonsFrame

-- Jump Buttons
local jumpButtons = {}
local jumpModeNames = {"Normal", "Double", "Quadruple", "Octuple"}

for _, modeName in ipairs(jumpModeNames) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1 / #jumpModeNames, -2, 1, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    button.BackgroundTransparency = 0.4
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = modeName
    button.Font = Enum.Font.SourceSans
    button.TextSize = 12
    button.Name = modeName
    button.Parent = JumpButtonsFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        -- Coba kedua metode untuk kompatibilitas
        pcall(function()
            Humanoid.JumpPower = jumpModes[modeName]
        end)
        pcall(function()
            Humanoid.JumpHeight = jumpModes[modeName] / 7.0
        end)
    end)
    
    jumpButtons[modeName] = button
end

-- Custom Inputs
local CustomSpeedFrame = Instance.new("Frame")
CustomSpeedFrame.Size = UDim2.new(1, -20, 0, 30)
CustomSpeedFrame.Position = UDim2.new(0, 10, 0, 160)
CustomSpeedFrame.BackgroundTransparency = 1
CustomSpeedFrame.Parent = MainFrame

local CustomSpeedBox = Instance.new("TextBox")
CustomSpeedBox.Size = UDim2.new(0, 120, 0, 30)
CustomSpeedBox.Position = UDim2.new(0, 0, 0, 0)
CustomSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CustomSpeedBox.BackgroundTransparency = 0.6
CustomSpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomSpeedBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
CustomSpeedBox.PlaceholderText = "Custom Speed"
CustomSpeedBox.Text = ""
CustomSpeedBox.Font = Enum.Font.SourceSans
CustomSpeedBox.TextSize = 14
CustomSpeedBox.Parent = CustomSpeedFrame

local CustomSpeedCorner = Instance.new("UICorner")
CustomSpeedCorner.CornerRadius = UDim.new(0, 6)
CustomSpeedCorner.Parent = CustomSpeedBox

local SetCustomSpeed = Instance.new("TextButton")
SetCustomSpeed.Size = UDim2.new(0, 50, 0, 30)
SetCustomSpeed.Position = UDim2.new(0, 125, 0, 0)
SetCustomSpeed.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SetCustomSpeed.BackgroundTransparency = 0.4
SetCustomSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
SetCustomSpeed.Text = "Set"
SetCustomSpeed.Font = Enum.Font.SourceSans
SetCustomSpeed.TextSize = 14
SetCustomSpeed.Parent = CustomSpeedFrame

local SetSpeedCorner = Instance.new("UICorner")
SetSpeedCorner.CornerRadius = UDim.new(0, 6)
SetSpeedCorner.Parent = SetCustomSpeed

SetCustomSpeed.MouseButton1Click:Connect(function()
    local speed = tonumber(CustomSpeedBox.Text)
    if speed and speed > 0 then
        Humanoid.WalkSpeed = speed
    else
        CustomSpeedBox.Text = "Invalid"
    end
end)

local CustomJumpFrame = Instance.new("Frame")
CustomJumpFrame.Size = UDim2.new(1, -20, 0, 30)
CustomJumpFrame.Position = UDim2.new(0, 10, 0, 195)
CustomJumpFrame.BackgroundTransparency = 1
CustomJumpFrame.Parent = MainFrame

local CustomJumpBox = Instance.new("TextBox")
CustomJumpBox.Size = UDim2.new(0, 120, 0, 30)
CustomJumpBox.Position = UDim2.new(0, 0, 0, 0)
CustomJumpBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CustomJumpBox.BackgroundTransparency = 0.6
CustomJumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomJumpBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
CustomJumpBox.PlaceholderText = "Custom Jump"
CustomJumpBox.Text = ""
CustomJumpBox.Font = Enum.Font.SourceSans
CustomJumpBox.TextSize = 14
CustomJumpBox.Parent = CustomJumpFrame

local CustomJumpCorner = Instance.new("UICorner")
CustomJumpCorner.CornerRadius = UDim.new(0, 6)
CustomJumpCorner.Parent = CustomJumpBox

local SetCustomJump = Instance.new("TextButton")
SetCustomJump.Size = UDim2.new(0, 50, 0, 30)
SetCustomJump.Position = UDim2.new(0, 125, 0, 0)
SetCustomJump.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SetCustomJump.BackgroundTransparency = 0.4
SetCustomJump.TextColor3 = Color3.fromRGB(255, 255, 255)
SetCustomJump.Text = "Set"
SetCustomJump.Font = Enum.Font.SourceSans
SetCustomJump.TextSize = 14
SetCustomJump.Parent = CustomJumpFrame

local SetJumpCorner = Instance.new("UICorner")
SetJumpCorner.CornerRadius = UDim.new(0, 6)
SetJumpCorner.Parent = SetCustomJump

SetCustomJump.MouseButton1Click:Connect(function()
    local jump = tonumber(CustomJumpBox.Text)
    if jump and jump > 0 then
        -- Coba kedua metode untuk kompatibilitas
        pcall(function()
            Humanoid.JumpPower = jump
        end)
        pcall(function()
            Humanoid.JumpHeight = jump / 7.0
        end)
    else
        CustomJumpBox.Text = "Invalid"
    end
end)

-- Reset Button
local ResetButton = Instance.new("TextButton")
ResetButton.Size = UDim2.new(1, -20, 0, 40)
ResetButton.Position = UDim2.new(0, 10, 0, 235)
ResetButton.BackgroundColor3 = Color3.fromRGB(215, 60, 60)
ResetButton.BackgroundTransparency = 0.4
ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetButton.Text = "Reset to Default"
ResetButton.Font = Enum.Font.SourceSansBold
ResetButton.TextSize = 16
ResetButton.Parent = MainFrame

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 6)
ResetCorner.Parent = ResetButton

ResetButton.MouseButton1Click:Connect(function()
    Humanoid.WalkSpeed = DEFAULT_WALKSPEED
    -- Reset kedua metode
    pcall(function()
        Humanoid.JumpPower = DEFAULT_JUMPHEIGHT
    end)
    pcall(function()
        Humanoid.JumpHeight = DEFAULT_JUMPHEIGHT / 7.0
    end)
    CustomSpeedBox.Text = ""
    CustomJumpBox.Text = ""
end)

-- Handle character respawns
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    
    Humanoid.WalkSpeed = DEFAULT_WALKSPEED
    -- Set kedua metode
    pcall(function()
        Humanoid.JumpPower = DEFAULT_JUMPHEIGHT
    end)
    pcall(function()
        Humanoid.JumpHeight = DEFAULT_JUMPHEIGHT / 7.0
    end)
end)
