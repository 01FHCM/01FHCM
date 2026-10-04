-- ==============================================
-- BLOX FRUITS FPS BOOST • CORRIGIDA + ARRASTÁVEL
-- ✅ Liga/desliga sem travar
-- ✅ Botão move com o dedo
-- ✅ Sem ficar vermelho/bloqueado
-- ==============================================

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Terrain = workspace.Terrain
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ⚙️ ESTADO
local OtimizacaoAtiva = false
local Conexoes = {}
local ConfigOriginal = {}

-- 📋 SALVAR configurações originais
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
        Specular = Lighting.EnvironmentSpecularScale,
    }
end

-- ⚡ APLICAR OTIMIZAÇÃO
local function AplicarOtimizacao()
    if OtimizacaoAtiva then return end
    OtimizacaoAtiva = true

    -- Limpar conexões antigas
    for i = #Conexoes, 1, -1 do
        Conexoes[i]:Disconnect()
        Conexoes[i] = nil
    end

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

    -- Água visível
    Terrain.WaterWaveSize = 0.1
    Terrain.WaterWaveSpeed = 2
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0.3

    -- Otimização de objetos
    local function OtimizarObj(obj)
        if not OtimizacaoAtiva then return end
        
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
                and not obj.Parent:IsA("GuiObject") then
                    obj:Destroy()
                end
            end)
        end
    end

    -- Aplicar em tudo
    task.spawn(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if OtimizacaoAtiva then
                task.delay(0.001, function() OtimizarObj(obj) end)
            end
        end
    end)

    -- Escutar objetos novos
    table.insert(Conexoes, workspace.DescendantAdded:Connect(function(obj)
        task.delay(0.003, function() OtimizarObj(obj) end)
    end))

    -- Limpeza de memória
    table.insert(Conexoes, task.spawn(function()
        while OtimizacaoAtiva do
            task.wait(120)
            collectgarbage("collect")
        end
    end))

    -- ✅ Botão verde = LIGADO
    Botao.Text = "✅ FPS ON"
    Botao.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
end

-- 🔄 DESLIGAR — VOLTA TUDO AO NORMAL
local function DesativarOtimizacao()
    if not OtimizacaoAtiva then return end
    OtimizacaoAtiva = false

    -- Desconectar TUDO
    for i = #Conexoes, 1, -1 do
        if typeof(Conexoes[i]) == "RBXScriptConnection" then
            Conexoes[i]:Disconnect()
        end
        Conexoes[i] = nil
    end

    -- Restaurar iluminação
    pcall(function()
        settings().Rendering.QualityLevel = ConfigOriginal.Quality
    end)
    Lighting.GlobalShadows = ConfigOriginal.Shadows
    Lighting.FogEnd = ConfigOriginal.FogEnd
    Lighting.Brightness = ConfigOriginal.Brightness
    Lighting.EnvironmentSpecularScale = ConfigOriginal.Specular

    -- Restaurar água
    Terrain.WaterWaveSize = ConfigOriginal.WaterSize
    Terrain.WaterWaveSpeed = ConfigOriginal.WaterSpeed
    Terrain.WaterReflectance = ConfigOriginal.WaterReflect
    Terrain.WaterTransparency = ConfigOriginal.WaterTransp

    -- Reativar efeitos
    for _, v in ipairs(Lighting:GetChildren()) do
        pcall(function()
            if v:IsA("PostEffect") or v:IsA("Atmosphere") then
                v.Enabled = true
            end
        end)
    end

    collectgarbage("collect")

    -- ✅ Botão vermelho = DESLIGADO (funciona de novo!)
    Botao.Text = "⚡ FPS OFF"
    Botao.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
end

-- 📱 CRIAR BOTÃO ARRASTÁVEL
local Tela = Instance.new("ScreenGui")
Tela.Name = "FPSBoostBlox"
Tela.Parent = PlayerGui
Tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Tela.ResetOnSpawn = false -- Não desaparece ao renascer!

Botao = Instance.new("TextButton")
Botao.Name = "BotaoFPS"
Botao.Size = UDim2.new(0, 140, 0, 55)
Botao.Position = UDim2.new(0.02, 0, 0.5, 0)
Botao.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
Botao.Text = "⚡ FPS OFF"
Botao.TextColor3 = Color3.fromRGB(255, 255, 255)
Botao.Font = Enum.Font.GothamBold
Botao.TextSize = 16
Botao.AutoLocalize = false
Botao.Active = true -- Permite arrastar!
Botao.Draggable = true -- ✅ ARRASTÁVEL com o dedo!
Botao.Parent = Tela

local Canto = Instance.new("UICorner")
Canto.CornerRadius = UDim.new(0, 12)
Canto.Parent = Botao

-- Alternar ao toque
Botao.MouseButton1Click:Connect(function()
    if OtimizacaoAtiva then
        DesativarOtimizacao()
    else
        AplicarOtimizacao()
    end
end)

SalvarConfigOriginal()
print("✅ Pronto! Botão arrastável + liga/desliga funcionando!")
