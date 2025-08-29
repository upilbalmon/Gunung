-- Shield Armor dengan Regen terus menerus + Tombol ON/OFF di layar
-- LocalScript (executor)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Konfigurasi
local MAX_SHIELD = 10000
local RECHARGE_RATE = 100 -- regen per detik

-- Status
local ShieldHP = MAX_SHIELD
local shieldOn = false
local shieldBall = nil
local guiBar = nil
local shieldButton = nil

-- Buat bola shield
local function createShield()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    if char:FindFirstChild("ShieldBall") then
        char.ShieldBall:Destroy()
    end

    local size = char:GetExtentsSize()
    local diameter = math.max(size.X, size.Y, size.Z) + 3

    local ball = Instance.new("Part")
    ball.Name = "ShieldBall"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(diameter, diameter, diameter)
    ball.CanCollide = false
    ball.Anchored = false
    ball.Massless = true
    ball.Transparency = 0.5
    ball.Material = Enum.Material.ForceField
    ball.Color = Color3.fromRGB(100, 180, 255)
    ball.Parent = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = ball
    weld.Part1 = hrp
    weld.Parent = ball

    shieldBall = ball
end

-- Buat GUI bar sederhana
local function createGUIBar()
    if guiBar then guiBar:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ShieldGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 20)
    frame.Position = UDim2.new(0.5, -100, 1, -100)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.Parent = gui

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    bar.BorderSizePixel = 0
    bar.Parent = frame

    guiBar = bar
end

-- Update GUI bar
local function updateBar()
    if guiBar then
        guiBar.Size = UDim2.new(ShieldHP / MAX_SHIELD, 0, 1, 0)
    end
end

-- Absorb damage
local function absorbDamage(amount)
    if ShieldHP > 0 then
        ShieldHP = math.max(0, ShieldHP - amount)
        updateBar()
        return true
    else
        return false
    end
end

-- Monitor damage masuk
local function monitorDamage()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")

    hum.HealthChanged:Connect(function(newHP)
        if newHP < hum.MaxHealth then
            local diff = hum.MaxHealth - newHP
            local blocked = absorbDamage(diff)
            if blocked then
                hum.Health = hum.MaxHealth -- cancel damage
            end
        end
    end)
end

-- Regen otomatis terus
task.spawn(function()
    while task.wait(1) do
        if shieldOn and ShieldHP < MAX_SHIELD then
            ShieldHP = math.min(MAX_SHIELD, ShieldHP + RECHARGE_RATE)
            updateBar()
        end
    end
end)

-- Buat tombol ON/OFF di layar
local function createButton()
    if shieldButton then shieldButton:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ShieldButtonGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(120, 50)
    button.Position = UDim2.new(1, -140, 1, -80) -- pojok kanan bawah
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = "Shield: OFF"
    button.TextScaled = true
    button.Parent = gui

    -- style bulat
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    shieldButton = button

    button.MouseButton1Click:Connect(function()
        local char = player.Character or player.CharacterAdded:Wait()
        if shieldOn then
            if shieldBall then shieldBall:Destroy() end
            if guiBar then guiBar.Parent.Parent:Destroy() end
            shieldOn = false
            button.Text = "Shield: OFF"
            button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            print("Shield OFF")
        else
            ShieldHP = MAX_SHIELD
            createShield()
            createGUIBar()
            monitorDamage()
            updateBar()
            shieldOn = true
            button.Text = "Shield: ON"
            button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            print("Shield ON")
        end
    end)
end

-- Auto apply pas respawn
player.CharacterAdded:Connect(function()
    if shieldOn then
        task.wait(0.5)
        createShield()
        monitorDamage()
    end
end)

-- Jalankan tombol
createButton()

print("Shield script aktif. Gunakan tombol di layar untuk ON/OFF.")
