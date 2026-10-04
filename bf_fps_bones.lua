-- FPS Booster + Auto Farm Bones (Blox Fruits) com menu de ligar/desligar
-- Auto Farm: Terceiro Mar (Haunted Castle), recomendado level 1975+

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
-- AUTO FARM BONES
----------------------------------------------------------------
local BoneMobs = {"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"}
local QuestName, QuestLevel = "HauntedQuest1", 1

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function isBoneMob(name)
    for _, n in ipairs(BoneMobs) do
        if name:find(n, 1, true) then return true end
    end
    return false
end

local function nearestMob()
    local root = getRoot()
    local folder = workspace:FindFirstChild("Enemies")
    if not root or not folder then return end
    local best, dist = nil, math.huge
    for _, m in ipairs(folder:GetChildren()) do
        local hum, hrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and isBoneMob(m.Name) then
            local d = (hrp.Position - root.Position).Magnitude
            if d < dist then best, dist = m, d end
        end
    end
    return best
end

local function equipMelee()
    local c = player.Character
    if not c then return end
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == "Melee" then
            t.Parent = c
            return
        end
    end
end

local function startQuest()
    pcall(function()
        local gui = player.PlayerGui:FindFirstChild("Main")
        local q = gui and gui:FindFirstChild("Quest")
        if q and q.Visible then return end
        RS.Remotes.CommF_:InvokeServer("StartQuest", QuestName, QuestLevel)
    end)
end

local function flyTo(cf)
    local root = getRoot()
    if not root then return end
    local dist = (root.Position - cf.Position).Magnitude
    local tw = TweenService:Create(root, TweenInfo.new(dist / 250, Enum.EasingStyle.Linear), {CFrame = cf})
    tw:Play()
    tw.Completed:Wait()
end

task.spawn(function()
    while true do
        task.wait(0.15)
        if State["Auto Farm Bones"] then
            pcall(function()
                local root, hum = getRoot()
                if not root or not hum or hum.Health <= 0 then return end
                startQuest()
                equipMelee()
                local mob = nearestMob()
                if mob then
                    local hrp = mob.HumanoidRootPart
                    root.CFrame = hrp.CFrame * CFrame.new(0, 8, 0) -- fica acima do mob
                    root.Velocity = Vector3.zero
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(900, 500))
                end
            end)
        end
    end
end)

-- Mantém o personagem sem cair/colidir enquanto farma
game:GetService("RunService").Stepped:Connect(function()
    if State["Auto Farm Bones"] and player.Character then
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

addToggle("Auto Farm Bones")
for _, name in ipairs({"Qualidade mínima", "Sem sombras", "Sem efeitos de luz",
    "Água simples", "Sem partículas", "Materiais simples"}) do
    addToggle(name, Features[name])
end
