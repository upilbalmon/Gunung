--// Services
local Players = game:GetService("Players")

--// Variables
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local createdFloor = nil  -- To store the created floor
local floorHeightMode = "below"  -- "below" or "above"

-- Hapus GUI lama bila ada
local OLD = playerGui:FindFirstChild("FloorCreatorGUI")
if OLD then OLD:Destroy() end

--// GUI
local MainFrame = Instance.new("ScreenGui")
MainFrame.Name = "FloorCreatorGUI"
MainFrame.Parent = playerGui
MainFrame.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 80, 0, 175)
Frame.Position = UDim2.new(0.8, -45, 0.6, -25)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.9
Frame.Parent = MainFrame
Frame.Draggable = false
Frame.Active = false

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
    button.TextColor3 = Color3.fromRGB(250, 250, 250)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.BackgroundTransparency = 0.5
    button.BorderSizePixel = 0
    button.Parent = ButtonsContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    return button
end

-- Create buttons
local UpButton = createButton(0, 30, "↑")
local CreateButton = createButton(35, 40, "FLOOR")
local DownButton = createButton(80, 30, "↓")
local HeightButton = createButton(115, 30, "BELOW")

-- Default values
local length = 1000
local width = 1000
local height = 0.1

-- Function to create the floor with offset
local function createFloor()
    local player = game.Players.LocalPlayer
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        warn("HumanoidRootPart tidak ditemukan!")
        return
    end
    
    -- Hancurkan lantai sebelumnya jika ada
    if createdFloor then
        createdFloor:Destroy()
    end
    
    -- Hitung posisi berdasarkan mode tinggi
    local position
    if floorHeightMode == "below" then
        position = hrp.Position - Vector3.new(0, 3, 0)  -- 3 stud di bawah
    else
        position = hrp.Position + Vector3.new(0, 10, 0)  -- 10 stud di atas
    end
    
    -- Buat part lantai
    createdFloor = Instance.new("Part")
    createdFloor.Size = Vector3.new(length, height, width)
    createdFloor.Position = position
    createdFloor.Anchored = true
    createdFloor.Color = Color3.fromRGB(0, 0, 0)
    createdFloor.Transparency = 0.7
    createdFloor.Material = Enum.Material.SmoothPlastic
    createdFloor.Parent = workspace
    
    -- Set timer untuk menghancurkan lantai setelah 60 detik
    task.delay(60, function()
        if createdFloor and createdFloor.Parent then
            createdFloor:Destroy()
            createdFloor = nil
        end
    end)
end

-- Button function to create floor
CreateButton.MouseButton1Click:Connect(function()
    createFloor()
end)

-- Height toggle button functionality
HeightButton.MouseButton1Click:Connect(function()
    if floorHeightMode == "below" then
        floorHeightMode = "above"
        HeightButton.Text = "ABOVE"
    else
        floorHeightMode = "below"
        HeightButton.Text = "BELOW"
    end
    
    -- Update floor position if it exists
    if createdFloor then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if floorHeightMode == "below" then
                createdFloor.Position = hrp.Position - Vector3.new(0, 3, 0)
            else
                createdFloor.Position = hrp.Position + Vector3.new(0, 10, 0)
            end
        end
    end
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
setupButtonHover(HeightButton)
