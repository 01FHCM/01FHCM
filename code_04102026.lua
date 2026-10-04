--==================================================
-- BLOX FRUITS PVP FPS BOOST
-- MOBILE
-- ON / OFF
-- RESTAURAÇÃO
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- VARIÁVEIS
--==================================================

local Ativo = false
local Estados = {}
local Conexoes = {}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "PvPFPSBoost"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

local Botao = Instance.new("TextButton")
Botao.Name = "FPSButton"
Botao.Size = UDim2.fromOffset(150, 55)
Botao.Position = UDim2.new(0, 15, 0.5, -25)
Botao.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Botao.TextColor3 = Color3.new(1, 1, 1)
Botao.Text = "FPS BOOST: OFF"
Botao.TextSize = 15
Botao.Font = Enum.Font.GothamBold
Botao.Active = true
Botao.AutoButtonColor = true
Botao.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Botao

--==================================================
-- SALVAR PROPRIEDADE
--==================================================

local function Salvar(obj, propriedade)

    if not obj or not obj.Parent then
        return
    end

    if not Estados[obj] then
        Estados[obj] = {}
    end

    if Estados[obj][propriedade] == nil then

        local sucesso, valor = pcall(function()
            return obj[propriedade]
        end)

        if sucesso then
            Estados[obj][propriedade] = valor
        end

    end
end

--==================================================
-- ALTERAR OBJETO
--==================================================

local function Otimizar(obj)

    if not Ativo then
        return
    end

    -- Nunca mexer no personagem
    if Player.Character
        and obj:IsDescendantOf(Player.Character) then
        return
    end

    -- PARTES
    if obj:IsA("BasePart") then

        Salvar(obj, "Material")
        Salvar(obj, "Reflectance")
        Salvar(obj, "CastShadow")

        pcall(function()
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        end)

    end

    -- MESH
    if obj:IsA("MeshPart") then

        Salvar(obj, "RenderFidelity")

        pcall(function()
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end)

    end

    -- PARTICULAS
    if obj:IsA("ParticleEmitter") then

        Salvar(obj, "Rate")

        pcall(function()
            obj.Rate = math.max(obj.Rate * 0.35, 1)
        end)

    end

    -- TRAIL
    if obj:IsA("Trail") then

        Salvar(obj, "Lifetime")

        pcall(function()
            obj.Lifetime = obj.Lifetime * 0.5
        end)

    end

    -- SMOKE
    if obj:IsA("Smoke") then

        Salvar(obj, "Opacity")

        pcall(function()
            obj.Opacity = obj.Opacity * 0.35
        end)

    end

    -- FIRE
    if obj:IsA("Fire") then

        Salvar(obj, "Size")

        pcall(function()
            obj.Size = obj.Size * 0.5
        end)

    end

    -- TEXTURE
    if obj:IsA("Texture") then

        Salvar(obj, "Transparency")

        pcall(function()
            obj.Transparency =
                math.min(obj.Transparency + 0.4, 1)
        end)

    end

    -- DECAL
    if obj:IsA("Decal") then

        Salvar(obj, "Transparency")

        pcall(function()
            obj.Transparency =
                math.min(obj.Transparency + 0.3, 1)
        end)

    end
end

--==================================================
-- RESTAURAR OBJETOS
--==================================================

local function Restaurar()

    for obj, propriedades in pairs(Estados) do

        if obj and obj.Parent then

            for propriedade, valor in pairs(propriedades) do

                pcall(function()
                    obj[propriedade] = valor
                end)

            end

        end

    end

    Estados = {}
end

--==================================================
-- SALVAR LIGHTING
--==================================================

local LightingOriginal = {}

local function SalvarLighting()

    LightingOriginal.GlobalShadows =
        Lighting.GlobalShadows

    LightingOriginal.FogEnd =
        Lighting.FogEnd

    LightingOriginal.Brightness =
        Lighting.Brightness

    LightingOriginal.EnvironmentSpecularScale =
        Lighting.EnvironmentSpecularScale

    LightingOriginal.WaterWaveSize =
        Terrain.WaterWaveSize

    LightingOriginal.WaterWaveSpeed =
        Terrain.WaterWaveSpeed

    LightingOriginal.WaterReflectance =
        Terrain.WaterReflectance

    LightingOriginal.WaterTransparency =
        Terrain.WaterTransparency

end

--==================================================
-- ATIVAR
--==================================================

local function Ativar()

    if Ativo then
        return
    end

    Ativo = true

    -- Limpar estados antigos
    Estados = {}

    SalvarLighting()

    -- GRÁFICOS
    pcall(function()
        settings().Rendering.QualityLevel =
            Enum.QualityLevel.Level02
    end)

    -- LIGHTING
    pcall(function()

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1500
        Lighting.EnvironmentSpecularScale = 0

    end)

    -- ÁGUA
    pcall(function()

        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0

    end)

    -- OBJETOS EXISTENTES
    task.spawn(function()

        local objetos = workspace:GetDescendants()

        for i, obj in ipairs(objetos) do

            if not Ativo then
                break
            end

            Otimizar(obj)

            -- Evita congelar o celular
            if i % 100 == 0 then
                task.wait()
            end

        end

    end)

    -- OBJETOS NOVOS
    table.insert(
        Conexoes,
        workspace.DescendantAdded:Connect(function(obj)

            if Ativo then
                task.defer(function()
                    if Ativo then
                        Otimizar(obj)
                    end
                end)
            end

        end)
    )

    -- BOTÃO
    Botao.Text = "FPS BOOST: ON"
    Botao.BackgroundColor3 =
        Color3.fromRGB(40, 180, 90)

end

--==================================================
-- DESATIVAR
--==================================================

local function Desativar()

    if not Ativo then
        return
    end

    Ativo = false

    -- Desconectar eventos
    for _, conexao in ipairs(Conexoes) do

        pcall(function()
            conexao:Disconnect()
        end)

    end

    Conexoes = {}

    -- RESTAURAR OBJETOS
    Restaurar()

    -- RESTAURAR QUALITY
    pcall(function()
        settings().Rendering.QualityLevel =
            Enum.QualityLevel.Automatic
    end)

    -- RESTAURAR LIGHTING
    pcall(function()

        Lighting.GlobalShadows =
            LightingOriginal.GlobalShadows

        Lighting.FogEnd =
            LightingOriginal.FogEnd

        Lighting.Brightness =
            LightingOriginal.Brightness

        Lighting.EnvironmentSpecularScale =
            LightingOriginal.EnvironmentSpecularScale

    end)

    -- RESTAURAR ÁGUA
    pcall(function()

        Terrain.WaterWaveSize =
            LightingOriginal.WaterWaveSize

        Terrain.WaterWaveSpeed =
            LightingOriginal.WaterWaveSpeed

        Terrain.WaterReflectance =
            LightingOriginal.WaterReflectance

        Terrain.WaterTransparency =
            LightingOriginal.WaterTransparency

    end)

    -- BOTÃO
    Botao.Text = "FPS BOOST: OFF"
    Botao.BackgroundColor3 =
        Color3.fromRGB(200, 50, 50)

end

--==================================================
-- BOTÃO MOBILE
--==================================================

Botao.Activated:Connect(function()

    if Ativo then
        Desativar()
    else
        Ativar()
    end

end)

print("PvP FPS Boost carregado.") = Color3.fromRGB(231, 76, 60)

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
