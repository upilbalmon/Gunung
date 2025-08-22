--// Services
local Players = game:GetService("Players")

--// Variables
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local createdFloor = nil  -- To store the created floor

--// GUI
local MainFrame = Instance.new("ScreenGui")
MainFrame.Name = "FloorCreatorGUI"
MainFrame.Parent = playerGui
MainFrame.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 200)  -- More compact size
Frame.Position = UDim2.new(0.5, -125, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.2
Frame.Parent = MainFrame
Frame.Draggable = true  -- Mempertahankan fungsi drag asli
Frame.Active = true     -- Mempertahankan fungsi drag asli

-- Add rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 24)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BackgroundTransparency = 0.3
TitleBar.Parent = Frame

-- Rounded corners for title bar
local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 8)
TitleBarCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Text = "Floor Creator"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamMedium
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -24, 0, 0)
CloseButton.Text = "×"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
CloseButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CloseButton.BackgroundTransparency = 0.3
CloseButton.BorderSizePixel = 0
CloseButton.Parent = TitleBar

-- Input fields container
local InputsContainer = Instance.new("Frame")
InputsContainer.Size = UDim2.new(1, -20, 0, 80)
InputsContainer.Position = UDim2.new(0, 10, 0, 30)
InputsContainer.BackgroundTransparency = 1
InputsContainer.Parent = Frame

-- Function to create input row
local function createInputRow(yPosition, labelText, defaultValue, placeholder)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 50, 0, 20)
    label.Position = UDim2.new(0, 0, 0, yPosition)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = InputsContainer
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 50, 0, 22)
    textBox.Position = UDim2.new(0, 55, 0, yPosition)
    textBox.Text = defaultValue
    textBox.PlaceholderText = placeholder
    textBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    textBox.BackgroundTransparency = 0.3
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.Parent = InputsContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = textBox
    
    return textBox
end

-- Create input fields
local LengthBox = createInputRow(0, "Length:", "5", "Length")
local WidthBox = createInputRow(25, "Width:", "5", "Width")
local HeightBox = createInputRow(50, "Height:", "1", "Height")
local OffsetBox = createInputRow(75, "Offset:", "0", "Offset")

-- Buttons container
local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Size = UDim2.new(1, -20, 0, 70)
ButtonsContainer.Position = UDim2.new(0, 10, 0, 115)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.Parent = Frame

-- Function to create styled button
local function createButton(xPosition, yPosition, width, text)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, width, 0, 28)
    button.Position = UDim2.new(0, xPosition, 0, yPosition)
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.BackgroundTransparency = 0.3
    button.BorderSizePixel = 0
    button.Parent = ButtonsContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    return button
end

-- Create buttons
local CreateButton = createButton(0, 0, 100, "Create Floor")
local ShiftUpButton = createButton(110, 0, 50, "Up")
local ShiftDownButton = createButton(110, 35, 50, "Down")

-- Function to create the floor with offset
local function createFloor(length, width, height, offset)
    local player = game.Players.LocalPlayer
    local hrp = player.Character.HumanoidRootPart
    -- Adjust position based on the offset
    local position = hrp.Position - Vector3.new(0, hrp.Size.Y/2, 0) + Vector3.new(0, offset, 0)
    
    if createdFloor then
        createdFloor:Destroy()
    end
    
    createdFloor = Instance.new("Part")
    createdFloor.Size = Vector3.new(length, height, width)
    createdFloor.Position = position
    createdFloor.Anchored = true
    createdFloor.Color = Color3.fromRGB(100, 100, 100)
    createdFloor.Material = Enum.Material.SmoothPlastic
    createdFloor.Parent = workspace
end

-- Button function to create floor
CreateButton.MouseButton1Click:Connect(function()
    local length = tonumber(LengthBox.Text) or 5
    local width = tonumber(WidthBox.Text) or 5
    local height = tonumber(HeightBox.Text) or 1
    local offset = tonumber(OffsetBox.Text) or 0

    createFloor(length, width, height, offset)
end)

-- Close button function
CloseButton.MouseButton1Click:Connect(function()
    MainFrame:Destroy()
end)

-- Flags to control continuous movement
local movingUpFlag = false
local movingDownFlag = false

ShiftUpButton.MouseButton1Click:Connect(function()
    movingUpFlag = not movingUpFlag
    movingDownFlag = false
    
    while movingUpFlag and createdFloor do
        createdFloor.Position = createdFloor.Position + Vector3.new(0, 1, 0)
        wait(0.1)
    end
end)

ShiftDownButton.MouseButton1Click:Connect(function()
    movingDownFlag = not movingDownFlag
    movingUpFlag = false
    
    while movingDownFlag and createdFloor do
        createdFloor.Position = createdFloor.Position - Vector3.new(0, 1, 0)
        wait(0.1)
    end
end)

-- Button hover effects
local function setupButtonHover(button)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
end

setupButtonHover(CreateButton)
setupButtonHover(ShiftUpButton)
setupButtonHover(ShiftDownButton)

-- Close button special hover
CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
end)
