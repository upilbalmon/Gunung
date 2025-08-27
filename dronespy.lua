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
	rendBound = true
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
		rendBound = false
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
		hr...