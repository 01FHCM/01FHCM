-- FPS Booster (Mobile) com botão ON/OFF
-- Reduz gráficos: sombras, partículas, efeitos, materiais e água.
-- Ao desativar, restaura tudo ao normal.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Evita duplicar se executar duas vezes
local GUI_NAME = "FPSBoosterGui"
pcall(function()
	local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
end)
pcall(function()
	local old = lp.PlayerGui:FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
end)

local enabled = false
local busy = false
local saved = setmetatable({}, { __mode = "k" }) -- [instância] = {propriedade = valorOriginal}
local connections = {}
local originalQuality

local function save(inst, prop, newValue)
	local ok, old = pcall(function() return inst[prop] end)
	if not ok then return end
	saved[inst] = saved[inst] or {}
	if saved[inst][prop] == nil then
		saved[inst][prop] = old
	end
	pcall(function() inst[prop] = newValue end)
end

local function optimize(inst)
	if inst:IsA("BasePart") then
		save(inst, "Material", Enum.Material.SmoothPlastic)
	elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
		or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
		save(inst, "Enabled", false)
	elseif inst:IsA("PostEffect") then
		save(inst, "Enabled", false)
	elseif inst:IsA("Atmosphere") then
		save(inst, "Density", 0)
		save(inst, "Haze", 0)
	end
end

local function applyLighting()
	save(Lighting, "GlobalShadows", false)
	save(Lighting, "FogEnd", 9e9)
	save(Lighting, "ShadowSoftness", 0)
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		save(terrain, "WaterWaveSize", 0)
		save(terrain, "WaterWaveSpeed", 0)
		save(terrain, "WaterReflectance", 0)
	end
	pcall(function()
		originalQuality = originalQuality or settings().Rendering.QualityLevel
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
end

local function enable()
	if busy then return end
	busy = true
	enabled = true

	applyLighting()

	-- Novos efeitos (skills de PvP) também são cortados enquanto ativo
	-- Só efeitos (barato). Partes novas são ignoradas para evitar picos de lag.
	local function onAdded(d)
		if enabled and not d:IsA("BasePart") then optimize(d) end
	end
	table.insert(connections, Workspace.DescendantAdded:Connect(onAdded))
	table.insert(connections, Lighting.DescendantAdded:Connect(onAdded))

	-- Limita FPS a 60 (menos calor = menos travadas por throttling do celular)
	pcall(function()
		if setfpscap then setfpscap(60) end
	end)

	-- Processa em lotes para não travar o celular
	local function run(list)
		for i, d in ipairs(list) do
			if not enabled then return end
			optimize(d)
			if i % 100 == 0 then task.wait() end
		end
	end
	run(Lighting:GetDescendants())
	run(Workspace:GetDescendants())

	busy = false
end

local function disable()
	enabled = false
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)

	-- Espera o lote terminar, se ainda estiver rodando
	while busy do task.wait() end
	busy = true

	local n = 0
	for inst, props in pairs(saved) do
		for prop, value in pairs(props) do
			pcall(function() inst[prop] = value end)
		end
		n += 1
		if n % 100 == 0 then task.wait() end
	end
	table.clear(saved)

	pcall(function()
		if originalQuality then
			settings().Rendering.QualityLevel = originalQuality
			originalQuality = nil
		end
	end)
	busy = false
end

-- ========== BOTÃO ==========
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 110, 0, 38)
btn.Position = UDim2.new(0, 12, 0.35, 0)
btn.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.Text = "FPS: OFF"
btn.AutoButtonColor = false
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

local function refresh()
	btn.Text = enabled and "FPS: ON" or "FPS: OFF"
	btn.BackgroundColor3 = enabled and Color3.fromRGB(45, 170, 80) or Color3.fromRGB(190, 50, 50)
end

local function toggle()
	if busy then return end
	if enabled then
		task.spawn(disable)
	else
		task.spawn(enable)
	end
	refresh()
end

-- Toque = liga/desliga | Arrastar = move o botão
local dragging, moved, dragStart, startPos = false, false, nil, nil

btn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging, moved = true, false
		dragStart, startPos = input.Position, btn.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if not moved then toggle() end
			end
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		if delta.Magnitude > 8 then moved = true end
		if moved then
			btn.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end
end)
