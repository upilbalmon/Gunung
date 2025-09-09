-- LocalScript, tempatkan di StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local requestCarry = ReplicatedStorage:WaitForChild("CarryEvents"):WaitForChild("RequestCarry")

-- Variabel untuk melacak pemain yang dipilih
local selectedPlayerName = nil

-- === Buat GUI ===

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarryGUI"
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (Bingkai utama yang dapat digeser)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 400)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
mainFrame.BackgroundTransparency = 0.5
mainFrame.BorderColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- UICorner untuk rounded corner
local mainFrameCorner = Instance.new("UICorner")
mainFrameCorner.CornerRadius = UDim.new(0, 4)
mainFrameCorner.Parent = mainFrame

-- Tombol "Close"
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.new(1, 0.3, 0.3)
closeButton.BackgroundTransparency = 0.5
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 20
closeButton.Parent = mainFrame

local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 4)
closeButtonCorner.Parent = closeButton

-- Bingkai untuk konten fungsional
local functionalFrame = Instance.new("Frame")
functionalFrame.Name = "FunctionalFrame"
functionalFrame.Size = UDim2.new(1, -20, 1, -50)
functionalFrame.Position = UDim2.new(0, 10, 0, 40)
functionalFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
functionalFrame.BackgroundTransparency = 0.5
functionalFrame.Parent = mainFrame

local functionalFrameCorner = Instance.new("UICorner")
functionalFrameCorner.CornerRadius = UDim.new(0, 4)
functionalFrameCorner.Parent = functionalFrame

-- UIListLayout untuk menata tombol secara vertikal di dalam functionalFrame
local functionalLayout = Instance.new("UIListLayout")
functionalLayout.Padding = UDim.new(0, 10)
functionalLayout.Parent = functionalFrame

-- Tombol "Get Player List"
local getListButton = Instance.new("TextButton")
getListButton.Name = "GetListButton"
getListButton.Size = UDim2.new(1, 0, 0, 40)
getListButton.Text = "Get Player List"
getListButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
getListButton.BackgroundTransparency = 0.5
getListButton.TextColor3 = Color3.new(0, 0, 0)
getListButton.Parent = functionalFrame

local getListButtonCorner = Instance.new("UICorner")
getListButtonCorner.CornerRadius = UDim.new(0, 4)
getListButtonCorner.Parent = getListButton

-- Bingkai ScrollingFrame untuk daftar pemain
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Name = "PlayerListFrame"
playerListFrame.Size = UDim2.new(1, 0, 0, 200)
playerListFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
playerListFrame.BackgroundTransparency = 0.5
playerListFrame.BorderSizePixel = 2
playerListFrame.Visible = false
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.Parent = functionalFrame

local playerListFrameCorner = Instance.new("UICorner")
playerListFrameCorner.CornerRadius = UDim.new(0, 4)
playerListFrameCorner.Parent = playerListFrame

-- UIListLayout
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = playerListFrame

-- Tombol "Carry"
local carryButton = Instance.new("TextButton")
carryButton.Name = "CarryButton"
carryButton.Size = UDim2.new(1, 0, 0, 40)
carryButton.Text = "Carry"
carryButton.BackgroundColor3 = Color3.new(0.1, 0.6, 0.1)
carryButton.BackgroundTransparency = 0.5
carryButton.TextColor3 = Color3.new(1, 1, 1)
carryButton.Parent = functionalFrame

local carryButtonCorner = Instance.new("UICorner")
carryButtonCorner.CornerRadius = UDim.new(0, 4)
carryButtonCorner.Parent = carryButton

-- === Logika Skrip ===

local function updatePlayerList()
	for _, child in ipairs(playerListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local playerCount = #Players:GetPlayers()
	local buttonHeight = 35
	local padding = 5
	local totalHeight = playerCount * buttonHeight + (playerCount - 1) * padding
	
	playerListFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	for _, player in ipairs(Players:GetPlayers()) do
		local playerButton = Instance.new("TextButton")
		playerButton.Name = player.Name
		playerButton.Size = UDim2.new(1, -10, 0, 30)
		playerButton.Position = UDim2.new(0, 5, 0, 0)
		playerButton.Text = player.Name
		playerButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
		playerButton.BackgroundTransparency = 0.5
		playerButton.TextColor3 = Color3.new(1, 1, 1)
		playerButton.Parent = playerListFrame
		
		local playerButtonCorner = Instance.new("UICorner")
		playerButtonCorner.CornerRadius = UDim.new(0, 4)
		playerButtonCorner.Parent = playerButton

		playerButton.Activated:Connect(function()
			selectedPlayerName = player.Name
			playerListFrame.Visible = false
			print("Pemain '" .. selectedPlayerName .. "' dipilih.")
			carryButton.Text = "Carry " .. selectedPlayerName
		end)
	end
end

-- Hubungkan tombol "Get Player List"
getListButton.Activated:Connect(function()
	updatePlayerList()
	playerListFrame.Visible = true
end)

-- Hubungkan tombol "Carry"
carryButton.Activated:Connect(function()
	if selectedPlayerName then
		local targetPlayer = Players:FindFirstChild(selectedPlayerName)
		if targetPlayer then
			requestCarry:FireServer(targetPlayer)
			print("Remote event dikirim untuk membawa " .. selectedPlayerName)
		else
			warn("Pemain '" .. selectedPlayerName .. "' tidak ditemukan!")
		end
	else
		warn("Pilih pemain dari daftar terlebih dahulu!")
	end
end)

-- Hubungkan tombol "Close"
closeButton.Activated:Connect(function()
	mainFrame.Visible = false
end)
