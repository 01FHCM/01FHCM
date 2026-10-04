-- FPS Booster + Auto Farm Bones (Blox Fruits) com menu de ligar/desligar
-- Auto Farm: mata todos os NPCs da ilha Haunted Castle (Terceiro Mar)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Terrain = workspace.Terrain
local player = Players.LocalPlayer

local State = {}      -- estado de cada toggle
local Saved = {}      -- valores originais (para restaurar)

----------------------------------------------------------------
-- OPÇÕES DE FPS (cada uma tem ligar/desligar)
----------------------------------------------------------------
local Features = {}

Features["Qualidade mínima"] = function(on)
    pcall(function()
        if on then
            Saved.quality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        elseif Saved.quality then
            settings().Rendering.QualityLevel = Saved.quality
        end
    end)
end

Features["Sem sombras"] = function(on)
    if on then Saved.shadows = Lighting.GlobalShadows end
    Lighting.GlobalShadows = (not on) and (Saved.shadows ~= false)
end

Features["Sem efeitos de luz"] = function(on)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") then
            pcall(function()
                if on then Saved[v] = v.Enabled ~= false end
                v.Enabled = (not on) and (Saved[v] ~= false)
            end)
        end
    end
end

Features["Água simples"] = function(on)
    if on then
        Saved.water = {Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance}
        Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance = 0, 0, 0
    elseif Saved.water then
        Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance = unpack(Saved.water)
    end
end

Features["Sem partículas"] = function(on)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke")
            or o:IsA("Fire") or o:IsA("Sparkles") then
            pcall(function()
                if on then Saved[o] = o.Enabled end
                o.Enabled = (not on) and (Saved[o] ~= false)
            end)
        end
    end
end

Features["Materiais simples"] = function(on)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not o:IsDescendantOf(player.Character or workspace) then
            pcall(function()
                if on then
                    Saved[o] = {o.Material, o.Reflectance, o.CastShadow}
                    o.Material = Enum.Material.Plastic
                    o.Reflectance = 0
                    o.CastShadow = false
                elseif Saved[o] then
                    o.Material, o.Reflectance, o.CastShadow = unpack(Saved[o])
                end
            end)
        end
    end
end

-- Aplica em objetos novos enquanto as opções estiverem ligadas
workspace.DescendantAdded:Connect(function(o)
    pcall(function()
        if State["Sem partículas"] and (o:IsA("ParticleEmitter") or o:IsA("Trail")
            or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles")) then
            o.Enabled = false
        elseif State["Materiais simples"] and o:IsA("BasePart") then
            o.Material = Enum.Material.Plastic
            o.Reflectance = 0
            o.CastShadow = false
        end
    end)
end)

----------------------------------------------------------------
-- AUTO FARM HAUNTED CASTLE (mata todos os NPCs da ilha)
----------------------------------------------------------------
local ISLAND_CENTER = Vector3.new(-9515, 142, 5535) -- centro do Haunted Castle
local ISLAND_RADIUS = 1200                          -- só ataca NPCs dentro desse raio
local HEIGHT = 7                                    -- altura acima do NPC
local WeaponTypes = {"Melee", "Sword", "Blox Fruit", "Gun"}
local WeaponIndex = 1
local FARM = "Matar NPCs Haunted Castle"
local QUEST = "Aceitar missão (opcional)"

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

-- Pega o NPC vivo mais próximo que esteja na ilha (qualquer NPC)
local function nearestMob()
    local root = getRoot()
    local folder = workspace:FindFirstChild("Enemies")
    if not root or not folder then return end
    local best, dist = nil, math.huge
    for _, m in ipairs(folder:GetChildren()) do
        local hum, hrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0
            and (hrp.Position - ISLAND_CENTER).Magnitude <= ISLAND_RADIUS then
            local d = (hrp.Position - root.Position).Magnitude
            if d < dist then best, dist = m, d end
        end
    end
    return best
end

-- Equipa o estilo de luta escolhido no botão "Arma"
local function equipWeapon()
    local c = player.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local want = WeaponTypes[WeaponIndex]
    local held = c:FindFirstChildOfClass("Tool")
    if held and held.ToolTip == want then return held end
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == want then
            hum:EquipTool(t)
            return t
        end
    end
end

local function startQuest(mobName)
    pcall(function()
        local gui = player.PlayerGui:FindFirstChild("Main")
        local q = gui and gui:FindFirstChild("Quest")
        if q and q.Visible then return end
        local isQ2 = mobName:find("Demonic") or mobName:find("Posessed") or mobName:find("Possessed")
        RS.Remotes.CommF_:InvokeServer("StartQuest", isQ2 and "HauntedQuest2" or "HauntedQuest1", isQ2 and 2 or 1)
    end)
end

-- Voa até a ilha (os NPCs só carregam perto do jogador)
local THIRD_SEA = 7449423635
local Flying = false
local currentTween

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Menu", Text = text, Duration = 4})
    end)
end

local function flyToIsland()
    if Flying then return end
    local root = getRoot()
    if not root then return end
    if game.PlaceId ~= THIRD_SEA then
        notify("O Haunted Castle fica no Terceiro Mar!")
        return
    end
    Flying = true
    notify("Voando até o Haunted Castle...")
    local target = CFrame.new(ISLAND_CENTER + Vector3.new(0, 60, 0))
    local dist = (root.Position - target.Position).Magnitude
    currentTween = TweenService:Create(root, TweenInfo.new(dist / 300, Enum.EasingStyle.Linear), {CFrame = target})
    currentTween:Play()
    currentTween.Completed:Wait()
    currentTween = nil
    Flying = false
end

local function cancelFly()
    if currentTween then pcall(function() currentTween:Cancel() end) end
    currentTween = nil
    Flying = false
end

local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Target = nil
local holder = nil

-- Clique de ataque (3 métodos juntos para garantir que o jogo reconheça)
local function attackClick(tool)
    if tool then pcall(function() tool:Activate() end) end
    pcall(function()
        local c = workspace.CurrentCamera.ViewportSize / 2
        VIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 1)
        VIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 1)
    end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(1280, 672))
        VirtualUser:Button1Up(Vector2.new(1280, 672))
    end)
end

local function validTarget(m)
    local h = m and m.Parent and m:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 and m:FindFirstChild("HumanoidRootPart")
end

-- 1) Escolhe o alvo (mais próximo dentro da ilha)
task.spawn(function()
    while true do
        task.wait(0.1)
        if State[FARM] and not Flying then
            pcall(function()
                local root, hum = getRoot()
                if not root or not hum or hum.Health <= 0 then Target = nil return end
                if validTarget(Target) then return end
                Target = nearestMob()
                if not Target and (root.Position - ISLAND_CENTER).Magnitude > ISLAND_RADIUS * 0.6 then
                    flyToIsland()
                end
                if Target and State[QUEST] then startQuest(Target.Name) end
            end)
        else
            Target = nil
        end
    end
end)

-- 2) Segura o personagem em cima do NPC a cada frame (sem tremer)
RunService.Heartbeat:Connect(function()
    local root, hum = getRoot()
    local active = State[FARM] and not Flying and root and hum and hum.Health > 0 and validTarget(Target)
    if active then
        if not holder or holder.Parent ~= root then
            if holder then holder:Destroy() end
            holder = Instance.new("BodyVelocity")
            holder.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            holder.Velocity = Vector3.zero
            holder.Parent = root
        end
        local pos = Target.HumanoidRootPart.Position + Vector3.new(0, HEIGHT, 0)
        root.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(-90), 0, 0) -- olhando para baixo
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    elseif holder then
        holder:Destroy()
        holder = nil
    end
end)

-- 3) Ataca sem parar enquanto houver alvo
task.spawn(function()
    while true do
        task.wait(0.08)
        if State[FARM] and not Flying and validTarget(Target) then
            local tool = equipWeapon()
            attackClick(tool)
        end
    end
end)

-- Sem colisão enquanto farma
RunService.Stepped:Connect(function()
    if State[FARM] and player.Character then
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

----------------------------------------------------------------
-- MENU (botões liga/desliga)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BF_Menu"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 210, 0, 0)
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.Position = UDim2.new(0, 10, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.Active, frame.Draggable = true, true
Instance.new("UICorner", frame)
local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 4)
local pad = Instance.new("UIPadding", frame)
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundTransparency = 1
title.Text = "Menu (arraste)"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local function addToggle(name, callback)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, 0, 0, 30)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b)
    State[name] = false
    local function refresh()
        b.Text = name .. ": " .. (State[name] and "ON" or "OFF")
        b.BackgroundColor3 = State[name] and Color3.fromRGB(40, 150, 70) or Color3.fromRGB(150, 45, 45)
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        State[name] = not State[name]
        refresh()
        if callback then task.spawn(callback, State[name]) end
    end)
end

addToggle(FARM, function(on)
    if on then
        local root = getRoot()
        if root and (root.Position - ISLAND_CENTER).Magnitude > ISLAND_RADIUS * 0.6 then
            flyToIsland()
        end
    else
        cancelFly()
    end
end)
addToggle(QUEST)

-- Botão para trocar o estilo de luta (Melee / Sword / Blox Fruit / Gun)
local wb = Instance.new("TextButton", frame)
wb.Size = UDim2.new(1, 0, 0, 30)
wb.Font = Enum.Font.Gotham
wb.TextSize = 13
wb.TextColor3 = Color3.new(1, 1, 1)
wb.BackgroundColor3 = Color3.fromRGB(50, 80, 160)
Instance.new("UICorner", wb)
wb.Text = "Arma: " .. WeaponTypes[WeaponIndex]
wb.MouseButton1Click:Connect(function()
    WeaponIndex = WeaponIndex % #WeaponTypes + 1
    wb.Text = "Arma: " .. WeaponTypes[WeaponIndex]
end)
for _, name in ipairs({"Qualidade mínima", "Sem sombras", "Sem efeitos de luz",
    "Água simples", "Sem partículas", "Materiais simples"}) do
    addToggle(name, Features[name])
end
