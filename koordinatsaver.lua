-- LocalScript di StarterGui (ScreenGui)

local player = game.Players.LocalPlayer

-- Fungsi helper untuk kasih rounded corner
local function applyCorner(guiObject, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6) -- default 6px
    corner.Parent = guiObject
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LocationSaverGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame container
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 140)
Frame.Position = UDim2.new(0.7, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BackgroundTransparency = 0.2
Frame.Active = true          -- supaya bisa di-drag
Frame.Draggable = true       -- buat draggable
Frame.Parent = ScreenGui
applyCorner(Frame, 6)

-- Judul
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.Text = "📍 Location Saver"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Parent = Frame
applyCorner(Title, 6)

-- TextBox
local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 0, 30)
TextBox.Position = UDim2.new(0, 10, 0, 40)
TextBox.PlaceholderText = "Masukkan nama lokasi"
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BackgroundTransparency = 0.7
TextBox.Parent = Frame

-- ==== Tombol biru ====
local function styleBlueButton(btn)
    -- kalau ada fungsi styleElement, bisa dipanggil
    -- styleElement(btn)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- biru
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)     -- teks putih biar kontras
end

-- Save Button (kiri)
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.5, -15, 0, 30) -- setengah lebar
SaveButton.Position = UDim2.new(0, 10, 0, 80)
SaveButton.Text = "Simpan Lokasi"
SaveButton.Parent = Frame
styleBlueButton(SaveButton)
applyCorner(SaveButton, 6)

-- Print Button (kanan)
local PrintButton = Instance.new("TextButton")
PrintButton.Size = UDim2.new(0.5, -15, 0, 30) -- setengah lebar
PrintButton.Position = UDim2.new(0.5, 5, 0, 80)
PrintButton.Text = "Print & Copy"
PrintButton.Parent = Frame
styleBlueButton(PrintButton)
applyCorner(PrintButton, 6)

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 120) -- di bawah tombol
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 50)
StatusLabel.Text = "🔔 Siap digunakan"
StatusLabel.TextScaled = true
StatusLabel.Size = UDim2.new(1, -20, 0, 12)
StatusLabel.Parent = Frame

-- Memory sementara
local savedLocations = {}

-- Simpan lokasi
SaveButton.MouseButton1Click:Connect(function()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then 
		StatusLabel.Text = "❌ Character belum siap!"
		return 
	end

	local pos = player.Character.HumanoidRootPart.Position
	local name = TextBox.Text


	if name == "" then
		StatusLabel.Text = "⚠️ Nama lokasi tidak boleh kosong!"
		return
	end

	savedLocations[name] = pos
	StatusLabel.Text = "✅ Lokasi '"..name.."' tersimpan."
	TextBox.Text = "" -- reset setelah simpan
end)

-- Print + Copy ke Clipboard (format tabel Lua)
PrintButton.MouseButton1Click:Connect(function()
	if next(savedLocations) == nil then
		StatusLabel.Text = "⚠️ Belum ada lokasi tersimpan."
		return
	end

	local result = "local Locations = {\n"
	for name, pos in pairs(savedLocations) do
		result = result .. string.format('    ["%s"] = Vector3.new(%.2f, %.2f, %.2f),\n', name, pos.X, pos.Y, pos.Z)
	end
	result = result .. "}"

	print("Hasil Lokasi:\n"..result)

	if setclipboard then
		setclipboard(result)
		StatusLabel.Text = "✅ Lokasi dicopy ke clipboard."
	else
		StatusLabel.Text = "❌ setclipboard tidak tersedia."
	end
end)
