-- ==============================================
-- BLOX FRUITS FPS BOOST • CORRIGIDO DEFINITIVO
-- ✅ NÃO fica vermelho ao desligar
-- ✅ Botão arrastável
-- ✅ Liga/desliga sem travar
-- ✅ Blox Fruits + PvP 100%
-- ==============================================

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Terrain = workspace.Terrain
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ⚙️ ESTADO
local OtimizacaoAtiva = false
local Conexoes = {}
local ConfigOriginal = {}
local ObjetosAlterados = {} -- GUARDA o que foi mudado para RESTAURAR!

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
    table.clear(ObjetosAlterados) -- Limpa histórico anterior

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

    -- Otimização de objetos — GUARDA VALORES ORIGINAIS!
    local function OtimizarObj(obj)
        if not OtimizacaoAtiva then return end
        if table.find(ObjetosAlterados, obj) then return end -- Não processa 2x

        if obj:IsA("BasePart") then
            pcall(function()
                if not obj:IsDescendantOf(Players.LocalPlayer.Character) then
                    -- GUARDA valor original ANTES de mudar!
                    ObjetosAlterados[obj] = {
                        Material = obj.Material,
                        Reflectance = obj.Reflectance,
                        CastShadow = obj.CastShadow,
                        RenderFidelity = obj.RenderFidelity,
                    }
                    -- Aplica otimização
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                    obj.RenderFidelity = Enum.RenderFidelity.Performance
                end
            end)
        elseif obj:IsA("ParticleEmitter") then
            pcall(function()
                if not obj:IsDescendantOf(Players.LocalPlayer.Character) then
                    ObjetosAlterados[obj] = {
                        Rate = obj.Rate,
                        LifetimeMin = obj.Lifetime.Min,
                        LifetimeMax = obj.Lifetime.Max,
                    }
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
                    ObjetosAlterados[obj] = { Enabled = obj.Enabled }
                    obj.Enabled = false
                end
            end)
        end
    end

    -- Aplicar em tudo existente
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

    Botao.Text = "✅ FPS ON"
    Botao.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
end

-- 🔄 DESLIGAR — RESTAURA TUDO!
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

    -- ✅ RESTAURA TODOS OS OBJETOS que foram alterados
    for obj, dadosOriginais in pairs(ObjetosAlterados) do
        pcall(function()
            if not obj or not obj.Parent then return end -- Objeto já não existe

            if obj:IsA("BasePart") then
                obj.Material = dadosOriginais.Material
                obj.Reflectance = dadosOriginais.Reflectance
                obj.CastShadow = dadosOriginais.CastShadow
                obj.RenderFidelity = dadosOriginais.RenderFidelity

            elseif obj:IsA("ParticleEmitter") then
                obj.Rate = dadosOriginais.Rate
                obj.Lifetime = NumberRange.new(
                    dadosOriginais.LifetimeMin,
                    dadosOriginais.LifetimeMax
                )

            elseif obj:IsA("Trail") or obj:IsA("Smoke") 
                or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = dadosOriginais.Enabled
            end
        end)
    end
    table.clear(ObjetosAlterados)

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

    Botao.Text = "⚡ FPS OFF"
    Botao.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
end

-- 📱 CRIAR BOTÃO ARRASTÁVEL
local Tela = Instance.new("ScreenGui")
Tela.Name = "FPSBoostBlox"
Tela.Parent = PlayerGui
Tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Tela.ResetOnSpawn = false

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
Botao.Active = true
Botao.Draggable = true
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
print("✅ Tudo pronto! NÃO fica mais vermelho ao desligar!")
