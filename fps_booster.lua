--==================================================
-- ULTRA FPS BOOSTER - MOBILE
-- FPS DINÂMICO + BOTÃO MINIMALISTA + ARRASTÁVEL
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Ativo = false
local Salvos = {}

--==================================================
-- GUI
--==================================================

pcall(function()
    local antiga = PlayerGui:FindFirstChild("UltraFPS")

    if antiga then
        antiga:Destroy()
    end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name = "UltraFPS"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

--==================================================
-- BOTÃO
--==================================================

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

--==================================================
-- INDICADOR
--==================================================

local Indicador = Instance.new("Frame")

Indicador.Size = UDim2.new(0, 6, 0, 6)
Indicador.Position = UDim2.new(0, 10, 0.5, -3)

Indicador.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
Indicador.BorderSizePixel = 0
Indicador.Parent = Botao

local IndicadorCorner = Instance.new("UICorner")
IndicadorCorner.CornerRadius = UDim.new(1, 0)
IndicadorCorner.Parent = Indicador

--==================================================
-- CONTADOR FPS
--==================================================

local FPSLabel = Instance.new("TextLabel")

FPSLabel.Name = "FPSCounter"

FPSLabel.Size = UDim2.new(0, 85, 0, 22)
FPSLabel.Position = UDim2.new(0, 15, 0.5, 25)

-- FUNDO PRETO
FPSLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FPSLabel.BackgroundTransparency = 0.15

-- TEXTO FINO
FPSLabel.Text = "FPS: --"
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.TextSize = 13
FPSLabel.Font = Enum.Font.Gotham

FPSLabel.TextXAlignment = Enum.TextXAlignment.Center
FPSLabel.TextYAlignment = Enum.TextYAlignment.Center

FPSLabel.BorderSizePixel = 0
FPSLabel.Parent = Gui

local FPSCorner = Instance.new("UICorner")
FPSCorner.CornerRadius = UDim.new(0, 5)
FPSCorner.Parent = FPSLabel

--==================================================
-- SALVAR PROPRIEDADES
--==================================================

local function Salvar(obj, prop)

    if not obj then
        return
    end

    Salvos[obj] = Salvos[obj] or {}

    if Salvos[obj][prop] == nil then

        pcall(function()
            Salvos[obj][prop] = obj[prop]
        end)

    end
end

--==================================================
-- OTIMIZAR OBJETO
--==================================================

local function Otimizar(obj)

    if not Ativo then
        return
    end

    pcall(function()

        -- PARTES
        if obj:IsA("BasePart") then

            Salvar(obj, "Material")
            Salvar(obj, "Reflectance")
            Salvar(obj, "CastShadow")

            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
            obj.CastShadow = false

        -- PARTÍCULAS E EFEITOS
        elseif obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then

            Salvar(obj, "Enabled")

            obj.Enabled = false

        -- TEXTURAS
        elseif obj:IsA("Texture")
        or obj:IsA("Decal") then

            Salvar(obj, "Transparency")

            obj.Transparency = 1

        -- MESH
        elseif obj:IsA("SpecialMesh") then

            Salvar(obj, "TextureId")

            obj.TextureId = ""

        -- HIGHLIGHT
        elseif obj:IsA("Highlight") then

            Salvar(obj, "Enabled")

            obj.Enabled = false

        end

    end)
end

--==================================================
-- ATIVAR
--==================================================

local function Ativar()

    Ativo = true

    -- QUALIDADE MÍNIMA
    pcall(function()

        settings().Rendering.QualityLevel =
            Enum.QualityLevel.Level01

    end)

    -- ILUMINAÇÃO
    Salvar(Lighting, "GlobalShadows")
    Salvar(Lighting, "Brightness")
    Salvar(Lighting, "FogEnd")

    pcall(function()

        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.FogEnd = 1000000000

    end)

    -- PÓS-PROCESSAMENTO
    for _, obj in ipairs(Lighting:GetChildren()) do

        if obj:IsA("PostEffect")
        or obj:IsA("Atmosphere") then

            Salvar(obj, "Enabled")

            pcall(function()
                obj.Enabled = false
            end)

        end
    end

    -- ÁGUA
    Salvar(Terrain, "WaterWaveSize")
    Salvar(Terrain, "WaterWaveSpeed")
    Salvar(Terrain, "WaterReflectance")
    Salvar(Terrain, "WaterTransparency")

    pcall(function()

        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1

    end)

    -- MAPA
    for _, obj in ipairs(workspace:GetDescendants()) do
        Otimizar(obj)
    end

    Botao.Text = "FPS  ON"
    Indicador.BackgroundColor3 =
        Color3.fromRGB(60, 210, 90)

    print("ULTRA FPS: ON")

end

--==================================================
-- DESATIVAR
--==================================================

local function Desativar()

    Ativo = false

    for obj, propriedades in pairs(Salvos) do

        if obj and obj.Parent then

            for prop, valor in pairs(propriedades) do

                pcall(function()
                    obj[prop] = valor
                end)

            end

        end
    end

    Salvos = {}

    -- RESTAURAR QUALIDADE
    pcall(function()

        settings().Rendering.QualityLevel =
            Enum.QualityLevel.Automatic

    end)

    Botao.Text = "FPS  OFF"

    Indicador.BackgroundColor3 =
        Color3.fromRGB(220, 60, 60)

    print("ULTRA FPS: OFF")

end

--==================================================
-- ARRASTAR NO MOBILE
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

    if not pressionado then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta =
            input.Position - inicioToque

        if math.abs(delta.X) > 8
        or math.abs(delta.Y) > 8 then

            arrastando = true

            Botao.Position = UDim2.new(
                inicioPosicao.X.Scale,
                inicioPosicao.X.Offset + delta.X,
                inicioPosicao.Y.Scale,
                inicioPosicao.Y.Offset + delta.Y
            )

            -- CONTADOR ACOMPANHA O BOTÃO
            FPSLabel.Position = UDim2.new(
                inicioPosicao.X.Scale,
                inicioPosicao.X.Offset + delta.X,
                inicioPosicao.Y.Scale,
                inicioPosicao.Y.Offset + delta.Y + 41
            )

        end

    end

end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        if pressionado and not arrastando then

            if Ativo then
                Desativar()
            else
                Ativar()
            end

        end

        pressionado = false
        arrastando = false

    end

end)

--==================================================
-- NOVOS OBJETOS
--==================================================

workspace.DescendantAdded:Connect(function(obj)

    if Ativo then

        task.defer(function()

            if Ativo then
                Otimizar(obj)
            end

        end)

    end

end)

--==================================================
-- CONTADOR DE FPS
--==================================================

local frames = 0
local ultimoTempo = os.clock()

RunService.RenderStepped:Connect(function()

    frames += 1

    local agora = os.clock()

    if agora - ultimoTempo >= 1 then

        local fps = math.floor(
            frames / (agora - ultimoTempo)
        )

        FPSLabel.Text = "FPS: " .. fps

        --==================================================
        -- COR DINÂMICA
        --==================================================

        if fps >= 50 then

            -- VERDE SUAVE
            FPSLabel.TextColor3 =
                Color3.fromRGB(120, 255, 140)

        elseif fps >= 30 then

            -- AMARELO SUAVE
            FPSLabel.TextColor3 =
                Color3.fromRGB(255, 220, 100)

        else

            -- VERMELHO SUAVE
            FPSLabel.TextColor3 =
                Color3.fromRGB(255, 110, 110)

        end

        frames = 0
        ultimoTempo = agora

    end

end)

print("ULTRA FPS MOBILE CARREGADO")
