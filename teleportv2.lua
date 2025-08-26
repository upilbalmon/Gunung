-- Tele GUI (persist across respawn) + Copy/Print All Bookmarks to Clipboard
-- Lokasi ideal: StarterPlayerScripts (LocalScript) atau dijalankan sebagai LocalScript

-- ==== Services / Bootstrap ====
local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local pg      = player:WaitForChild("PlayerGui")

local GUI_NAME = "TeleGUI"

-- Reuse agar tidak dobel saat respawn
local ScreenGui = pg:FindFirstChild(GUI_NAME)
if not ScreenGui then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GUI_NAME
    ScreenGui.Parent = pg
end

-- Persist + top layer
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder   = 9999 -- top-layer

-- Hindari inisialisasi ulang
if ScreenGui:GetAttribute("Initialized") then
    return
end
ScreenGui:SetAttribute("Initialized", true)

-- ==== State ====
local isMinimized           = false
local originalPositionVec3  = nil
local originalFrameSize
local bookmarks             = {}  -- [name] = Vector3

-- ==== Helpers ====
local function styleElement(el)
    el.BackgroundTransparency = 0.5
    el.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    if el:IsA("TextBox") or el:IsA("TextButton") then
        el.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    el.BorderSizePixel = 0
end

local function styleBlueButton(btn)
    styleElement(btn)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- tombol biru
end

local function addCorner(inst, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, rad or 10)
    c.Parent = inst
    return c
end

local function parseCoordinates(input)
    local parts = string.split((input or ""), ",")
    if #parts == 3 then
        local x = tonumber(parts[1])
        local y = tonumber(parts[2])
        local z = tonumber(parts[3])
        if x and y and z then
            return Vector3.new(x, y, z)
        end
    end
    return nil
end

local function getCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    return character
end

local function fmtVec3(v)
    return string.format("%d,%d,%d", math.floor(v.X), math.floor(v.Y), math.floor(v.Z))
end

local function safeSetClipboard(text)
    local ok = false
    if typeof(setclipboard) == "function" then
        local s = pcall(function() setclipboard(text) end)
        ok = s or ok
    end
    if (not ok) and typeof(toclipboard) == "function" then
        local s = pcall(function() toclipboard(text) end)
        ok = s or ok
    end
    if (not ok) and typeof(writefile) == "function" then
        local s = pcall(function() writefile("tele_bookmarks.txt", text) end)
        ok = s or ok
    end
    return ok
end

-- ==== UI Elements ====
local Frame           = Instance.new("Frame")
local TitleBar        = Instance.new("Frame")
local TitleText       = Instance.new("TextLabel")
local CloseButton     = Instance.new("TextButton")
local MinimizeButton  = Instance.new("TextButton")

local XBox            = Instance.new("TextBox")
local TeleportButton  = Instance.new("TextButton")
local ReturnButton    = Instance.new("TextButton")
local LokasiButton    = Instance.new("TextButton")

local BookmarkBox     = Instance.new("TextBox")
local SaveButton      = Instance.new("TextButton")

local BookmarkList    = Instance.new("Frame")
local Layout          = Instance.new("UIListLayout")

local CopyAllButton   = Instance.new("TextButton") -- NEW
local ClearAllButton  = Instance.new("TextButton") -- opsional: bersihkan daftar (hanya UI)

-- ==== Main Frame ====
Frame.Name = "MainFrame"
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 260, 0, 380)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundTransparency = 0.4  -- sesuai preferensi
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true
addCorner(Frame, 12)

-- ==== Title Bar ====
TitleBar.Name = "TitleBar"
TitleBar.Parent = Frame
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundTransparency = 0.2 -- title transparansi 0.2
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
addCorner(TitleBar, 12)

TitleText.Parent = TitleBar
TitleText.Size = UDim2.new(1, -64, 1, 0)
TitleText.Position = UDim2.new(0, 8, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 14
TitleText.Text = "Teleport Tool"
TitleText.TextColor3 = Color3.fromRGB(255,255,255)

-- Close (merah), Minimize (hijau 0.5)
CloseButton.Parent = TitleBar
CloseButton.Text = "X"
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0, 3)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
CloseButton.BackgroundTransparency = 0
CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
CloseButton.BorderSizePixel = 0
CloseButton.AutoButtonColor = true
addCorner(CloseButton, 8)

MinimizeButton.Parent = TitleBar
MinimizeButton.Text = "–"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -56, 0, 3)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
MinimizeButton.BackgroundTransparency = 0.5
MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.AutoButtonColor = true
addCorner(MinimizeButton, 8)

-- ==== Inputs Koordinat ====
XBox.Parent = Frame
XBox.PlaceholderText = "X,Y,Z"
XBox.Position = UDim2.new(0, 10, 0, 40)
XBox.Size = UDim2.new(0, 240, 0, 28)
styleElement(XBox)
XBox.BackgroundTransparency = 0.2 -- textbox transparansi 0.2
addCorner(XBox, 8)

-- Tombol biru baris 1
TeleportButton.Parent = Frame
TeleportButton.Text = "Teleport"
TeleportButton.Position = UDim2.new(0, 10, 0, 74)
TeleportButton.Size = UDim2.new(0, 74, 0, 28)
styleBlueButton(TeleportButton); addCorner(TeleportButton, 8)

ReturnButton.Parent = Frame
ReturnButton.Text = "Kembali"
ReturnButton.Position = UDim2.new(0, 92, 0, 74)
ReturnButton.Size = UDim2.new(0, 74, 0, 28)
styleBlueButton(ReturnButton); addCorner(ReturnButton, 8)

LokasiButton.Parent = Frame
LokasiButton.Text = "GetLoc"
LokasiButton.Position = UDim2.new(0, 174, 0, 74)
LokasiButton.Size = UDim2.new(0, 76, 0, 28)
styleBlueButton(LokasiButton); addCorner(LokasiButton, 8)

-- Input nama bookmark + simpan
BookmarkBox.Parent = Frame
BookmarkBox.PlaceholderText = "Nama lokasi"
BookmarkBox.Position = UDim2.new(0, 10, 0, 112)
BookmarkBox.Size = UDim2.new(0, 160, 0, 28)
styleElement(BookmarkBox)
BookmarkBox.BackgroundTransparency = 0.2
addCorner(BookmarkBox, 8)

SaveButton.Parent = Frame
SaveButton.Text = "Simpan"
SaveButton.Position = UDim2.new(0, 180, 0, 112)
SaveButton.Size = UDim2.new(0, 70, 0, 28)
styleBlueButton(SaveButton); addCorner(SaveButton, 8)

-- Daftar bookmark (dipendekkan agar muat tombol copy/clear di bawah)
BookmarkList.Parent = Frame
BookmarkList.Position = UDim2.new(0, 10, 0, 150)
BookmarkList.Size = UDim2.new(0, 240, 0, 170) -- tinggi 170
BookmarkList.BackgroundTransparency = 0.5
BookmarkList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
addCorner(BookmarkList, 10)

Layout.Parent = BookmarkList
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 4)

-- Tombol baru: Copy All + Clear
CopyAllButton.Parent = Frame
CopyAllButton.Text = "Copy/Print All"
CopyAllButton.Position = UDim2.new(0, 10, 0, 326)
CopyAllButton.Size = UDim2.new(0, 118, 0, 28)
styleBlueButton(CopyAllButton); addCorner(CopyAllButton, 8)

ClearAllButton.Parent = Frame
ClearAllButton.Text = "Clear List (UI)"
ClearAllButton.Position = UDim2.new(0, 132, 0, 326)
ClearAllButton.Size = UDim2.new(0, 118, 0, 28)
styleBlueButton(ClearAllButton); addCorner(ClearAllButton, 8)

-- ==== Minimize / Close ====
originalFrameSize = Frame.Size

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        for _, child in ipairs(Frame:GetChildren()) do
            if child ~= TitleBar and not child:IsA("UICorner") then
                child.Visible = false
            end
        end
        Frame.Size = UDim2.new(originalFrameSize.X.Scale, originalFrameSize.X.Offset, 0, 30)
    else
        for _, child in ipairs(Frame:GetChildren()) do
            child.Visible = true
        end
        Frame.Size = originalFrameSize
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ==== Actions ====
TeleportButton.MouseButton1Click:Connect(function()
    local coords = parseCoordinates(XBox.Text)
    if not coords then return end
    local character = getCharacter()
    if character and character.PrimaryPart then
        originalPositionVec3 = character.PrimaryPart.Position
        character:SetPrimaryPartCFrame(CFrame.new(coords))
    end
end)

ReturnButton.MouseButton1Click:Connect(function()
    if not originalPositionVec3 then return end
    local character = getCharacter()
    if character and character.PrimaryPart then
        character:SetPrimaryPartCFrame(CFrame.new(originalPositionVec3))
    end
end)

LokasiButton.MouseButton1Click:Connect(function()
    local character = getCharacter()
    if character and character.PrimaryPart then
        local pos = character.PrimaryPart.Position
        local formatted = fmtVec3(pos)
        XBox.Text = formatted
        if typeof(setclipboard) == "function" then
            pcall(function() setclipboard(formatted) end)
        end
    end
end)

SaveButton.MouseButton1Click:Connect(function()
    local name = (BookmarkBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local coords = parseCoordinates(XBox.Text)
    if name ~= "" and coords then
        bookmarks[name] = coords

        local b = Instance.new("TextButton")
        b.Text = name
        b.Size = UDim2.new(1, 0, 0, 26)
        b.BackgroundTransparency = 0.4
        b.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.BorderSizePixel = 0
        b.Parent = BookmarkList
        addCorner(b, 8)

        b.MouseButton1Click:Connect(function()
            local character = getCharacter()
            if character and character.PrimaryPart then
                character:SetPrimaryPartCFrame(CFrame.new(coords))
            end
            local formatted = fmtVec3(coords)
            XBox.Text = formatted
            if typeof(setclipboard) == "function" then
                pcall(function() setclipboard(formatted) end)
            end
        end)

        BookmarkBox.Text = ""
        -- jangan kosongkan XBox agar mudah simpan berulang, tapi kalau mau:
        -- XBox.Text = ""
    end
end)

-- ==== NEW: Copy/Print All Bookmarks to Clipboard ====
CopyAllButton.MouseButton1Click:Connect(function()
    local lines = {}
    -- urutkan biar rapi
    local names = {}
    for k,_ in pairs(bookmarks) do table.insert(names, k) end
    table.sort(names, function(a,b) return a:lower() < b:lower() end)

    for _, name in ipairs(names) do
        local v = bookmarks[name]
        table.insert(lines, string.format("%s=%s", name, fmtVec3(v)))
    end

    if #lines == 0 then
        warn("[tele.lua] Belum ada bookmark yang disimpan.")
        return
    end

    local blob = table.concat(lines, "\n")
    local ok = safeSetClipboard(blob)
    if ok then
        print("[tele.lua] Semua bookmark tersalin ke clipboard:")
    else
        print("[tele.lua] Clipboard tidak tersedia. Disimpan/ditampilkan sebagai gantinya:")
    end
    print(blob)
end)

-- Opsional: bersihkan daftar tombol (hanya UI, tidak mengosongkan table bookmarks)
ClearAllButton.MouseButton1Click:Connect(function()
    for _, child in ipairs(BookmarkList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end)
