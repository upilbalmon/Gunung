local button = script.Parent
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local isScaled = false

local originalScale = character.Humanoid.HeadScale.Value
local originalBodyScale = character.Humanoid.BodyDepthScale.Value
local originalHeightScale = character.Humanoid.BodyHeightScale.Value
local originalWidthScale = character.Humanoid.BodyWidthScale.Value

local scaledFactor = 2 -- Mengubah ukuran karakter menjadi 2x lipat

button.MouseButton1Click:Connect(function()
	-- Pastikan karakter ada sebelum mencoba mengubahnya
	if not character or not character.Parent then
		character = player.Character or player.CharacterAdded:Wait()
		if not character or not character.Parent then return end -- Keluar jika karakter masih tidak ada
	end

	-- Cek apakah properti HeadScale, BodyDepthScale, dll., ada
	if not character:FindFirstChild("Humanoid") then return end
	local humanoid = character.Humanoid
	if not humanoid:FindFirstChild("HeadScale") or not humanoid:FindFirstChild("BodyDepthScale") then return end

	if not isScaled then
		-- Memperbesar karakter
		humanoid.HeadScale.Value = originalScale * scaledFactor
		humanoid.oidBodyDepthScale.Value = originalBodyScale * scaledFactor
		humanoid.BodyHeightScale.Value = originalHeightScale * scaledFactor
		humanoid.BodyWidthScale.Value = originalWidthScale * scaledFactor
		button.Text = "Kembali ke Normal"
		isScaled = true
	else
		-- Mengembalikan karakter ke ukuran normal
		humanoid.HeadScale.Value = originalScale
		humanoid.BodyDepthScale.Value = originalBodyScale
		humanoid.BodyHeightScale.Value = originalHeightScale
		humanoid.BodyWidthScale.Value = originalWidthScale
		button.Text = "Perbesar Karakter"
		isScaled = false
	end
end)

-- Jika karakter di-reset, skrip akan kembali ke ukuran normal
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	-- Mengatur ulang properti agar tetap berfungsi setelah karakter di-reset
	originalScale = character.Humanoid.HeadScale.Value
	originalBodyScale = character.Humanoid.BodyDepthScale.Value
	originalHeightScale = character.Humanoid.BodyHeightScale.Value
	originalWidthScale = character.Humanoid.BodyWidthScale.Value
	isScaled = false
	button.Text = "Perbesar Karakter"
end)
