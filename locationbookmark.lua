--[[ 
GUI Bookmark Lokasi + Import (Roblox Lua)
- Scrolling list berisi item bookmark
- Import dari teks berformat: ["Name"] = Vector3.new(x, y, z),
- Tombol Teleport & Hapus per item
- Dibuat sebagai LocalScript
]]

-- ==== Helper: Dapatkan Player/PlayerGui ====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==== Data ====
local bookmarks = {}  -- { [name] = Vector3, ... }

-- ==== UI Creation ====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BookmarkLokasiGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Container utama (Card)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(420, 520)
mainFrame.Position = UDim2.new(0, 20, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 12)

local uiPadding = Instance.new("UIPadding", mainFrame)
uiPadding.PaddingTop = UDim.new(0, 12)
uiPadding.PaddingBottom = UDim.new(0, 12)
uiPadding.PaddingLeft = UDim.new(0, 12)
uiPadding.PaddingRight = UDim.new(0, 12)

-- Header
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 28)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Text = "📍 Bookmark Lokasi"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- TextBox untuk paste data import
local importBox = Instance.new("TextBox")
importBox.Name = "ImportBox"
importBox.Size = UDim2.new(1, -24, 0, 110)
importBox.Position = UDim2.fromOffset(12, 44)
importBox.TextWrapped = true
importBox.ClearTextOnFocus = false
importBox.MultiLine = true
importBox.PlaceholderText = 'Tempel data di sini...\nContoh:\n["CP3"] = Vector3.new(-1636.47, 992.97, 284.60),'
importBox.TextXAlignment = Enum.TextXAlignment.Left
importBox.TextYAlignment = Enum.TextYAlignment.Top
importBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
importBox.TextColor3 = Color3.fromRGB(230, 230, 230)
importBox.Font = Enum.Font.Code
importBox.TextSize = 14
importBox.Parent = mainFrame
Instance.new("UICorner", importBox).CornerRadius = UDim.new(0, 8)

-- Tombol Import
local importBtn = Instance.new("TextButton")
importBtn.Name = "ImportBtn"
importBtn.Size = UDim2.fromOffset(100, 32)
importBtn.Position = UDim2.fromOffset(12, 160)
importBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
importBtn.Text = "Import"
importBtn.TextColor3 = Color3.new(1,1,1)
importBtn.Font = Enum.Font.GothamBold
importBtn.TextSize = 14
importBtn.AutoButtonColor = true
importBtn.Parent = mainFrame
Instance.new("UICorner", importBtn).CornerRadius = UDim.new(0, 8)

-- Label status (error/success)
local statusLbl = Instance.new("TextLabel")
statusLbl.Name = "StatusLabel"
statusLbl.Size = UDim2.new(1, -136, 0, 32)
statusLbl.Position = UDim2.fromOffset(120, 160)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 14
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = mainFrame

-- Garis pemisah
local sep = Instance.new("Frame")
sep.Name = "Separator"
sep.Size = UDim2.new(1, -24, 0, 1)
sep.Position = UDim2.fromOffset(12, 204)
sep.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sep.BorderSizePixel = 0
sep.Parent = mainFrame

-- ScrollingFrame untuk list bookmark
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "ListFrame"
listFrame.Size = UDim2.new(1, -24, 1, -224)
listFrame.Position = UDim2.fromOffset(12, 216)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.ScrollBarThickness = 6
listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
listFrame.BorderSizePixel = 0
listFrame.Parent = mainFrame
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

local uiList = Instance.new("UIListLayout", listFrame)
uiList.Padding = UDim.new(0, 8)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local listPadding = Instance.new("UIPadding", listFrame)
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.PaddingLeft = UDim.new(0, 8)
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.PaddingBottom = UDim.new(0, 8)

-- Auto-resize CanvasSize sesuai konten
local function updateCanvasSize()
	task.defer(function()
		local contentSize = uiList.AbsoluteContentSize
		listFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 16)
	end)
end
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

-- ==== Util ====
local function setStatus(text, isError)
	statusLbl.Text = text or ""
	if isError then
		statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		statusLbl.TextColor3 = Color3.fromRGB(180, 220, 160)
	end
end

-- Buat satu item baris di list
local function makeListItem(name, v3)
	local item = Instance.new("Frame")
	item.Name = "Item_" .. name
	item.Size = UDim2.new(1, -0, 0, 48)
	item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	item.BorderSizePixel = 0
	item.Parent = listFrame
	Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.Size = UDim2.new(1, -220, 1, -0)
	nameLbl.Position = UDim2.fromOffset(12, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Text = string.format("%s  —  (%.2f, %.2f, %.2f)", name, v3.X, v3.Y, v3.Z)
	nameLbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	nameLbl.Font = Enum.Font.Gotham
	nameLbl.TextSize = 14
	nameLbl.Parent = item

	local tpBtn = Instance.new("TextButton")
	tpBtn.Name = "TpBtn"
	tpBtn.Size = UDim2.fromOffset(88, 32)
	tpBtn.Position = UDim2.new(1, -184, 0.5, -16)
	tpBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
	tpBtn.Text = "Teleport"
	tpBtn.TextColor3 = Color3.new(1,1,1)
	tpBtn.Font = Enum.Font.GothamBold
	tpBtn.TextSize = 14
	tpBtn.AutoButtonColor = true
	tpBtn.Parent = item
	Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 8)

	local delBtn = Instance.new("TextButton")
	delBtn.Name = "DelBtn"
	delBtn.Size = UDim2.fromOffset(88, 32)
	delBtn.Position = UDim2.new(1, -92, 0.5, -16)
	delBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	delBtn.Text = "Hapus"
	delBtn.TextColor3 = Color3.new(1,1,1)
	delBtn.Font = Enum.Font.GothamBold
	delBtn.TextSize = 14
	delBtn.AutoButtonColor = true
	delBtn.Parent = item
	Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 8)

	-- Actions
	tpBtn.MouseButton1Click:Connect(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(v3)
			setStatus("Teleport ke " .. name .. " ✓", false)
		else
			setStatus("Gagal teleport: HRP tidak ditemukan.", true)
		end
	end)

	delBtn.MouseButton1Click:Connect(function()
		bookmarks[name] = nil
		item:Destroy()
		updateCanvasSize()
		setStatus("Hapus bookmark: " .. name, false)
	end)

	return item
end

-- Render ulang list (dipakai saat import)
local function renderList()
	-- Hapus semua item lama
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Item_") then
			child:Destroy()
		end
	end
	-- Urutkan nama
	local names = {}
	for name in pairs(bookmarks) do
		table.insert(names, name)
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)

	for _, name in ipairs(names) do
		makeListItem(name, bookmarks[name])
	end

	updateCanvasSize()
end

-- ==== Parser Import ====
-- Menerima teks seperti:
-- ["CP3"] = Vector3.new(-1636.47, 992.97, 284.60),
-- Kuat terhadap spasi dan baris baru.
local function parseAndImport(text)
	if not text or text == "" then
		return false, "Input kosong."
	end

	local count = 0
	-- Pola: ["Nama"] = Vector3.new(X, Y, Z)
	-- Tangkap grup: nama, x, y, z
	for name, x, y, z in text:gmatch("%[\"(.-)\"%]%s*=%s*Vector3%.new%s*%(%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*%)") do
		local vx = tonumber(x)
		local vy = tonumber(y)
		local vz = tonumber(z)
		if name ~= "" and vx and vy and vz then
			bookmarks[name] = Vector3.new(vx, vy, vz)
			count += 1
		end
	end

	if count == 0 then
		return false, "Tidak ada baris valid yang ditemukan. Pastikan formatnya benar."
	end

	renderList()
	return true, ("Berhasil import %d bookmark."):format(count)
end

-- ==== Hook tombol Import ====
importBtn.MouseButton1Click:Connect(function()
	local ok, msg = parseAndImport(importBox.Text)
	setStatus(msg, not ok)
end)

-- ==== (Opsional) Isi contoh awal agar mudah tes ====
local contoh = [[
["CP1"] = Vector3.new(-228,440,2143)
["CP2"] = Vector3.new(-427,848,3204)
["CP3"] = Vector3.new(41,1268,4044)
["CP4"] = Vector3.new(-1142,1552,4899)
["RINTANGAN TERAKHIR"] = Vector3.new(-670.04, 1803.13, 5194.87)
["CPTOP"] = Vector3.new(-718.58, 1933.16, 5358.43)
]]
importBox.Text = contoh
-- Kamu bisa otomatis import saat start dengan baris berikut (hapus komentar jika mau):
-- parseAndImport(contoh)
