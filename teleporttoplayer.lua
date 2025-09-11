-- Script untuk Executor (Tempel di Executor)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Hapus GUI lama jika ada
if CoreGui:FindFirstChild("TeleportGUI") then
    CoreGui:FindFirstChild("TeleportGUI"):Destroy()
end

-- Buat GUI
local TeleportGUI = Instance.new("ScreenGui")
TeleportGUI.Name = "TeleportGUI"
TeleportGUI.Parent = CoreGui
TeleportGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = TeleportGUI

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "TELEPORT KE PEMAIN"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 8)
UICorner2.Parent = Title

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -20, 0, 30)
SearchBox.Position = UDim2.new(0, 10, 0, 45)
SearchBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.PlaceholderText = "Cari pemain..."
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 14
SearchBox.Parent = MainFrame

local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0, 4)
UICorner3.Parent = SearchBox

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Name = "PlayerListFrame"
PlayerListFrame.Size = UDim2.new(1, -20, 0, 250)
PlayerListFrame.Position = UDim2.new(0, 10, 0, 85)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.ScrollBarThickness = 5
PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerListFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = PlayerListFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 345)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Text = "Pilih pemain untuk di-teleport"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 100, 0, 40)
CloseButton.Position = UDim2.new(0.5, -50, 1, -50)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "Tutup"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = MainFrame

local UICorner4 = Instance.new("UICorner")
UICorner4.CornerRadius = UDim.new(0, 4)
UICorner4.Parent = CloseButton

-- Fungsi untuk membuat tombol pemain
local function createPlayerButton(player)
    local PlayerButton = Instance.new("TextButton")
    PlayerButton.Name = player.Name
    PlayerButton.Size = UDim2.new(1, 0, 0, 40)
    PlayerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerButton.Text = player.Name
    PlayerButton.Font = Enum.Font.Gotham
    PlayerButton.TextSize = 14
    PlayerButton.AutoButtonColor = true
    PlayerButton.Parent = PlayerListFrame
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = PlayerButton
    
    return PlayerButton
end

-- Fungsi untuk memperbarui daftar pemain
local function updatePlayerList(searchTerm)
    -- Hapus semua tombol pemain yang ada
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Dapatkan daftar pemain dan urutkan berdasarkan nama
    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    
    -- Buat tombol untuk setiap pemain (kecuali diri sendiri)
    for _, player in ipairs(players) do
        if player ~= LocalPlayer then
            if searchTerm == "" or player.Name:lower():find(searchTerm:lower()) then
                local button = createPlayerButton(player)
                
                button.MouseButton1Click:Connect(function()
                    StatusLabel.Text = "Mencoba teleport ke " .. player.Name
                    
                    -- Teleport ke pemain yang dipilih
                    local success, errorMsg = pcall(function()
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
                            StatusLabel.Text = "Berhasil teleport ke " .. player.Name
                        else
                            StatusLabel.Text = "Karakter pemain tidak ditemukan"
                        end
                    end)
                    
                    if not success then
                        StatusLabel.Text = "Error: " .. errorMsg
                    end
                end)
            end
        end
    end
end

-- Fungsi untuk mencari pemain
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updatePlayerList(SearchBox.Text)
end)

-- Tombol tutup
CloseButton.MouseButton1Click:Connect(function()
    TeleportGUI:Destroy()
end)

-- Perbarui daftar pemain saat pertama kali dibuka
updatePlayerList("")

-- Perbarui daftar ketika pemain bergabung atau keluar
Players.PlayerAdded:Connect(function(player)
    updatePlayerList(SearchBox.Text)
end)

Players.PlayerRemoving:Connect(function(player)
    updatePlayerList(SearchBox.Text)
end)

-- Bukan GUI bisa di-drag
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

warn("Script Teleport GUI Loaded! Use at your own risk.")
