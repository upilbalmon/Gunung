--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

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

local BASE_SPEED  = 40   -- studs/detik
local FAST_MULT   = 3
local SLOW_MULT   = 0.35
local ACCEL       = 10   -- smoothing translasi
local FOV_MIN, FOV_MAX = 30, 100

-- ====== STATE DRONE ======
local droneEnabled = false
local move = {fwd = 0, right = 0, up = 0}
local speedMultFast, speedMultSlow = 1, 1

local pos -- posisi drone
local pitch, yaw = 0, 0 -- hanya untuk reset pitch
local vel = Vector3.zero

local saved = {
	cameraType = nil,
	cameraSubject = nil,
	cameraFOV = nil,
	cameraCFrame = nil,
	charAnchored = nil,
	walkSpeed = nil,
	jumpPower = nil,
	autoRotate = nil,
}

local controls -- PlayerModule controls

-- ====== VIRTUAL KEYBOARD STATE ======
local wPressed = false
local sPressed = false
local aPressed = false
local dPressed = false
local ePressed = false
local qPressed = false
local shiftPressed = false
local ctrlPressed = false

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
end

-- ====== RENDER HOOK ======
local bindName = "DroneAfterCamera"
local renderBound = false

local function bindRender()
	if renderBound then return end
	renderBound = true
	-- Jalankan SETELAH kamera bawaan update, supaya orientasi sudah final
	local prio = Enum.RenderPriority.Camera.Value + 1
	RunService:BindToRenderStep(bindName, prio, function(dt)
		-- ambil ORIENTASI dari kamera bawaan
		local rot = camera.CFrame.Rotation
		-- update translasi drone
		local targetSpeed = BASE_SPEED * speedMultFast * speedMultSlow
		local dirWorld = Vector3.zero
		-- arah lokal relatif orientasi kamera bawaan
		local forward = (CFrame.new(Vector3.zero) * rot).LookVector
		local rightv  = (CFrame.new(Vector3.zero) * rot).RightVector
		local upv     = Vector3.new(0,1,0)
		dirWorld = dirWorld + forward * move.fwd + rightv * move.right + upv * move.up
		if dirWorld.Magnitude > 1 then dirWorld = dirWorld.Unit end
		local targetVel = dirWorld * targetSpeed
		vel = vel + (targetVel - vel) * math.clamp(ACCEL * dt, 0, 1)
		pos = pos + vel * dt

		-- timpa POSISI kamera, pertahankan ROTASI bawaan
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

	-- simpan state
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

	-- Penting: JANGAN disable PlayerModule; biarkan kontrol touch aktif
	controls = controls or getPlayerModuleControls()
	if controls then controls:Enable() end

	-- Kamera harus Custom agar touch look berfungsi
	camera.CameraType = Enum.CameraType.Custom

	-- posisi awal = dekat karakter / kamera saat ini
	local startCF = camera.CFrame
	if hrp then
		startCF = CFrame.new(hrp.Position + Vector3.new(0, 6, 0)) * CFrame.new(0,0,-6)
	end
	pos = startCF.Position
	local rx = startCF:ToEulerAnglesYXZ()
	pitch = rx
	vel = Vector3.zero

	showHint()
	bindRender()
end

local function disableDrone()
	if not droneEnabled then return end
	droneEnabled = false
	unbindRender()

	-- pulihkan kamera & karakter
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

-- ====== VIRTUAL KEYBOARD FUNCTIONS ======
local function updateDroneMovementFromVirtualKeys()
    if not droneEnabled then return end
    
    -- Update movement based on virtual keyboard state
    move.fwd = 0
    move.right = 0
    move.up = 0
    
    if wPressed then move.fwd = 1 end
    if sPressed then move.fwd = -1 end
    if aPressed then move.right = -1 end
    if dPressed then move.right = 1 end
    if ePressed then move.up = 1 end
    if qPressed then move.up = -1 end
    
    -- Update speed multipliers
    speedMultFast = shiftPressed and FAST_MULT or 1
    speedMultSlow = ctrlPressed and SLOW_MULT or 1
end

-- ====== CREATE VIRTUAL KEYBOARD GUI ======
local function createVirtualKeyboard()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VirtualKeyboardGUI"
	screenGui.Parent = playerGui
	screenGui.ResetOnSpawn = false

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 200, 0, 200)
	Frame.Position = UDim2.new(0.7, 0, 0.5, -100)
	Frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	Frame.BackgroundTransparency = 0.3
	Frame.Parent = screenGui
	Frame.Draggable = true
	Frame.Active = true

	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Size = UDim2.new(0, 10, 0, 10)
	MinimizeButton.Position = UDim2.new(0.7, -20, 0.1, 0)
	MinimizeButton.Text = "-"
	MinimizeButton.Font = Enum.Font.SourceSansBold
	MinimizeButton.TextSize = 7
	MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
	MinimizeButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
	MinimizeButton.Parent = Frame

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 10, 0, 10)
	CloseButton.Position = UDim2.new(0.85, -20, 0.1, 0)
	CloseButton.Text = "X"
	CloseButton.Font = Enum.Font.SourceSansBold
	CloseButton.TextSize = 7
	CloseButton.TextColor3 = Color3.new(1, 1, 1)
	CloseButton.BackgroundColor3 = Color3.new(0.8, 0, 0)
	CloseButton.Parent = Frame

	-- Tombol W (atas)
	local wButton = Instance.new("TextButton")
	wButton.Name = "WButton"
	wButton.Size = UDim2.new(0, 40, 0, 40)
	wButton.Position = UDim2.new(0.5, -20, 0.2, 0)
	wButton.AnchorPoint = Vector2.new(0.5, 0)
	wButton.Text = "W"
	wButton.TextSize = 16
	wButton.Font = Enum.Font.GothamBold
	wButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	wButton.TextColor3 = Color3.new(1, 1, 1)
	wButton.BorderSizePixel = 0
	wButton.Parent = Frame

	-- Tombol A (kiri)
	local aButton = Instance.new("TextButton")
	aButton.Name = "AButton"
	aButton.Size = UDim2.new(0, 40, 0, 40)
	aButton.Position = UDim2.new(0.2, 0, 0.5, -20)
	aButton.AnchorPoint = Vector2.new(0, 0.5)
	aButton.Text = "A"
	aButton.TextSize = 16
	aButton.Font = Enum.Font.GothamBold
	aButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	aButton.TextColor3 = Color3.new(1, 1, 1)
	aButton.BorderSizePixel = 0
	aButton.Parent = Frame

	-- Tombol S (bawah)
	local sButton = Instance.new("TextButton")
	sButton.Name = "SButton"
	sButton.Size = UDim2.new(0, 40, 0, 40)
	sButton.Position = UDim2.new(0.5, -20, 0.5, -20)
	sButton.AnchorPoint = Vector2.new(0.5, 0.5)
	sButton.Text = "S"
	sButton.TextSize = 16
	sButton.Font = Enum.Font.GothamBold
	sButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	sButton.TextColor3 = Color3.new(1, 1, 1)
	sButton.BorderSizePixel = 0
	sButton.Parent = Frame

	-- Tombol D (kanan)
	local dButton = Instance.new("TextButton")
	dButton.Name = "DButton"
	dButton.Size = UDim2.new(0, 40, 0, 40)
	dButton.Position = UDim2.new(0.8, -40, 0.5, -20)
	dButton.AnchorPoint = Vector2.new(1, 0.5)
	dButton.Text = "D"
	dButton.TextSize = 16
	dButton.Font = Enum.Font.GothamBold
	dButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	dButton.TextColor3 = Color3.new(1, 1, 1)
	dButton.BorderSizePixel = 0
	dButton.Parent = Frame

	-- Tombol E (naik)
	local eButton = Instance.new("TextButton")
	eButton.Name = "EButton"
	eButton.Size = UDim2.new(0, 35, 0, 35)
	eButton.Position = UDim2.new(0.8, 0, 0.2, 0)
	eButton.Text = "E"
	eButton.TextSize = 14
	eButton.Font = Enum.Font.GothamBold
	eButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	eButton.TextColor3 = Color3.new(1, 1, 1)
	eButton.BorderSizePixel = 0
	eButton.Parent = Frame

	-- Tombol Q (turun)
	local qButton = Instance.new("TextButton")
	qButton.Name = "QButton"
	qButton.Size = UDim2.new(0, 35, 0, 35)
	qButton.Position = UDim2.new(0.2, -35, 0.2, 0)
	qButton.Text = "Q"
	qButton.TextSize = 14
	qButton.Font = Enum.Font.GothamBold
	qButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	qButton.TextColor3 = Color3.new(1, 1, 1)
	qButton.BorderSizePixel = 0
	qButton.Parent = Frame

	-- Tombol Shift (cepat)
	local shiftButton = Instance.new("TextButton")
	shiftButton.Name = "ShiftButton"
	shiftButton.Size = UDim2.new(0, 50, 0, 25)
	shiftButton.Position = UDim2.new(0.2, 0, 0.8, 0)
	shiftButton.Text = "SHIFT"
	shiftButton.TextSize = 10
	shiftButton.Font = Enum.Font.GothamBold
	shiftButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	shiftButton.TextColor3 = Color3.new(1, 1, 1)
	shiftButton.BorderSizePixel = 0
	shiftButton.Parent = Frame

	-- Tombol Ctrl (pelan)
	local ctrlButton = Instance.new("TextButton")
	ctrlButton.Name = "CtrlButton"
	ctrlButton.Size = UDim2.new(0, 50, 0, 25)
	ctrlButton.Position = UDim2.new(0.8, -50, 0.8, 0)
	ctrlButton.Text = "CTRL"
	ctrlButton.TextSize = 10
	ctrlButton.Font = Enum.Font.GothamBold
	ctrlButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	ctrlButton.TextColor3 = Color3.new(1, 1, 1)
	ctrlButton.BorderSizePixel = 0
	ctrlButton.Parent = Frame

	-- Fungsi untuk tombol W
	wButton.MouseButton1Down:Connect(function()
		wPressed = true
		wButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	wButton.MouseButton1Up:Connect(function()
		wPressed = false
		wButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	wButton.MouseLeave:Connect(function()
		if wPressed then
			wPressed = false
			wButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol S
	sButton.MouseButton1Down:Connect(function()
		sPressed = true
		sButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	sButton.MouseButton1Up:Connect(function()
		sPressed = false
		sButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	sButton.MouseLeave:Connect(function()
		if sPressed then
			sPressed = false
			sButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol A
	aButton.MouseButton1Down:Connect(function()
		aPressed = true
		aButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	aButton.MouseButton1Up:Connect(function()
		aPressed = false
		aButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	aButton.MouseLeave:Connect(function()
		if aPressed then
			aPressed = false
			aButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol D
	dButton.MouseButton1Down:Connect(function()
		dPressed = true
		dButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	dButton.MouseButton1Up:Connect(function()
		dPressed = false
		dButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	dButton.MouseLeave:Connect(function()
		if dPressed then
			dPressed = false
			dButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol E
	eButton.MouseButton1Down:Connect(function()
		ePressed = true
		eButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	eButton.MouseButton1Up:Connect(function()
		ePressed = false
		eButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	eButton.MouseLeave:Connect(function()
		if ePressed then
			ePressed = false
			eButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol Q
	qButton.MouseButton1Down:Connect(function()
		qPressed = true
		qButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	qButton.MouseButton1Up:Connect(function()
		qPressed = false
		qButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	qButton.MouseLeave:Connect(function()
		if qPressed then
			qPressed = false
			qButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol Shift
	shiftButton.MouseButton1Down:Connect(function()
		shiftPressed = true
		shiftButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	shiftButton.MouseButton1Up:Connect(function()
		shiftPressed = false
		shiftButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	shiftButton.MouseLeave:Connect(function()
		if shiftPressed then
			shiftPressed = false
			shiftButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol Ctrl
	ctrlButton.MouseButton1Down:Connect(function()
		ctrlPressed = true
		ctrlButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
	end)

	ctrlButton.MouseButton1Up:Connect(function()
		ctrlPressed = false
		ctrlButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
	end)

	ctrlButton.MouseLeave:Connect(function()
		if ctrlPressed then
			ctrlPressed = false
			ctrlButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
		end
	end)

	-- Fungsi untuk tombol Minimize/Maximize
	local minimized = false
	local originalSize = Frame.Size
	local minimizedSize = UDim2.new(0, 70, 0, 20)

	MinimizeButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Frame.Size = minimizedSize
			MinimizeButton.Text = "+"
			wButton.Visible = false
			sButton.Visible = false
			aButton.Visible = false
			dButton.Visible = false
			eButton.Visible = false
			qButton.Visible = false
			shiftButton.Visible = false
			ctrlButton.Visible = false
		else
			Frame.Size = originalSize
			MinimizeButton.Text = "-"
			wButton.Visible = true
			sButton.Visible = true
			aButton.Visible = true
			dButton.Visible = true
			eButton.Visible = true
			qButton.Visible = true
			shiftButton.Visible = true
			ctrlButton.Visible = true
		end
	end)

	-- Fungsi untuk tombol Close
	CloseButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)
end

-- ====== CREATE DRONE TOGGLE BUTTON ======
local function createDroneToggleButton()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = playerGui
	screenGui.ResetOnSpawn = false

	-- Tombol untuk mengaktifkan/mematikan drone
	local button = Instance.new("TextButton")
	button.Parent = screenGui
	button.Size = UDim2.new(0, 40, 0, 40)
	button.Position = UDim2.new(1, -70, 0.12, 0)
	button.Text = "DRN"
	button.TextSize = 8
	button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.3	
	
	-- Tambahkan round corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	-- Menambahkan event handler untuk klik tombol
	button.MouseButton1Click:Connect(function()
		if droneEnabled then
			disableDrone()
			button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			button.BackgroundTransparency = 0.3
		else
			enableDrone()
			button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			button.BackgroundTransparency = 0.3
		end
	end)
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
	
	if not droneEnabled then return end

	if input.KeyCode == KEY_FORWARD then
		move.fwd = 1
	elseif input.KeyCode == KEY_BACK then
		move.fwd = -1
	elseif input.KeyCode == KEY_LEFT then
		move.right = -1
	elseif input.KeyCode == KEY_RIGHT then
		move.right = 1
	elseif input.KeyCode == KEY_UP then
		move.up = 1
	elseif input.KeyCode == KEY_DOWN then
		move.up = -1
	elseif input.KeyCode == KEY_FAST then
		speedMultFast = FAST_MULT
	elseif input.KeyCode == KEY_SLOW then
		speedMultSlow = SLOW_MULT
	elseif input.KeyCode == KEY_FOV_DEC then
		camera.FieldOfView = math.max(FOV_MIN, camera.FieldOfView - 2)
	elseif input.KeyCode == KEY_FOV_INC then
		camera.FieldOfView = math.min(FOV_MAX, camera.FieldOfView + 2)
	elseif input.KeyCode == KEY_RESET_ORI then
		pitch = 0
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not droneEnabled then return end

	if input.KeyCode == KEY_FORWARD and move.fwd == 1 then move.fwd = 0 end
	if input.KeyCode == KEY_BACK and move.fwd == -1 then move.fwd = 0 end
	if input.KeyCode == KEY_LEFT and move.right == -1 then move.right = 0 end
	if input.KeyCode == KEY_RIGHT and move.right == 1 then move.right = 0 end
	if input.KeyCode == KEY_UP and move.up == 1 then move.up = 0 end
	if input.KeyCode == KEY_DOWN and move.up == -1 then move.up = 0 end
	if input.KeyCode == KEY_FAST then speedMultFast = 1 end
	if input.KeyCode == KEY_SLOW then speedMultSlow = 1 end
end)

-- ====== UPDATE LOOP ======
RunService.RenderStepped:Connect(function()
	updateDroneMovementFromVirtualKeys()
end)

-- ====== INITIALIZATION ======
createVirtualKeyboard()
createDroneToggleButton()

-- Jika karakter respawn saat drone aktif, nonaktifkan biar state bersih
player.CharacterAdded:Connect(function()
	if droneEnabled then disableDrone() end
end)

game:BindToClose(function()
	if droneEnabled then disableDrone() end
end)

print("Virtual Keyboard dan Drone View loaded!")
