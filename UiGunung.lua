--// LocalScript: UI Toggle Button (load/destroy external GUIs)
-- posisi kiri-bawah, 40px di atas tepi bawah, ukuran 40x40, warna hitam transparansi 0.5

--== Services & Vars ==
local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local pg      = player:WaitForChild("PlayerGui")

local URLS = {
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/pengendalitanah.lua",
}

--== Make a dedicated ScreenGui (top layer, persist) ==
local GUI_NAME = "UIToggleLauncher"
local sg = pg:FindFirstChild(GUI_NAME)
if not sg then
    sg = Instance.new("ScreenGui")
    sg.Name = GUI_NAME
    sg.DisplayOrder = 10000
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    sg.ResetOnSpawn = false
    sg.Parent = pg
end
if sg:GetAttribute("Initialized") then return end
sg:SetAttribute("Initialized", true)

--== Create the 40x40 button ==
local btn = Instance.new("TextButton")
btn.Name = "UIToggle"
btn.Parent = sg
btn.Size = UDim2.fromOffset(40, 40)
btn.Position = UDim2.new(0, 0, 1, -80) -- kiri-bawah, naik 40px
btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
btn.BackgroundTransparency = 0.5
btn.Text = "UI"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.BorderSizePixel = 0
do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
end

--== State & helpers ==
local isOn = false
local managedGuis : { Instance } = {}

local function destroyManaged()
    for _, g in ipairs(managedGuis) do
        if typeof(g) == "Instance" and g.Destroy then
            pcall(function() g:Destroy() end)
        end
    end
    table.clear(managedGuis)
end

local function toSet(children)
    local set = {}
    for _, c in ipairs(children) do set[c] = true end
    return set
end

local function captureNewScreenGuis(beforeSet)
    local newOnes = {}
    for _, ch in ipairs(pg:GetChildren()) do
        if ch:IsA("ScreenGui") and not beforeSet[ch] and ch ~= sg then
            table.insert(newOnes, ch)
        end
    end
    return newOnes
end

local function loadAll()
    -- snapshot sebelum load
    local before = toSet(pg:GetChildren())

    for _, url in ipairs(URLS) do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and typeof(res) == "Instance" then
            -- kalau script return instance (idealnya ScreenGui)
            if res:IsA("ScreenGui") then
                table.insert(managedGuis, res)
            elseif res:IsA("GuiObject") then
                -- bungkus ke ScreenGui agar tetap manageable
                local wrap = Instance.new("ScreenGui")
                wrap.Name = "Wrapped_" .. (res.Name or "Ext")
                wrap.ResetOnSpawn = false
                wrap.ZIndexBehavior = Enum.ZIndexBehavior.Global
                wrap.DisplayOrder = 9999
                res.Parent = wrap
                wrap.Parent = pg
                table.insert(managedGuis, wrap)
            end
        end
    end

    -- tangkap ScreenGui yang ditambahkan oleh script bila tidak return instance
    local newOnes = captureNewScreenGuis(before)
    for _, gui in ipairs(newOnes) do
        table.insert(managedGuis, gui)
    end
end

--== Toggle behavior ==
btn.MouseButton1Click:Connect(function()
    isOn = not isOn
    if isOn then
        btn.Text = "ON"
        loadAll()
    else
        btn.Text = "OFF"
        destroyManaged()
    end
end)
