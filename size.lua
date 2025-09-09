-- LocalScript, tempatkan di dalam tombol (Button) atau di dalam ScreenGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variabel UI
local carryButton = script.Parent -- Tombol Carry
local playerDropdown = carryButton.Parent:WaitForChild("PlayerDropdown") -- Ganti dengan nama Dropdown Anda

-- Event
local requestCarry = ReplicatedStorage:WaitForChild("CarryEvents"):WaitForChild("RequestCarry")

-- Fungsi untuk memperbarui daftar pemain di Dropdown
local function updatePlayerList()
	-- Hapus semua opsi yang ada terlebih dahulu
	playerDropdown:ClearAllChildren()
	
	-- Tambahkan opsi untuk setiap pemain yang ada di game
	for _, player in ipairs(Players:GetPlayers()) do
		local newOption = Instance.new("StringValue")
		newOption.Name = "Option"
		newOption.Value = player.Name
		newOption.Parent = playerDropdown
	end
end

-- Fungsi saat tombol ditekan
local function onCarryClicked()
	local selectedPlayerName = playerDropdown.Value -- Ambil nama pemain yang dipilih dari Dropdown
	
	-- Cek apakah ada pemain yang dipilih
	if selectedPlayerName == "" then
		warn("Pilih pemain dari daftar!")
		return
	end
	
	local targetPlayer = Players:FindFirstChild(selectedPlayerName)
	
	if targetPlayer then
		requestCarry:FireServer(targetPlayer)
		print("Remote event dikirim untuk membawa " .. selectedPlayerName)
	else
		warn("Player " .. selectedPlayerName .. " tidak ditemukan!")
	end
end

-- Hubungkan fungsi ke event tombol
carryButton.Activated:Connect(onCarryClicked)

-- Perbarui daftar pemain saat skrip dimulai
updatePlayerList()

-- Hubungkan ke event PlayerAdded dan PlayerRemoving untuk memperbarui daftar secara dinamis
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

