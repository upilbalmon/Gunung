--[[ 
GUI Bookmark Lokasi + Import + Waypoint (Roblox Lua)
- Scrolling list berisi item bookmark
- Import dari teks berformat: ["Name"] = Vector3.new(x, y, z),
- Tombol Teleport & Hapus per item
- Fungsi Waypoint untuk teleport otomatis
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

-- Container utama (Card) - Ukuran dikurangi 2:3
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(280, 380) -- Diperbesar untuk fitur waypoint
mainFrame.Position = UDim2.new(0, 13, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.4
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 8)

local uiPadding = Instance.new("UIPadding", mainFrame)
uiPadding.PaddingTop = UDim.new(0, 8)
uiPadding.PaddingBottom = UDim.new(0, 8)
uiPadding.PaddingLeft = UDim.new(0, 8)
uiPadding.PaddingRight = UDim.new(0, 8)

-- Header dengan tombol close dan minimize
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, -16, 0, 19)
headerFrame.Position = UDim2.fromOffset(8, 5)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = mainFrame

-- Judul
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -50, 1, 0) -- Kurangi lebar untuk tombol
title.Position = UDim2.fromOffset(0, 0)
title.BackgroundTransparency = 1
title.Text = "📍 Bookmark Lokasi"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = headerFrame

-- Tombol Minimize
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.fromOffset(16, 16)
minimizeBtn.Position = UDim2.new(1, -36, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
minimizeBtn.TextColor3 = Color3.new(0, 0, 0)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 12
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = headerFrame
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

-- Tombol Close
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.fromOffset(16, 16)
closeBtn.Position = UDim2.new(1, -18, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- Tombol Minimized (tombol kecil di kiri bawah saat minimized)
local minimizedBtn = Instance.new("TextButton")
minimizedBtn.Name = "MinimizedBtn"
minimizedBtn.Size = UDim2.fromOffset(40, 40)
minimizedBtn.Position = UDim2.new(0, 20, 1, -60)
minimizedBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
minimizedBtn.TextColor3 = Color3.new(1, 1, 1)
minimizedBtn.Text = "📍"
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 16
minimizedBtn.AutoButtonColor = true
minimizedBtn.Visible = false
minimizedBtn.Parent = screenGui
Instance.new("UICorner", minimizedBtn).CornerRadius = UDim.new(0, 8)

-- Variabel untuk drag functionality
local isDraggingMinimized = false
local dragStartMinimized
local startPosMinimized

-- Fungsi untuk mengupdate posisi tombol minimized saat didrag
local function updateMinimizedBtnPosition(input)
    if not isDraggingMinimized then return end
    
    local delta = input.Position - dragStartMinimized
    local newX = math.clamp(startPosMinimized.X.Offset + delta.X, 0, screenGui.AbsoluteSize.X - minimizedBtn.AbsoluteSize.X)
    local newY = math.clamp(startPosMinimized.Y.Offset + delta.Y, 0, screenGui.AbsoluteSize.Y - minimizedBtn.AbsoluteSize.Y)
    
    minimizedBtn.Position = UDim2.new(0, newX, 0, newY)
end

-- Event handlers untuk drag functionality
minimizedBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMinimized = true
        dragStartMinimized = input.Position
        startPosMinimized = minimizedBtn.Position
        minimizedBtn.AutoButtonColor = false
        minimizedBtn.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    end
end)

minimizedBtn.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and isDraggingMinimized then
        updateMinimizedBtnPosition(input)
    end
end)

minimizedBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMinimized = false
        minimizedBtn.AutoButtonColor = true
        minimizedBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    end
end)

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -16, 0, 24)
tabContainer.Position = UDim2.fromOffset(8, 29)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

-- Fungsi helper untuk membuat tab
local function createTab(name, text, position, size)
    local tab = Instance.new("TextButton")
    tab.Name = "Tab" .. name
    tab.Size = size
    tab.Position = position
    tab.BackgroundColor3 = name == "Bookmark" and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(40, 40, 40)
    tab.Text = text
    tab.TextColor3 = name == "Bookmark" and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180)
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 10
    tab.AutoButtonColor = false
    tab.Parent = tabContainer
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 4)
    return tab
end

-- Tab Bookmark
local tabBookmark = createTab("Bookmark", "Bookmark", UDim2.fromOffset(0, 0), UDim2.new(0.333, -2, 1, 0))

-- Tab Import
local tabImport = createTab("Import", "Import", UDim2.new(0.333, 2, 0, 0), UDim2.new(0.333, -2, 1, 0))

-- Tab Location Saver
local tabSaver = createTab("Saver", "Saver", UDim2.new(0.666, 2, 0, 0), UDim2.new(0.333, 0, 1, 0))

-- Container untuk konten tab
local tabContent = Instance.new("Frame")
tabContent.Name = "TabContent"
tabContent.Size = UDim2.new(1, -16, 1, -65)
tabContent.Position = UDim2.fromOffset(8, 58)
tabContent.BackgroundTransparency = 1
tabContent.ClipsDescendants = true
tabContent.Parent = mainFrame

-- ===== TAB BOOKMARK =====
local bookmarkTab = Instance.new("ScrollingFrame")
bookmarkTab.Name = "BookmarkTab"
bookmarkTab.Size = UDim2.new(1, 0, 1, 0)
bookmarkTab.Position = UDim2.fromOffset(0, 0)
bookmarkTab.CanvasSize = UDim2.new(0, 0, 0, 0)
bookmarkTab.ScrollBarThickness = 4
bookmarkTab.BackgroundTransparency = 1
bookmarkTab.BorderSizePixel = 0
bookmarkTab.Visible = true
bookmarkTab.Parent = tabContent

local uiList = Instance.new("UIListLayout", bookmarkTab)
uiList.Padding = UDim.new(0, 5)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local listPadding = Instance.new("UIPadding", bookmarkTab)
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 5)
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 5)

-- Auto-resize CanvasSize sesuai konten
local function updateCanvasSize()
    task.defer(function()
        local contentSize = uiList.AbsoluteContentSize
        bookmarkTab.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 10)
    end)
end
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

-- ===== TAB IMPORT =====
local importTab = Instance.new("Frame")
importTab.Name = "ImportTab"
importTab.Size = UDim2.new(1, 0, 1, 0)
importTab.Position = UDim2.fromOffset(0, 0)
importTab.BackgroundTransparency = 1
importTab.Visible = false
importTab.Parent = tabContent

-- TextBox untuk paste data import
local importBox = Instance.new("TextBox")
importBox.Name = "ImportBox"
importBox.Size = UDim2.new(1, 0, 0, 100)
importBox.Position = UDim2.fromOffset(0, 0)
importBox.TextWrapped = true
importBox.ClearTextOnFocus = false
importBox.MultiLine = true
importBox.PlaceholderText = 'Tempel data di sini...\nContoh:\n["CP3"] = Vector3.new(-1636.47, 992.97, 284.60),'
importBox.TextXAlignment = Enum.TextXAlignment.Left
importBox.TextYAlignment = Enum.TextYAlignment.Top
importBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
importBox.TextColor3 = Color3.fromRGB(230, 230, 230)
importBox.Font = Enum.Font.Code
importBox.TextSize = 9
importBox.Parent = importTab
Instance.new("UICorner", importBox).CornerRadius = UDim.new(0, 5)

-- Tombol Import
local importBtn = Instance.new("TextButton")
importBtn.Name = "ImportBtn"
importBtn.Size = UDim2.fromOffset(67, 21)
importBtn.Position = UDim2.fromOffset(0, 108)
importBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
importBtn.Text = "Import"
importBtn.TextColor3 = Color3.new(1,1,1)
importBtn.Font = Enum.Font.GothamBold
importBtn.TextSize = 9
importBtn.AutoButtonColor = true
importBtn.Parent = importTab
Instance.new("UICorner", importBtn).CornerRadius = UDim.new(0, 5)

-- Label status (error/success)
local statusLbl = Instance.new("TextLabel")
statusLbl.Name = "StatusLabel"
statusLbl.Size = UDim2.new(1, -75, 0, 21)
statusLbl.Position = UDim2.fromOffset(72, 108)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 9
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = importTab

-- ===== TAB LOCATION SAVER =====
local saverTab = Instance.new("Frame")
saverTab.Name = "SaverTab"
saverTab.Size = UDim2.new(1, 0, 1, 0)
saverTab.Position = UDim2.fromOffset(0, 0)
saverTab.BackgroundTransparency = 1
saverTab.Visible = false
saverTab.Parent = tabContent

-- Fungsi helper untuk kasih rounded corner
local function applyCorner(guiObject, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = guiObject
end

-- TextBox
local saverTextBox = Instance.new("TextBox")
saverTextBox.Size = UDim2.new(1, -10, 0, 30)
saverTextBox.Position = UDim2.new(0, 5, 0, 5)
saverTextBox.PlaceholderText = "Masukkan nama lokasi"
saverTextBox.Text = ""
saverTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
saverTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
saverTextBox.BackgroundTransparency = 0.7
saverTextBox.Parent = saverTab
applyCorner(saverTextBox, 6)

-- ==== Tombol biru ====
local function styleBlueButton(btn)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- Save Button (kiri)
local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0.5, -7, 0, 30)
saveButton.Position = UDim2.new(0, 5, 0, 45)
saveButton.Text = "Simpan Lokasi"
saveButton.Parent = saverTab
styleBlueButton(saveButton)
applyCorner(saveButton, 6)

-- Print Button (kanan)
local printButton = Instance.new("TextButton")
printButton.Size = UDim2.new(0.5, -7, 0, 30)
printButton.Position = UDim2.new(0.5, 2, 0, 45)
printButton.Text = "Print & Copy"
printButton.Parent = saverTab
styleBlueButton(printButton)
applyCorner(printButton, 6)

-- ===== FUNGSI WAYPOINT =====
local waypointFrame = Instance.new("Frame")
waypointFrame.Name = "WaypointFrame"
waypointFrame.Size = UDim2.new(1, -10, 0, 120)
waypointFrame.Position = UDim2.new(0, 5, 0, 85)
waypointFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
waypointFrame.BackgroundTransparency = 0.5
waypointFrame.Parent = saverTab
applyCorner(waypointFrame, 6)

-- Judul Waypoint
local waypointTitle = Instance.new("TextLabel")
waypointTitle.Name = "WaypointTitle"
waypointTitle.Size = UDim2.new(1, 0, 0, 20)
waypointTitle.Position = UDim2.fromOffset(0, 5)
waypointTitle.BackgroundTransparency = 1
waypointTitle.Text = "🔄 Waypoint System"
waypointTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
waypointTitle.Font = Enum.Font.GothamBold
waypointTitle.TextSize = 12
waypointTitle.Parent = waypointFrame

-- Delay Input
local delayLabel = Instance.new("TextLabel")
delayLabel.Name = "DelayLabel"
delayLabel.Size = UDim2.new(0.4, -5, 0, 20)
delayLabel.Position = UDim2.new(0, 5, 0, 30)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay (detik):"
delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextSize = 10
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = waypointFrame

local delayBox = Instance.new("TextBox")
delayBox.Name = "DelayBox"
delayBox.Size = UDim2.new(0.6, -5, 0, 20)
delayBox.Position = UDim2.new(0.4, 0, 0, 30)
delayBox.Text = "3"
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
delayBox.Parent = waypointFrame
applyCorner(delayBox, 4)

-- Loop Input
local loopLabel = Instance.new("TextLabel")
loopLabel.Name = "LoopLabel"
loopLabel.Size = UDim2.new(0.4, -5, 0, 20)
loopLabel.Position = UDim2.new(0, 5, 0, 55)
loopLabel.BackgroundTransparency = 1
loopLabel.Text = "Jumlah Loop:"
loopLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
loopLabel.Font = Enum.Font.Gotham
loopLabel.TextSize = 10
loopLabel.TextXAlignment = Enum.TextXAlignment.Left
loopLabel.Parent = waypointFrame

local loopBox = Instance.new("TextBox")
loopBox.Name = "LoopBox"
loopBox.Size = UDim2.new(0.6, -5, 0, 20)
loopBox.Position = UDim2.new(0.4, 0, 0, 55)
loopBox.Text = "1"
loopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
loopBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
loopBox.Parent = waypointFrame
applyCorner(loopBox, 4)

-- Start/Stop Button
local waypointButton = Instance.new("TextButton")
waypointButton.Name = "WaypointButton"
waypointButton.Size = UDim2.new(1, -10, 0, 25)
waypointButton.Position = UDim2.new(0, 5, 0, 85)
waypointButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
waypointButton.Text = "▶ Start Waypoint"
waypointButton.TextColor3 = Color3.new(1, 1, 1)
waypointButton.Font = Enum.Font.GothamBold
waypointButton.TextSize = 12
waypointButton.AutoButtonColor = true
waypointButton.Parent = waypointFrame
applyCorner(waypointButton, 5)

-- Status Label
local saverStatusLabel = Instance.new("TextLabel")
saverStatusLabel.Name = "StatusLabel"
saverStatusLabel.Size = UDim2.new(1, -10, 0, 25)
saverStatusLabel.Position = UDim2.new(0, 5, 0, 210)
saverStatusLabel.BackgroundTransparency = 1
saverStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 50)
saverStatusLabel.Text = "🔔 Siap digunakan"
saverStatusLabel.TextSize = 8
saverStatusLabel.Size = UDim2.new(1, -10, 0, 20)
saverStatusLabel.Parent = saverTab

-- Memory sementara untuk location saver
local savedLocations = {}

-- Variabel untuk waypoint system
local isWaypointRunning = false
local currentWaypointIndex = 1
local currentLoop = 1

-- Fungsi untuk menjalankan waypoint
local function runWaypoint()
    if not isWaypointRunning or not next(bookmarks) then return end
    
    -- Dapatkan daftar nama bookmark yang terurut
    local names = {}
    for name in pairs(bookmarks) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    
    -- Jika sudah mencapai akhir daftar, reset atau hentikan
    if currentWaypointIndex > #names then
        currentWaypointIndex = 1
        currentLoop = currentLoop + 1
        
        -- Cek jika sudah mencapai jumlah loop yang diinginkan
        local maxLoops = tonumber(loopBox.Text) or 1
        if currentLoop > maxLoops then
            isWaypointRunning = false
            waypointButton.Text = "▶ Start Waypoint"
            waypointButton.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
            saverStatusLabel.Text = "✅ Waypoint selesai"
            return
        end
    end
    
    -- Teleport ke waypoint saat ini
    local currentName = names[currentWaypointIndex]
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hrp and bookmarks[currentName] then
        hrp.CFrame = CFrame.new(bookmarks[currentName])
        saverStatusLabel.Text = string.format("🔁 Waypoint %d/%d (Loop %d/%d): %s", 
            currentWaypointIndex, #names, currentLoop, tonumber(loopBox.Text) or 1, currentName)
    end
    
    -- Increment index untuk waypoint berikutnya
    currentWaypointIndex = currentWaypointIndex + 1
    
    -- Jadwalkan waypoint berikutnya
    local delay = tonumber(delayBox.Text) or 3
    delay = math.max(1, delay) -- Minimal 1 detik
    task.delay(delay, runWaypoint)
end

-- Event handler untuk tombol waypoint
waypointButton.MouseButton1Click:Connect(function()
    if not next(bookmarks) then
        saverStatusLabel.Text = "⚠️ Tidak ada bookmark untuk waypoint"
        return
    end
    
    isWaypointRunning = not isWaypointRunning
    
    if isWaypointRunning then
        -- Start waypoint
        waypointButton.Text = "⏹ Stop Waypoint"
        waypointButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        currentWaypointIndex = 1
        currentLoop = 1
        saverStatusLabel.Text = "🔄 Memulai waypoint..."
        runWaypoint()
    else
        -- Stop waypoint
        waypointButton.Text = "▶ Start Waypoint"
        waypointButton.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
        saverStatusLabel.Text = "⏹ Waypoint dihentikan"
    end
end)

-- ==== Fungsi untuk Location Saver ====
-- Simpan lokasi
saveButton.MouseButton1Click:Connect(function()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then 
        saverStatusLabel.Text = "❌ Character belum siap!"
        return 
    end

    local pos = player.Character.HumanoidRootPart.Position
    local name = saverTextBox.Text

    if name == "" then
        saverStatusLabel.Text = "⚠️ Nama lokasi tidak boleh kosong!"
        return
    end

    savedLocations[name] = pos
    saverStatusLabel.Text = "✅ Lokasi '"..name.."' tersimpan."
    saverTextBox.Text = "" -- reset setelah simpan
end)

-- Print + Copy ke Clipboard (format tabel Lua)
printButton.MouseButton1Click:Connect(function()
    if next(savedLocations) == nil then
        saverStatusLabel.Text = "⚠️ Belum ada lokasi tersimpan."
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
        saverStatusLabel.Text = "✅ Lokasi dicopy ke clipboard."
    else
        saverStatusLabel.Text = "❌ setclipboard tidak tersedia."
    end
end)

-- ==== Util ====
local function setStatus(text, isError)
    statusLbl.Text = text or ""
    if isError then
        statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
    else
        statusLbl.TextColor3 = Color3.fromRGB(180, 220, 160)
    end
end

-- Fungsi untuk minimize/maximize GUI
local function toggleMinimize()
    if mainFrame.Visible then
        -- Minimize
        mainFrame.Visible = false
        minimizedBtn.Visible = true
    else
        -- Maximize
        mainFrame.Visible = true
        minimizedBtn.Visible = false
    end
end

-- Event handlers untuk tombol minimize dan close
minimizeBtn.MouseButton1Click:Connect(toggleMinimize)
minimizedBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Fungsi untuk mengganti tab
local function switchTab(selectedTab)
    -- Reset semua tab
    tabBookmark.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabBookmark.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabImport.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabImport.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabSaver.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabSaver.TextColor3 = Color3.fromRGB(180, 180, 180)
    
    -- Sembunyikan semua konten tab
    bookmarkTab.Visible = false
    importTab.Visible = false
    saverTab.Visible = false
    
    -- Aktifkan tab yang dipilih
    if selectedTab == "bookmark" then
        tabBookmark.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabBookmark.TextColor3 = Color3.new(1, 1, 1)
        bookmarkTab.Visible = true
    elseif selectedTab == "import" then
        tabImport.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabImport.TextColor3 = Color3.new(1, 1, 1)
        importTab.Visible = true
    elseif selectedTab == "saver" then
        tabSaver.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabSaver.TextColor3 = Color3.new(1, 1, 1)
        saverTab.Visible = true
    end
end

-- Event handlers untuk tab
tabBookmark.MouseButton1Click:Connect(function()
    switchTab("bookmark")
end)

tabImport.MouseButton1Click:Connect(function()
    switchTab("import")
end)

tabSaver.MouseButton1Click:Connect(function()
    switchTab("saver")
end)

-- Buat satu item baris di list (HANYA NAMA, TOMBOL X KECIL)
local function makeListItem(name, v3)
    local item = Instance.new("Frame")
    item.Name = "Item_" .. name
    item.Size = UDim2.new(1, -10, 0, 32)
    item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    item.BorderSizePixel = 0
    item.Parent = bookmarkTab
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 5)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "NameLabel"
    nameLbl.Size = UDim2.new(1, -60, 1, -0)
    nameLbl.Position = UDim2.fromOffset(8, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Text = name
    nameLbl.TextColor3 = Color3.fromRGB(235, 235, 235)
    nameLbl.Font = Enum.Font.Gotham
    nameLbl.TextSize = 11
    nameLbl.Parent = item

    local tpBtn = Instance.new("TextButton")
    tpBtn.Name = "TpBtn"
    tpBtn.Size = UDim2.fromOffset(60, 24)
    tpBtn.Position = UDim2.new(1, -75, 0.5, -12)
    tpBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
    tpBtn.Text = "Teleport"
    tpBtn.TextColor3 = Color3.new(1,1,1)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.AutoButtonColor = true
    tpBtn.Parent = item
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)

    -- Tombol Hapus (X kecil persegi)
    local delBtn = Instance.new("TextButton")
    delBtn.Name = "DelBtn"
    delBtn.Size = UDim2.fromOffset(24, 24)
    delBtn.Position = UDim2.new(1, -30, 0.5, -12)
    delBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    delBtn.Text = "X"
    delBtn.TextColor3 = Color3.new(1,1,1)
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 12
    delBtn.AutoButtonColor = true
    delBtn.Parent = item
    Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 5)

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
    for _, child in ipairs(bookmarkTab:GetChildren()) do
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
    switchTab("bookmark")
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
