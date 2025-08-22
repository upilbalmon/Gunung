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
Frame.Size = UDim2.new(0, 80, 0, 140)
Frame.Position = UDim2.new(0.5, -40, 0.5, -60)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.8
Frame.Parent = MainFrame
Frame.Draggable = true
Frame.Active = true

-- Add rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

-- Buttons container
local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Size = UDim2.new(1, -10, 1, -30)
ButtonsContainer.Position = UDim2.new(0, 5, 0, 25)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.Parent = Frame

-- Function to create styled button
local function createButton(yPosition, size, text)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, size, 0, size)
    button.Position = UDim2.new(0.5, -size/2, 0, yPosition)
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
local UpButton = createButton(0, 30, "↑")
local CreateButton = createButton(35, 40, "Create")
local DownButton = createButton(80, 30, "↓")

-- Default values
local length = 1000
local width = 1000
local height = 0.1
local offset = 0

-- Function to create the floor with offset
local function createFloor()
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
    createFloor()
end)

-- Variables for button states
local movingUp = false
local movingDown = false

-- Up button functionality
UpButton.MouseButton1Down:Connect(function()
    movingUp = true
    spawn(function()
        while movingUp and createdFloor do
            createdFloor.Position = createdFloor.Position + Vector3.new(0, 1, 0)
            wait(0.1)
        end
    end)
end)

UpButton.MouseButton1Up:Connect(function()
    movingUp = false
end)

UpButton.MouseLeave:Connect(function()
    movingUp = false
end)

-- Down button functionality
DownButton.MouseButton1Down:Connect(function()
    movingDown = true
    spawn(function()
        while movingDown and createdFloor do
            createdFloor.Position = createdFloor.Position - Vector3.new(0, 1, 0)
            wait(0.1)
        end
    end)
end)

DownButton.MouseButton1Up:Connect(function()
    movingDown = false
end)

DownButton.MouseLeave:Connect(function()
    movingDown = false
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
setupButtonHover(UpButton)
setupButtonHover(DownButton)
