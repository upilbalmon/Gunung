-- LocalScript di StarterPlayer > StarterPlayerScripts

--===== Buat GUI =====--
local player = game.Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VirtualControls"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Tombol W
local forwardBtn = Instance.new("TextButton")
forwardBtn.Name = "ForwardButton"
forwardBtn.Size = UDim2.new(0,60,0,60)
forwardBtn.Position = UDim2.new(0.05,0,0.8,0) -- kiri bawah
forwardBtn.Text = "W"
forwardBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
forwardBtn.TextScaled = true
forwardBtn.Parent = screenGui

--===== Logika Gerak =====--
local function getHumanoid()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("Humanoid")
end

local moveForward = Vector3.new(0,0,-1) -- arah maju relatif kamera
local moving = false

local function updateMovement()
    local humanoid = getHumanoid()
    while moving do
        humanoid:Move(moveForward, true)
        task.wait()
    end
end

forwardBtn.MouseButton1Down:Connect(function()
    moving = true
    updateMovement()
end)

forwardBtn.MouseButton1Up:Connect(function()
    moving = false
    local humanoid = getHumanoid()
    humanoid:Move(Vector3.new(0,0,0), true)
end)
