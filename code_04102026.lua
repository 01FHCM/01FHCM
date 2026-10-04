--==================================================
-- BLOX FRUITS FPS BOOST
-- MOBILE • ON/OFF • RESTAURAÇÃO COMPLETA
--==================================================

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Terrain = workspace.Terrain

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- ESTADO
--==================================================

local OtimizacaoAtiva = false
local Conexoes = {}
local EstadosOriginais = {}

local Botao

--==================================================
-- FUNÇÃO: SALVAR PROPRIEDADE
--==================================================

local function SalvarEstado(obj, propriedade, valor)
    if not EstadosOriginais[obj] then
        EstadosOriginais[obj] = {}
    end

    if EstadosOriginais[obj][propriedade] == nil then
        EstadosOriginais[obj][propriedade] = valor
    end
end

--==================================================
-- SALVAR LIGHTING / TERRAIN
--==================================================

local ConfigOriginal = {}

local function SalvarConfigOriginal()

    ConfigOriginal = {
        Quality = settings().Rendering.QualityLevel,

        Shadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        Specular = Lighting.EnvironmentSpecularScale,

        WaterSize = Terrain.WaterWaveSize,
        WaterSpeed = Terrain.WaterWaveSpeed,
        WaterReflect = Terrain.WaterReflectance,
        WaterTransp = Terrain.WaterTransparency
    }

    -- Salvar efeitos existentes
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
            SalvarEstado(obj, "Enabled", obj.Enabled)
        end
    end
end

--==================================================
-- OTIMIZAR OBJETO
--==================================================

local function OtimizarObj(obj)

    if not OtimizacaoAtiva then
        return
    end

    -- Não alterar o personagem
    local Character = LocalPlayer.Character

    if Character and obj:IsDescendantOf(Character) then
        return
    end

    -- BASEPART
    if obj:IsA("BasePart") then

        pcall(function()

            SalvarEstado(obj, "Material", obj.Material)
            SalvarEstado(obj, "Reflectance", obj.Reflectance)
            SalvarEstado(obj, "CastShadow", obj.CastShadow)
            SalvarEstado(obj, "RenderFidelity", obj.RenderFidelity)

            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            obj.RenderFidelity = Enum.RenderFidelity.Performance

        end)

    -- PARTICLE
    elseif obj:IsA("ParticleEmitter") then

        pcall(function()

            SalvarEstado(obj, "Rate", obj.Rate)
            SalvarEstado(obj, "Lifetime", obj.Lifetime)

            obj.Rate = obj.Rate * 0.3

            obj.Lifetime = NumberRange.new(
                obj.Lifetime.Min * 0.4,
                obj.Lifetime.Max * 0.4
            )

        end)

    -- TRAIL / SMOKE / FIRE / SPARKLES
    elseif obj:IsA("Trail")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then

        pcall(function()

            SalvarEstado(obj, "Enabled", obj.Enabled)

            obj.Enabled = false

        end)

    -- TEXTURE / DECAL
    elseif obj:IsA("Texture")
        or obj:IsA("Decal") then

        pcall(function()

            if obj.Parent and not obj.Parent:IsA("GuiObject") then

                SalvarEstado(obj, "Transparency", obj.Transparency)

                -- NÃO DESTRÓI.
                -- Apenas deixa invisível temporariamente.
                obj.Transparency = 1

            end

        end)

    -- EFEITOS DE LIGHTING
    elseif obj:IsA("PostEffect") or obj:IsA("Atmosphere") then

        pcall(function()

            SalvarEstado(obj, "Enabled", obj.Enabled)

            obj.Enabled = false

        end)
    end
end

--==================================================
-- APLICAR FPS BOOST
--==================================================

local function AplicarOtimizacao()

    if OtimizacaoAtiva then
        return
    end

    OtimizacaoAtiva = true

    -- Salvar configurações novamente
    EstadosOriginais = {}
    SalvarConfigOriginal()

    --==================================================
    -- QUALIDADE
    --==================================================

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level02
    end)

    --==================================================
    -- LIGHTING
    --==================================================

    pcall(function()

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1500
        Lighting.Brightness = 2
        Lighting.EnvironmentSpecularScale = 0

    end)

    --==================================================
    -- EFEITOS
    --==================================================

    for _, obj in ipairs(Lighting:GetChildren()) do
        OtimizarObj(obj)
    end

    --==================================================
    -- ÁGUA
    --==================================================

    pcall(function()

        Terrain.WaterWaveSize = 0.1
        Terrain.WaterWaveSpeed = 2
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0.3

    end)

    --==================================================
    -- OTIMIZAR WORKSPACE
    --==================================================

    task.spawn(function()

        for _, obj in ipairs(workspace:GetDescendants()) do

            if not OtimizacaoAtiva then
                break
            end

            OtimizarObj(obj)

            -- Evita travar o celular processando tudo de uma vez
            task.wait()

        end

    end)

    --==================================================
    -- OBJETOS NOVOS
    --==================================================

    table.insert(
        Conexoes,

        workspace.DescendantAdded:Connect(function(obj)

            if not OtimizacaoAtiva then
                return
            end

            task.delay(0.03, function()

                if OtimizacaoAtiva and obj.Parent then
                    OtimizarObj(obj)
                end

            end)

        end)
    )

    --==================================================
    -- NOVOS EFEITOS NO LIGHTING
    --==================================================

    table.insert(
        Conexoes,

        Lighting.ChildAdded:Connect(function(obj)

            if not OtimizacaoAtiva then
                return
            end

            task.delay(0.03, function()

                if OtimizacaoAtiva and obj.Parent then
                    OtimizarObj(obj)
                end

            end)

        end)
    )

    --==================================================
    -- BOTÃO
    --==================================================

    Botao.Text = "✅ FPS ON"
    Botao.BackgroundColor3 = Color3.fromRGB(46, 204, 113)

end

--==================================================
-- RESTAURAR OBJETOS
--==================================================

local function RestaurarObjetos()

    for obj, propriedades in pairs(EstadosOriginais) do

        if obj and obj.Parent then

            for propriedade, valorOriginal in pairs(propriedades) do

                pcall(function()
                    obj[propriedade] = valorOriginal
                end)

            end

        end

    end

end

--==================================================
-- DESATIVAR FPS BOOST
--==================================================

local function DesativarOtimizacao()

    if not OtimizacaoAtiva then
        return
    end

    -- Primeiro impede novas alterações
    OtimizacaoAtiva = false

    --==================================================
    -- DESCONECTAR
    --==================================================

    for i = #Conexoes, 1, -1 do

        local conexao = Conexoes[i]

        if typeof(conexao) == "RBXScriptConnection" then
            pcall(function()
                conexao:Disconnect()
            end)
        end

        Conexoes[i] = nil

    end

    --==================================================
    -- RESTAURAR QUALIDADE
    --==================================================

    pcall(function()
        settings().Rendering.QualityLevel =
            ConfigOriginal.Quality
    end)

    --==================================================
    -- RESTAURAR LIGHTING
    --==================================================

    pcall(function()

        Lighting.GlobalShadows =
            ConfigOriginal.Shadows

        Lighting.FogEnd =
            ConfigOriginal.FogEnd

        Lighting.Brightness =
            ConfigOriginal.Brightness

        Lighting.EnvironmentSpecularScale =
            ConfigOriginal.Specular

    end)

    --==================================================
    -- RESTAURAR ÁGUA
    --==================================================

    pcall(function()

        Terrain.WaterWaveSize =
            ConfigOriginal.WaterSize

        Terrain.WaterWaveSpeed =
            ConfigOriginal.WaterSpeed

        Terrain.WaterReflectance =
            ConfigOriginal.WaterReflect

        Terrain.WaterTransparency =
            ConfigOriginal.WaterTransp

    end)

    --==================================================
    -- RESTAURAR OBJETOS
    --==================================================

    RestaurarObjetos()

    --==================================================
    -- LIMPAR ESTADOS
    --==================================================

    EstadosOriginais = {}

    --==================================================
    -- BOTÃO
    --==================================================

    Botao.Text = "⚡ FPS OFF"
    Botao.BackgroundColor3 = Color3.fromRGB(231, 76, 60)

end

--==================================================
-- INTERFACE MOBILE
--==================================================

local Tela = Instance.new("ScreenGui")

Tela.Name = "FPSBoostBlox"
Tela.ResetOnSpawn = false
Tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Tela.Parent = PlayerGui

Botao = Instance.new("TextButton")

Botao.Name = "BotaoFPS"

Botao.Size = UDim2.new(0, 140, 0, 55)

Botao.Position =
    UDim2.new(0.02, 0, 0.5, 0)

Botao.BackgroundColor3 =
    Color3.fromRGB(231, 76, 60)

Botao.Text =
    "⚡ FPS OFF"

Botao.TextColor3 =
    Color3.fromRGB(255, 255, 255)

Botao.Font =
    Enum.Font.GothamBold

Botao.TextSize = 16

Botao.AutoLocalize = false

Botao.Active = true

Botao.Draggable = true

Botao.Parent = Tela

--==================================================
-- CANTO ARREDONDADO
--==================================================

local Canto = Instance.new("UICorner")

Canto.CornerRadius =
    UDim.new(0, 12)

Canto.Parent = Botao

--==================================================
-- TOQUE / CLIQUE
--==================================================

Botao.MouseButton1Click:Connect(function()

    if OtimizacaoAtiva then
        DesativarOtimizacao()
    else
        AplicarOtimizacao()
    end

end)

--==================================================
-- INICIAR
--==================================================

SalvarConfigOriginal()

print("FPS Booster carregado.")
print("ON = otimização")
print("OFF = restauração")
