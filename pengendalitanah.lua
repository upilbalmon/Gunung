--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Hapus GUI lama bila ada untuk mencegah duplikasi
if playerGui:FindFirstChild("TeleportBidikGUI") then playerGui:FindFirstChild("TeleportBidikGUI"):Destroy() end
if playerGui:FindFirstChild("FloorCreatorGUI") then playerGui:FindFirstChild("FloorCreatorGUI"):Destroy() end
if playerGui:FindFirstChild("DroneMovementGUIs") then playerGui:FindFirstChild("DroneMovementGUIs"):Destroy() end
if playerGui:FindFirstChild("DroneToggleButtonGUI") then playerGui:FindFirstChild("DroneToggleButtonGUI"):Destroy() end
if playerGui:FindFirstChild("DroneHintGui") then playerGui:FindFirstChild("DroneHintGui"):Destroy() end

-- ====== KONFIG DRONE VIEW ======
local TOGGLE_KEY = Enum.KeyCode.V
local KEY_FORWARD = Enum.KeyCode.W
local KEY_BACK    = Enum.KeyCode.S
local KEY_LEFT    = Enum.KeyCode.A
local KEY_RIGHT   = Enum.KeyCode.D
local KEY_UP      = Enum.KeyCode.E
local KEY_DOWN    = Enum.KeyCode.Q
local KEY_FAST    = Enum.KeyCode.LeftShift
local KEY_SLOW    = Enum.KeyCode.LeftControl
local KEY_FOV_DEC = Enum.KeyCode.Z
local KEY_FOV_INC = Enum.KeyCode.X
local KEY_RESET_ORI = Enum.KeyCode.R

-- KONFIGURASI TELEPORT & FLOOR
local KEY_TELEPORT = Enum.KeyCode.T -- Tombol Teleport baru
local TELEPORT_BUTTON_TEXT = "TP"

local BASE_SPEED  = 16   -- studs/detik
local FAST_MULT   = 3
local SLOW_MULT   = 0.35
local ACCEL       = 10   -- smoothing translasi
local FOV_MIN, FOV_MAX = 30, 100

-- ====== STATE GABUNGAN ======
local droneEnabled = false
local move = {fwd = 0, right = 0, up = 0}
local speedMultFast, speedMultSlow = 1, 1
local createdFloor = nil
local floorHeightMode = "below"

local pos -- posisi drone
local vel = Vector3.zero
local saved = {}
local controls

-- Tambahkan referensi GUI global
local droneMovementGUIs
local floorCreatorGUIs

-- ====== UTIL ======
local function getPlayerModuleControls()
	local ok, mod = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	end)
	if ok and mod and mod.GetControls then
		return mod:GetControls()
	end
	return nil
end

local function character()
	return player.Character or player.CharacterAdded:Wait()
end

local function clamp(n, lo, hi)
	if n < lo then return lo end
	if n > hi then return hi end
	return n
end

-- ====== FUNGSI TELEPORT BIDIK ======
local function teleportToAim()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local offsetY = 5
	local rayOrigin = camera.CFrame.Position
	local rayDirection = camera.CFrame.LookVector * 1000
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char }
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(rayOrigin, rayDirection, params)
	local target

	if result then
		target = result.Position
		if result.Instance and (result.Instance:IsA("Terrain") or result.Instance.Anchored) then
			target = target + Vector3.new(0, offsetY, 0)
		end
	else
		target = rayOrigin + rayDirection
	end

	hrp.CFrame = CFrame.new(target, target + camera.CFrame.LookVector)
end

-- ====== FUNGSI KONTROL LANTAI ======
local function createFloor()
    local playerChar = player.Character
    local hrp = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        warn("HumanoidRootPart tidak ditemukan!")
        return
    end
    
    if createdFloor then
        createdFloor:Destroy()
    end
    
    local position
    if floorHeightMode == "below" then
        position = hrp.Position - Vector3.new(0, 3, 0)
    else
        position = hrp.Position + Vector3.new(0, 10, 0)
    end
    
    createdFloor = Instance.new("Part")
    createdFloor.Size = Vector3.new(1000, 0.1, 1000)
    createdFloor.Position = position
    createdFloor.Anchored = true
    createdFloor.Color = Color3.fromRGB(0, 0, 0)
    createdFloor.Transparency = 0.7
    createdFloor.Material = Enum.Material.SmoothPlastic
    createdFloor.Parent = workspace
    
    task.delay(60, function()
        if createdFloor and createdFloor.Parent then
            createdFloor:Destroy()
            createdFloor = nil
        end
    end)
end

-- ====== HINT GUI SINGKAT ======
local hintGui
local function showHint()
	if hintGui then hintGui:Destroy() end
	hintGui = Instance.new("ScreenGui")
	hintGui.Name = "DroneHintGui"
	hintGui.ResetOnSpawn = false
	hintGui.IgnoreGuiInset = true
	hintGui.DisplayOrder = 10

	local frame = Instance.new("Frame")
	frame.Parent = hintGui
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, -12, 1, -12)
	frame.Size = UDim2.new(0, 380, 0, 140)
	frame.BackgroundTransparency = 0.25
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0

	local pad = Instance.new("UIPadding", frame)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)

	local lbl = Instance.new("TextLabel")
	lbl.Parent = frame
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Text = table.concat({
		"DRONE VIEW AKTIF (V untuk keluar)",
		"Rotasi: DRAG sisi kanan layar (touchpad look bawaan)",
		"Gerak: WASD, Naik/Turun: E/Q (opsional)",
		"Shift/Ctrl: cepat/pelan • Z/X: FOV ± • R: reset pitch",
	}, "\n")

	hintGui.Parent = player:WaitForChild("PlayerGui")
	
	task.delay(5, function()
        if hintGui and hintGui.Parent then
            hintGui:Destroy()
        end
    end)
end

-- ====== RENDER HOOK ======
local bindName = "DroneAfterCamera"
local renderBound = false

local function bindRender()
	if renderBound then return end
	renderBound = true
	local prio = Enum.RenderPriority.Camera.Value + 1
	RunService:BindToRenderStep(bindName, prio, function(dt)
		local rot = camera.CFrame.Rotation
		local targetSpeed = BASE_SPEED * speedMultFast * speedMultSlow
		local dirWorld = Vector3.zero
		local forward = (CFrame.new(Vector3.zero) * rot).LookVector
		local rightv  = (CFrame.new(Vector3.zero) * rot).RightVector
		local upv     = Vector3.new(0,1,0)
		dirWorld = dirWorld + forward * move.fwd + rightv * move.right + upv * move.up
		if dirWorld.Magnitude > 1 then dirWorld = dirWorld.Unit end
		local targetVel = dirWorld * targetSpeed
		vel = vel + (targetVel - vel) * math.clamp(ACCEL * dt, 0, 1)
		pos = pos + vel * dt
		camera.CFrame = CFrame.new(pos) * rot
	end)
end

local function unbindRender()
	if renderBound then
		RunService:UnbindFromRenderStep(bindName)
		renderBound = false
	end
end

-- ====== ENABLE/DISABLE DRONE ======
local function enableDrone()
	if droneEnabled then return end
	droneEnabled = true
	
	local droneMovementGUIs = playerGui:FindFirstChild("DroneMovementGUIs")
	if droneMovementGUIs then droneMovementGUIs.Enabled = true end
	
	-- Sembunyikan FloorCreatorGUI
	local floorCreatorGUIs = playerGui:FindFirstChild("FloorCreatorGUI")
	if floorCreatorGUIs then floorCreatorGUIs.Enabled = false end

	saved.cameraType   = camera.CameraType
	saved.cameraSubject= camera.CameraSubject
	saved.cameraFOV    = camera.FieldOfView
	saved.cameraCFrame = camera.CFrame

	local ch = character()
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if hum then
		saved.walkSpeed = hum.WalkSpeed
		saved.jumpPower = hum.JumpPower
		saved.autoRotate = hum.AutoRotate
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.AutoRotate = false
	end
	if hrp then
		saved.charAnchored = hrp.Anchored
		hrp.Anchored = true
	end

	controls = controls or getPlayerModuleControls()
	if controls then controls:Enable() end

	camera.CameraType = Enum.CameraType.Custom

	local startCF = camera.CFrame
	if hrp then
		startCF = CFrame.new(hrp.Position + Vector3.new(0, 6, 0)) * CFrame.new(0,0,-6)
	end
	pos = startCF.Position
	vel = Vector3.zero

	showHint()
	bindRender()
end

local function disableDrone()
	if not droneEnabled then return end
	droneEnabled = false
	unbindRender()
	
	local droneMovementGUIs = playerGui:FindFirstChild("DroneMovementGUIs")
	if droneMovementGUIs then droneMovementGUIs.Enabled = false end

	-- Tampilkan kembali FloorCreatorGUI
	local floorCreatorGUIs = playerGui:FindFirstChild("FloorCreatorGUI")
	if floorCreatorGUIs then floorCreatorGUIs.Enabled = true end

	camera.CameraType = saved.cameraType or Enum.CameraType.Custom
	camera.FieldOfView = saved.cameraFOV or 70
	if saved.cameraSubject then camera.CameraSubject = saved.cameraSubject end
	if saved.cameraCFrame then camera.CFrame = saved.cameraCFrame end

	local ch = player.Character
	if ch then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch:FindFirstChild("HumanoidRootPart")
		if hum then
			hum.WalkSpeed = saved.walkSpeed or 16
			hum.JumpPower = saved.jumpPower or 50
			hum.AutoRotate = (saved.autoRotate ~= false)
		end
		if hrp and saved.charAnchored ~= nil then
			hrp.Anchored = saved.charAnchored
		end
	end
	if hintGui then hintGui:Destroy() hintGui = nil end
end

-- ====== VIRTUAL KEYBOARD GUI FUNCTIONS ======
local function updateDroneMovementFromVirtualKeys()
    if not droneEnabled then return end
    move.fwd = 0
    move.right = 0
    move.up = 0
    if wPressed then move.fwd = 1 end
    if sPressed then move.fwd = -1 end
    if aPressed then move.right = -1 end
    if dPressed then move.right = 1 end
    if ePressed then move.up = 1 end
    if qPressed then move.up = -1 end
end

local function createDroneMovementGUI()
	droneMovementGUIs = Instance.new("ScreenGui")
	droneMovementGUIs.Name = "DroneMovementGUIs"
	droneMovementGUIs.Parent = playerGui
	droneMovementGUIs.ResetOnSpawn = false
    droneMovementGUIs.Enabled = false

	local function createButton(parent, name, text, size, position, anchor, events)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Parent = parent
		button.Size = size
		button.Position = position
		button.AnchorPoint = anchor
		button.Text = text
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		if events then
			for eventName, func in pairs(events) do
				button[eventName]:Connect(func)
			end
		end
		return button
	end

	local wasdFrame = Instance.new("Frame")
	wasdFrame.Name = "WASD_Frame"
	wasdFrame.BackgroundTransparency = 1
	wasdFrame.Size = UDim2.new(0, 120, 0, 120)
	wasdFrame.Position = UDim2.new(0, 20, 1, -140)
	wasdFrame.Parent = droneMovementGUIs

	local wButton = createButton(wasdFrame, "WButton", "W", UDim2.new(0, 40, 0, 40), UDim2.new(0.5, 0, 0, 0), Vector2.new(0.5, 0), {
		MouseButton1Down = function() wPressed = true end, MouseButton1Up = function() wPressed = false end
	})
	local aButton = createButton(wasdFrame, "AButton", "A", UDim2.new(0, 40, 0, 40), UDim2.new(0, 0, 0.5, 0), Vector2.new(0, 0.5), {
		MouseButton1Down = function() aPressed = true end, MouseButton1Up = function() aPressed = false end
	})
	local sButton = createButton(wasdFrame, "SButton", "S", UDim2.new(0, 40, 0, 40), UDim2.new(0.5, 0, 1, 0), Vector2.new(0.5, 1), {
		MouseButton1Down = function() sPressed = true end, MouseButton1Up = function() sPressed = false end
	})
	local dButton = createButton(wasdFrame, "DButton", "D", UDim2.new(0, 40, 0, 40), UDim2.new(1, 0, 0.5, 0), Vector2.new(1, 0.5), {
		MouseButton1Down = function() dPressed = true end, MouseButton1Up = function() dPressed = false end
	})

	local rightFrame = Instance.new("Frame")
	rightFrame.Name = "Right_Side_Controls"
	rightFrame.BackgroundTransparency = 1
	rightFrame.Size = UDim2.new(0, 100, 0, 150)
	rightFrame.Position = UDim2.new(1, -120, 1, -170)
	rightFrame.Parent = droneMovementGUIs

	local eButton = createButton(rightFrame, "EButton", "E", UDim2.new(0, 40, 0, 40), UDim2.new(0.5, 0, 0.3, 0), Vector2.new(0.5, 0.5), {
		MouseButton1Down = function() ePressed = true end, MouseButton1Up = function() ePressed = false end
	})
	local qButton = createButton(rightFrame, "QButton", "Q", UDim2.new(0, 40, 0, 40), UDim2.new(0.5, 0, 0.7, 0), Vector2.new(0.5, 0.5), {
		MouseButton1Down = function() qPressed = true end, MouseButton1Up = function() qPressed = false end
	})
end

-- ====== CREATE DRONE TOGGLE BUTTON ======
local function createDroneToggleButton()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = playerGui
	screenGui.Name = "DroneToggleButtonGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true

	local button = Instance.new("TextButton")
	button.Parent = screenGui
	button.Name = "DRN_Button"
	button.Size = UDim2.new(0, 40, 0, 40)
	button.Position = UDim2.new(1, -70, 0.12, 0)
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Text = "DRN"
	button.TextSize = 8
	button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.3	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.MouseButton1Click:Connect(function()
		if droneEnabled then
			disableDrone()
			button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		else
			enableDrone()
			button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end
	end)
end

-- ====== CREATE TELEPORT GUI ======
local function createTeleportGUI()
	local teleportGui = Instance.new("ScreenGui")
	teleportGui.Name = "TeleportGUI"
	teleportGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	teleportGui.DisplayOrder = 9999
	teleportGui.IgnoreGuiInset = true
	teleportGui.ResetOnSpawn = false
	teleportGui.Enabled = true
	teleportGui.Parent = playerGui

	local frame = Instance.new("Frame", teleportGui)
	frame.Size = UDim2.fromOffset(70, 70)
	frame.Position = UDim2.new(0.9, -26, 0.3, 85)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.ZIndex = 50

	local btnAimTp = Instance.new("TextButton", frame)
	btnAimTp.Size = UDim2.fromOffset(50, 50)
	btnAimTp.AnchorPoint = Vector2.new(0.5, 0.5)
	btnAimTp.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnAimTp.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	btnAimTp.BackgroundTransparency = 0.5
	btnAimTp.Text = "TP"
	btnAimTp.Font = Enum.Font.GothamBold
	btnAimTp.TextSize = 16
	btnAimTp.TextColor3 = Color3.new(1, 1, 1)
	btnAimTp.ZIndex = 55
	Instance.new("UICorner", btnAimTp).CornerRadius = UDim.new(1, 0)

	local ZCROSS = 5
	local function makeCross(a, b, pos)
		local f = Instance.new("Frame", teleportGui)
		f.Size = UDim2.fromOffset(a, b)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = pos
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.ZIndex = ZCROSS
		return f
	end

	makeCross(4, 4, UDim2.new(0.5, 0, 0.5, 0))
	makeCross(20, 2, UDim2.new(0.5, 0, 0.5, 0))
	makeCross(2, 20, UDim2.new(0.5, 0, 0.5, 0))

	btnAimTp.MouseButton1Click:Connect(function()
		teleportToAim()
	end)
end

-- ====== CREATE FLOOR CREATOR GUI ======
local function createFloorCreatorGUI()
	floorCreatorGUIs = Instance.new("ScreenGui")
	floorCreatorGUIs.Name = "FloorCreatorGUI"
	floorCreatorGUIs.Parent = playerGui
	floorCreatorGUIs.ResetOnSpawn = false

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 80, 0, 175)
	Frame.Position = UDim2.new(0.8, -45, 0.6, -25)
	Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Frame.BackgroundTransparency = 0.9
	Frame.Parent = floorCreatorGUIs
	Frame.Draggable = false
	Frame.Active = false

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = Frame

	local ButtonsContainer = Instance.new("Frame")
	ButtonsContainer.Size = UDim2.new(1, -10, 1, -30)
	ButtonsContainer.Position = UDim2.new(0, 5, 0, 25)
	ButtonsContainer.BackgroundTransparency = 1
	ButtonsContainer.Parent = Frame

	local function createButton(yPosition, size, text)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, size, 0, size)
		button.Position = UDim2.new(0.5, -size/2, 0, yPosition)
		button.Text = text
		button.Font = Enum.Font.Gotham
		button.TextSize = 12
		button.TextColor3 = Color3.fromRGB(250, 250, 250)
		button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		button.BackgroundTransparency = 0.5
		button.BorderSizePixel = 0
		button.Parent = ButtonsContainer
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = button
		
		return button
	end

	local UpButton = createButton(0, 30, "↑")
	local CreateButton = createButton(35, 40, "FLOOR")
	local DownButton = createButton(80, 30, "↓")
	local HeightButton = createButton(115, 30, "BELOW")

	CreateButton.MouseButton1Click:Connect(function()
		createFloor()
	end)

	HeightButton.MouseButton1Click:Connect(function()
		if floorHeightMode == "below" then
			floorHeightMode = "above"
			HeightButton.Text = "ABOVE"
		else
			floorHeightMode = "below"
			HeightButton.Text = "BELOW"
		end
		if createdFloor then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				if floorHeightMode == "below" then
					createdFloor.Position = hrp.Position - Vector3.new(0, 3, 0)
				else
					createdFloor.Position = hrp.Position + Vector3.new(0, 10, 0)
				end
			end
		end
	end)

	local movingUp = false
	local movingDown = false

	UpButton.MouseButton1Down:Connect(function()
		movingUp = true
		task.spawn(function()
			while movingUp and createdFloor do
				createdFloor.Position = createdFloor.Position + Vector3.new(0, 1, 0)
				task.wait(0.1)
			end
		end)
	end)
	UpButton.MouseButton1Up:Connect(function()
		movingUp = false
	end)
	UpButton.MouseLeave:Connect(function()
		movingUp = false
	end)

	DownButton.MouseButton1Down:Connect(function()
		movingDown = true
		task.spawn(function()
			while movingDown and createdFloor do
				createdFloor.Position = createdFloor.Position - Vector3.new(0, 1, 0)
				task.wait(0.1)
			end
		end)
	end)
	DownButton.MouseButton1Up:Connect(function()
		movingDown = false
	end)
	DownButton.MouseLeave:Connect(function()
		movingDown = false
	end)

	local function setupButtonHover(button)
		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		end)
	end

	setupButtonHover(CreateButton)
	setupButtonHover(UpButton)
	setupButtonHover(DownButton)
	setupButtonHover(HeightButton)
end

-- ====== INPUT HANDLING ======
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	if input.KeyCode == TOGGLE_KEY then
		if droneEnabled then
			disableDrone()
		else
			enableDrone()
		end
	end
	
	if input.KeyCode == KEY_TELEPORT then
		teleportToAim()
	end
	
	if not droneEnabled then return end

	local key = input.KeyCode
	if key == KEY_FORWARD then
		wPressed = true
	elseif key == KEY_BACK then
		sPressed = true
	elseif key == KEY_LEFT then
		aPressed = true
	elseif key == KEY_RIGHT then
		dPressed = true
	elseif key == KEY_UP then
		ePressed = true
	elseif key == KEY_DOWN then
		qPressed = true
	elseif key == KEY_FAST then
		speedMultFast = FAST_MULT
	elseif key == KEY_SLOW then
		speedMultSlow = SLOW_MULT
	elseif key == KEY_FOV_DEC then
		camera.FieldOfView = math.max(FOV_MIN, camera.FieldOfView - 2)
	elseif key == KEY_FOV_INC then
		camera.FieldOfView = math.min(FOV_MAX, camera.FieldOfView + 2)
	elseif key == KEY_RESET_ORI then
		-- Tambahkan logika untuk reset pitch
	end
end)

UserInputService.InputEnded:Connect(function(input)
	local key = input.KeyCode
	if key == KEY_FORWARD then wPressed = false
	elseif key == KEY_BACK then sPressed = false
	elseif key == KEY_LEFT then aPressed = false
	elseif key == KEY_RIGHT then dPressed = false
	elseif key == KEY_UP then ePressed = false
	elseif key == KEY_DOWN then qPressed = false
	elseif key == KEY_FAST then speedMultFast = 1
	elseif key == KEY_SLOW then speedMultSlow = 1
	end
end)

-- ====== UPDATE LOOP ======
RunService.RenderStepped:Connect(function()
	updateDroneMovementFromVirtualKeys()
end)

-- ====== INITIALIZATION ======
createDroneMovementGUI()
createDroneToggleButton()
createTeleportGUI()
createFloorCreatorGUI()

player.CharacterAdded:Connect(function()
	if droneEnabled then disableDrone() end
end)

game:BindToClose(function()
	if droneEnabled then disableDrone() end
end)

print("Semua fungsionalitas telah digabungkan!")
