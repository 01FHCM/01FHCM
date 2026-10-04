-- ==============================================
-- BLOX FRUITS FPS BOOST — VERSÃO CELULAR C/ BOTÃO
-- Ativa/Desativa • Não quebra PvP • Água visível
-- ==============================================

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Terrain = workspace.Terrain
local RunService = game:GetService("RunService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ⚙️ ESTADO DA OTIMIZAÇÃO
local OtimizacaoAtiva = false
local Conexoes = {}
local ConfigOriginal = {}

-- 📋 SALVAR configurações ORIGINAIS pra restaurar depois
local function SalvarConfigOriginal()
    ConfigOriginal = {
        Quality = settings().Rendering.QualityLevel,
        Shadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        WaterSize = Terrain.WaterWaveSize,
        WaterSpeed = Terrain.WaterWaveSpeed,
        WaterReflect = Terrain.WaterReflectance,
        WaterTransp = Terrain.WaterTransparency,
    }
end

-- ⚡ APLICAR otimização
local function AplicarOtimizacao()
    if OtimizacaoAtiva then return end
    OtimizacaoAtiva = true

    -- Qualidade
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level02
    end)

    -- Iluminação
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1500
    Lighting.Brightness = 2
    Lighting.EnvironmentSpecularScale = 0

    for _, v in ipairs(Lighting:GetChildren()) do
        pcall(function()
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") 
            or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect")
            or v:IsA("Atmosphere") then
                v.Enabled = false
            end
        end)
    end

    -- Água
    Terrain.WaterWaveSize = 0.1
    Terrain.WaterWaveSpeed = 2
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0.3

    -- Função de otimização
    local function OtimizarObj(obj)
        if obj:IsA("BasePart") then
            pcall(function()
                if not obj:IsDescendantOf(Players.LocalPlayer.Character) then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                    obj.RenderFidelity = Enum.RenderFidelity.Performance
                end
            end)
        elseif obj:IsA("ParticleEmitter") then
            pcall(function()
                if not obj:IsDescendantOf(Players.LocalPlayer.Character) then
                    obj.Rate = obj.Rate * 0.3
                    obj.Lifetime = NumberRange.new(
                        obj.Lifetime.Min * 0.4,
                        obj.Lifetime.Max * 0.4
                    )
                end
            end)
        elseif obj:IsA("Trail") or obj:IsA("Smoke") 
            or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function()
                if not obj:IsDescendantOf(Players.LocalPlayer.Character) then
                    obj.Enabled = false
                end
            end)
        elseif obj:IsA("Texture") or obj:IsA("Decal") then
            pcall(function()
                if not obj:IsDescendantOf(Players.LocalPlayer.Character)
                and not obj.Parent:IsA("PlayerGui") then
                    obj:Destroy()
                end
            end)
        end
    end

    -- Limpar conexões antigas
    for _, conn in pairs(Conexoes) do conn:Disconnect() end
    Conexoes = {}

    -- Aplicar em tudo existente
    task.spawn(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            task.delay(0.001, function() OtimizarObj(obj) end)
        end
    end)

    -- Escutar objetos novos
    table.insert(Conexoes, workspace.DescendantAdded:Connect(function(obj)
        task.delay(0.003, function() OtimizarObj(obj) end)
    end))

    -- Coletar lixo
    table.insert(Conexoes, task.spawn(function()
        while OtimizacaoAtiva do
            task.wait(120)
            collectgarbage("collect")
        end
    end))

    Botao.Text = "✅ FPS ON"
    Botao.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
end

-- 🔄 DESLIGAR — voltar ao normal
local function DesativarOtimizacao()
    if not OtimizacaoAtiva then return end
    OtimizacaoAtiva = false

    -- Desconectar tudo
    for _, conn in pairs(Conexoes) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    Conexoes = {}

    -- Restaurar configurações originais
    pcall(function()
        settings().Rendering.QualityLevel = ConfigOriginal.Quality
    end)
    Lighting.GlobalShadows = ConfigOriginal.Shadows
    Lighting.FogEnd = ConfigOriginal.FogEnd
    Lighting.Brightness = ConfigOriginal.Brightness
    Lighting.EnvironmentSpecularScale = 1

    Terrain.WaterWaveSize = ConfigOriginal.WaterSize
    Terrain.WaterWaveSpeed = ConfigOriginal.WaterSpeed
    Terrain.WaterReflectance = ConfigOriginal.WaterReflect
    Terrain.WaterTransparency = ConfigOriginal.WaterTransp

    -- Reativar efeitos de iluminação
    for _, v in ipairs(Lighting:GetChildren()) do
        pcall(function()
            if v:IsA("PostEffect") or v:IsA("Atmosphere") then
                v.Enabled = true
            end
        end)
    end

    collectgarbage("collect")
    Botao.Text = "⚡ FPS OFF"
    Botao.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
end

-- 📱 CRIAR BOTÃO NA TELA (adaptado pra celular)
local Tela = Instance.new("ScreenGui")
Tela.Name = "FPSBoostBlox"
Tela.Parent = PlayerGui
Tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Botao = Instance.new("TextButton")
Botao.Name = "BotaoFPS"
Botao.Size = UDim2.new(0, 140, 0, 55) -- Tamanho bom pra dedo
Botao.Position = UDim2.new(0.02, 0, 0.5, 0) -- Lado esquerdo, meio da tela
Botao.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
Botao.Text = "⚡ FPS OFF"
Botao.TextColor3 = Color3.fromRGB(255, 255, 255)
Botao.Font = Enum.Font.GothamBold
Botao.TextSize = 16
Botao.AutoLocalize = false
Botao.Parent = Tela

-- Cantos arredondados
local Canto = Instance.new("UICorner")
Canto.CornerRadius = UDim.new(0, 12)
Canto.Parent = Botao

-- Função do clique/toque
Botao.MouseButton1Click:Connect(function()
    if OtimizacaoAtiva then
        DesativarOtimizacao()
    else
        AplicarOtimizacao()
    end
end)

SalvarConfigOriginal()
print("✅ Botão FPS carregado! Toque para ligar/desligar")
