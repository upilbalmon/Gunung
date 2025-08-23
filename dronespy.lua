--[[ DRONE VIEW / FREECAM PENGINTAI — VERSI MOBILE ROBLOX DENGAN GUI BUTTON ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ====== KONFIG ======
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

-- ====== STATE ======
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

-- ====== ENABLE/DISABLE ======
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

-- ====== GUI BUTTON ======
local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Tombol untuk mengaktifkan/mematikan drone
	local button = Instance.new("TextButton")
	button.Parent = screenGui
	button.Size = UDim2.new(0, 60, 0, 30)
	button.Position = UDim2.new(0.5, -10, 0.5, -25)  -- Tengah layar
	button.Text = "Drone"
	button.TextSize = 24
	button.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)

	-- Menambahkan event handler untuk klik tombol
	button.MouseButton1Click:Connect(function()
		if droneEnabled then
			disableDrone()
			button.Text = "Aktifkan Drone"
		else
			enableDrone()
			button.Text = "Matikan Drone"
		end
	end)
end

-- Panggil fungsi untuk membuat tombol GUI saat permainan dimulai
createGui()

-- ====== INPUT GERAK ======
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
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

-- Jika karakter respawn saat drone aktif, nonaktifkan biar state bersih
player.CharacterAdded:Connect(function()
	if droneEnabled then disableDrone() end
end)

game:BindToClose(function()
	if droneEnabled then disableDrone() end
end)
