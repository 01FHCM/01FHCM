--==================================================
-- ULTRA FPS BOOSTER - MOBILE (MODO BATATA)
-- Remove texturas, sombras, luzes, partículas, céu,
-- roupas, água, névoa, pós-processamento e mais.
-- Botão arrastável: toque para ligar/desligar.
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Ativo = false
local Salvos = {}      -- [obj] = { prop = valorOriginal }
local Removidos = {}   -- [obj] = parentOriginal

--==================================================
-- GUI
--==================================================

pcall(function()
    local antiga = PlayerGui:FindFirstChild("UltraFPS")
    if antiga then antiga:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UltraFPS"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Botao = Instance.new("TextButton")
Botao.Name = "FPSButton"
Botao.Size = UDim2.new(0, 125, 0, 38)
Botao.Position = UDim2.new(0, 15, 0.5, -19)
Botao.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Botao.BackgroundTransparency = 0.15
Botao.TextColor3 = Color3.fromRGB(235, 235, 235)
Botao.Text = "FPS  OFF"
Botao.TextSize = 14
Botao.Font = Enum.Font.GothamMedium
Botao.BorderSizePixel = 0
Botao.AutoButtonColor = false
Botao.Active = true
Botao.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 9)
Corner.Parent = Botao

local Indicador = Instance.new("Frame")
Indicador.Size = UDim2.new(0, 6, 0, 6)
Indicador.Position = UDim2.new(0, 10, 0.5, -3)
Indicador.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
Indicador.BorderSizePixel = 0
Indicador.Parent = Botao

local IndicadorCorner = Instance.new("UICorner")
IndicadorCorner.CornerRadius = UDim.new(1, 0)
IndicadorCorner.Parent = Indicador

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Name = "FPSCounter"
FPSLabel.Size = UDim2.new(0, 85, 0, 22)
FPSLabel.Position = UDim2.new(0, 15, 0.5, 25)
FPSLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FPSLabel.BackgroundTransparency = 0.15
FPSLabel.Text = "FPS: --"
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.TextSize = 13
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.BorderSizePixel = 0
FPSLabel.Parent = Gui

local FPSCorner = Instance.new("UICorner")
FPSCorner.CornerRadius = UDim.new(0, 5)
FPSCorner.Parent = FPSLabel

--==================================================
-- SALVAR / REMOVER (para poder restaurar depois)
--==================================================

local function Salvar(obj, prop)
    if not obj then return end
    Salvos[obj] = Salvos[obj] or {}
    if Salvos[obj][prop] == nil then
        pcall(function()
            Salvos[obj][prop] = obj[prop]
        end)
    end
end

local function Definir(obj, prop, valor)
    Salvar(obj, prop)
    pcall(function()
        obj[prop] = valor
    end)
end

local function Remover(obj)
    if Removidos[obj] == nil and obj.Parent then
        Removidos[obj] = obj.Parent
        obj.Parent = nil
    end
end

--==================================================
-- OTIMIZAR UM OBJETO
--==================================================

local function Otimizar(obj)
    if not Ativo then return end

    pcall(function()

        if obj:IsA("BasePart") then
            Definir(obj, "Material", Enum.Material.SmoothPlastic)
            Definir(obj, "Reflectance", 0)
            Definir(obj, "CastShadow", false)

            if obj:IsA("MeshPart") then
                Definir(obj, "TextureID", "")
                Definir(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
            end

        elseif obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam")
            or obj:IsA("Smoke")
            or obj:IsA("Fire")
            or obj:IsA("Sparkles")
            or obj:IsA("Highlight")
            or obj:IsA("Light") then          -- PointLight, SpotLight, SurfaceLight
            Definir(obj, "Enabled", false)

        elseif obj:IsA("Decal") then          -- inclui Texture
            Definir(obj, "Transparency", 1)

        elseif obj:IsA("SpecialMesh") then
            Definir(obj, "TextureId", "")

        elseif obj:IsA("SurfaceAppearance")
            or obj:IsA("Shirt")
            or obj:IsA("Pants")
            or obj:IsA("ShirtGraphic")
            or obj:IsA("Sky") then
            Remover(obj)

        elseif obj:IsA("Explosion") or obj:IsA("ForceField") then
            Definir(obj, "Visible", false)

        elseif obj:IsA("Clouds") or obj:IsA("PostEffect") then
            Definir(obj, "Enabled", false)

        elseif obj:IsA("Atmosphere") then
            Definir(obj, "Density", 0)
            Definir(obj, "Haze", 0)
            Definir(obj, "Glare", 0)
        end

    end)
end

-- Processa em lotes para não travar o celular
local function ProcessarLote(raiz)
    local n = 0
    for _, obj in ipairs(raiz:GetDescendants()) do
        if not Ativo then return end
        Otimizar(obj)
        n += 1
        if n % 300 == 0 then
            task.wait()
        end
    end
end

--==================================================
-- ATIVAR
--==================================================

local function Ativar()
    Ativo = true

    -- Qualidade gráfica mínima
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end)

    -- Iluminação
    Definir(Lighting, "GlobalShadows", false)
    Definir(Lighting, "Brightness", 1)
    Definir(Lighting, "FogStart", 0)
    Definir(Lighting, "FogEnd", 1e9)
    Definir(Lighting, "ShadowSoftness", 0)
    Definir(Lighting, "EnvironmentDiffuseScale", 0)
    Definir(Lighting, "EnvironmentSpecularScale", 0)

    -- Terreno / água
    Definir(Terrain, "WaterWaveSize", 0)
    Definir(Terrain, "WaterWaveSpeed", 0)
    Definir(Terrain, "WaterReflectance", 0)
    Definir(Terrain, "WaterTransparency", 1)
    Definir(Terrain, "Decoration", false) -- grama

    Botao.Text = "FPS  ON"
    Indicador.BackgroundColor3 = Color3.fromRGB(60, 210, 90)

    task.spawn(function()
        ProcessarLote(Lighting)
        ProcessarLote(workspace)
    end)
end

--==================================================
-- DESATIVAR (restaura tudo)
--==================================================

local function Desativar()
    Ativo = false

    for obj, propriedades in pairs(Salvos) do
        for prop, valor in pairs(propriedades) do
            pcall(function()
                obj[prop] = valor
            end)
        end
    end
    Salvos = {}

    for obj, pai in pairs(Removidos) do
        pcall(function()
            obj.Parent = pai
        end)
    end
    Removidos = {}

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)

    Botao.Text = "FPS  OFF"
    Indicador.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end

--==================================================
-- ARRASTAR + TOCAR
--==================================================

local pressionado = false
local arrastando = false
local inicioToque
local inicioPosicao

Botao.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        pressionado = true
        arrastando = false
        inicioToque = input.Position
        inicioPosicao = Botao.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not pressionado then return end

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - inicioToque

        if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
            arrastando = true

            Botao.Position = UDim2.new(
                inicioPosicao.X.Scale, inicioPosicao.X.Offset + delta.X,
                inicioPosicao.Y.Scale, inicioPosicao.Y.Offset + delta.Y
            )
            FPSLabel.Position = UDim2.new(
                inicioPosicao.X.Scale, inicioPosicao.X.Offset + delta.X,
                inicioPosicao.Y.Scale, inicioPosicao.Y.Offset + delta.Y + 44
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if pressionado and not arrastando then
            if Ativo then Desativar() else Ativar() end
        end
        pressionado = false
        arrastando = false
    end
end)

--==================================================
-- NOVOS OBJETOS (também otimizados)
--==================================================

local function AoAdicionar(obj)
    if Ativo then
        task.defer(Otimizar, obj)
    end
end

workspace.DescendantAdded:Connect(AoAdicionar)
Lighting.DescendantAdded:Connect(AoAdicionar)

--==================================================
-- CONTADOR DE FPS
--==================================================

local frames = 0
local ultimoTempo = os.clock()

RunService.RenderStepped:Connect(function()
    frames += 1
    local agora = os.clock()

    if agora - ultimoTempo >= 1 then
        local fps = math.floor(frames / (agora - ultimoTempo))
        FPSLabel.Text = "FPS: " .. fps

        if fps >= 50 then
            FPSLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
        elseif fps >= 30 then
            FPSLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        else
            FPSLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
        end

        frames = 0
        ultimoTempo = agora
    end
end)
