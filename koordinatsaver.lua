-- LocalScript di StarterGui (ScreenGui)

local player = game.Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LocationSaverGui"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame container
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 160)
Frame.Position = UDim2.new(0.7, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BackgroundTransparency = 0.2
Frame.Active = true          -- supaya bisa di-drag
Frame.Draggable = true       -- buat draggable
Frame.Parent = ScreenGui

-- Judul
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.Text = "📍 Location Saver"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Parent = Frame

-- TextBox
local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 0, 30)
TextBox.Position = UDim2.new(0, 10, 0, 40)
TextBox.PlaceholderText = "Masukkan nama lokasi"
TextBox.Text = ""
TextBox.Parent = Frame

-- Save Button
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(1, -20, 0, 30)
SaveButton.Position = UDim2.new(0, 10, 0, 80)
SaveButton.Text = "Simpan Lokasi"
SaveButton.Parent = Frame

-- Print Button
local PrintButton = Instance.new("TextButton")
PrintButton.Size = UDim2.new(1, -20, 0, 30)
PrintButton.Position = UDim2.new(0, 10, 0, 120)
PrintButton.Text = "Print & Copy"
PrintButton.Parent = Frame

-- Memory sementara
local savedLocations = {}

-- Simpan lokasi
SaveButton.MouseButton1Click:Connect(function()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	local pos = player.Character.HumanoidRootPart.Position
	local name = TextBox.Text

	if name == "" then
		warn("Nama lokasi tidak boleh kosong!")
		return
	end

	savedLocations[name] = pos
	print("Lokasi '"..name.."' tersimpan:", pos)
	TextBox.Text = "" -- reset setelah simpan
end)

-- Print + Copy ke Clipboard (format tabel Lua)
PrintButton.MouseButton1Click:Connect(function()
	if next(savedLocations) == nil then
		warn("Belum ada lokasi tersimpan.")
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
		print("✅ Hasil sudah dicopy ke clipboard.")
	else
		warn("❌ setclipboard tidak tersedia di environment ini.")
	end
end)
