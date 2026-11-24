
--==================================================
-- ESFERAS NO TORSO - SEM UI
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--==================================================
-- CONFIGURAÇÕES DE TAMANHO
--==================================================

local DEFAULT_SIZE_X = 1.5
local DEFAULT_SIZE_Y = 2
local DEFAULT_SIZE_Z = 1.5

--==================================================
-- CONFIGURAÇÕES DE POSIÇÃO
--==================================================

local DEFAULT_DIST_X = 0.5
local DEFAULT_DIST_Y = 1.5
local DEFAULT_DIST_Z = 0.8

--==================================================
-- CONFIGURAÇÕES DE ROTAÇÃO
--==================================================

local DEFAULT_ROT_X = 45
local DEFAULT_ROT_Y = 0
local DEFAULT_ROT_Z = 0

--==================================================
-- CONFIGURAÇÕES INDIVIDUAIS DE TEXTURA
--==================================================


local TEXTURE_SETTINGS = {
    [1] = {
        Front = {
            TILE_U = 20,
            TILE_V = 20,
            OFFSET_U = 6.3,
            OFFSET_V = 2
        },

        Back = {
            TILE_U = 20,
            TILE_V = 20,
            OFFSET_U = 6.3,
            OFFSET_V = 2
        },

        Bottom = {
            TILE_U = 20,
            TILE_V = 20,
            OFFSET_U = 6.3,
            OFFSET_V = 6
        }
    },

    [2] = {
        Front = {
            TILE_U = 20,
            TILE_V = 20,
            OFFSET_U = 10,
            OFFSET_V = 2
        },

        Back = {
            TILE_U = 20,
            TILE_V = 20,
            OFFSET_U = 10,
            OFFSET_V = 2
        },

        Bottom = {
            TILE_U = 20,
            TILE_V = 20,
            OFFSET_U = 10,
            OFFSET_V = 6
        }
    }
}
--==================================================
-- JIGGLE PHYSICS
--==================================================

local JIGGLE_SETTINGS = {
    [1] = {
        INTENSITY = 3.5,
        STIFFNESS = 32,
        DAMPING = 5
    },

    [2] = {
        INTENSITY = 3.5,
        STIFFNESS = 32,
        DAMPING = 5
    }
}

local BASE_SIZE = 4

--==================================================
-- VALORES ATUAIS
--==================================================

local sizeX = DEFAULT_SIZE_X
local sizeY = DEFAULT_SIZE_Y
local sizeZ = DEFAULT_SIZE_Z

local distX = DEFAULT_DIST_X
local distY = DEFAULT_DIST_Y
local distZ = DEFAULT_DIST_Z

local rotX = DEFAULT_ROT_X
local rotY = DEFAULT_ROT_Y
local rotZ = DEFAULT_ROT_Z

local spheres = {}

--==================================================
-- PERSONAGEM
--==================================================

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getTorso()
    local character = getCharacter()

    local upperTorso = character:FindFirstChild("UpperTorso")
    if upperTorso then
        return upperTorso
    end

    local torso = character:FindFirstChild("Torso")
    if torso then
        return torso
    end

    return character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- ENCONTRAR TEXTURA DA ROUPA
--==================================================
local function getTorsoColor(torso)
    if not torso then
        return Color3.new(1, 1, 1)
    end

    return torso.Color
end
local function getTextureFromCharacter()
    local character = getCharacter()

    local shirtGraphic = character:FindFirstChildOfClass("ShirtGraphic")

    if shirtGraphic and shirtGraphic.Graphic ~= "" then
        return shirtGraphic.Graphic
    end

    local shirt = character:FindFirstChildOfClass("Shirt")

    if shirt and shirt.ShirtTemplate ~= "" then
        return shirt.ShirtTemplate
    end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("WrapLayer") and obj.ColorMap ~= "" then
            return obj.ColorMap
        end

        if obj:IsA("SurfaceAppearance") and obj.ColorMap ~= "" then
            return obj.ColorMap
        end

        if obj:IsA("MeshPart") and obj.TextureID ~= "" then
            return obj.TextureID
        end
    end

    return nil
end

--==================================================
-- ESCALA PROPORCIONAL DA TEXTURA
--==================================================

local function getTextureScale(sx, sy, sphereIndex, faceName)
    local settings = TEXTURE_SETTINGS[sphereIndex][faceName]

    local scaleU = sx / BASE_SIZE
    local scaleV = sy / BASE_SIZE

    local tileU = settings.TILE_U * scaleU
    local tileV = settings.TILE_V * scaleV

    local offsetU = settings.OFFSET_U * scaleU
    local offsetV = settings.OFFSET_V * scaleV

    return tileU, tileV, offsetU, offsetV
end

--==================================================
-- POSIÇÃO E ROTAÇÃO
--==================================================

local function getRelativeCFrame(x)
    return CFrame.new(x, distY, distZ)
        * CFrame.Angles(
            math.rad(rotX),
            math.rad(rotY),
            math.rad(rotZ)
        )
end

--==================================================
-- ATUALIZAR ESFERAS
--==================================================

local function updateSpheres()
    for i, sphereData in ipairs(spheres) do
        local part = sphereData.Part
        local mesh = sphereData.Mesh
        local weld = sphereData.Weld
        local jiggle = sphereData.Jiggle

        if part and part.Parent then
            mesh.Scale = Vector3.new(sizeX, sizeY, sizeZ)

            local x = (i == 1) and distX or -distX

            weld.C0 = getRelativeCFrame(x)
                * CFrame.new(
                    jiggle.TurnCurrent * 0.05,
                    -sizeY / 2 + jiggle.VerticalCurrent,
                    0
                )
                * CFrame.Angles(
                    math.rad(jiggle.Current.X),
                    math.rad(jiggle.Current.Y),
                    math.rad(jiggle.Current.Z)
                )

            weld.C1 = CFrame.new(0, sizeY / 2, 0)

            local torso = getTorso()

            if torso then
                part.Color = getTorsoColor(torso)
                part.Material = torso.Material
            end

            for _, faceName in ipairs({"Front", "Back", "Bottom"}) do
                local texture = sphereData.Textures[faceName]

                if texture then
                    local tileU, tileV, offsetU, offsetV =
                        getTextureScale(sizeX, sizeY, i, faceName)

                    texture.StudsPerTileU = math.max(0.1, tileU)
                    texture.StudsPerTileV = math.max(0.1, tileV)

                    texture.OffsetStudsU = offsetU
                    texture.OffsetStudsV = offsetV
                end
            end
        end
    end
end

--==================================================
-- SISTEMA DE JIGGLE PHYSICS
--==================================================

local function updateJiggle(deltaTime)
    local character = player.Character

    if not character then
        return
    end

    local torso = getTorso()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not torso or not humanoid or not root then
        return
    end

    local localVelocity =
        root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
        -- Detecta a velocidade de rotação do personagem
local localAngularVelocity =
    root.CFrame:VectorToObjectSpace(root.AssemblyAngularVelocity)
    -- Movimento lateral causado pelo giro
local turnTarget = math.clamp(
    -localAngularVelocity.Y * 1.5,
    -8,
    8
)

    for i, sphereData in ipairs(spheres) do
        local part = sphereData.Part
        local weld = sphereData.Weld

        if not part or not part.Parent then
            continue
        end

        local settings = JIGGLE_SETTINGS[i]
        local jiggle = sphereData.Jiggle

        local intensity = settings.INTENSITY
        -- Mola lateral do giro
local turnStiffness = 30
local turnDamping = 5

local turnAcceleration =
    (turnTarget - jiggle.TurnCurrent) * turnStiffness
    - jiggle.TurnVelocity * turnDamping

jiggle.TurnVelocity += turnAcceleration * deltaTime
jiggle.TurnCurrent += jiggle.TurnVelocity * deltaTime

jiggle.TurnCurrent = math.clamp(jiggle.TurnCurrent, -10, 10)
        -- Mola vertical
            local verticalTarget = math.clamp(
          -localVelocity.Y * 0.025,
             -0.5,
          0.5
            )

            local verticalStiffness = 45
            local verticalDamping = 4.5

            local verticalAcceleration =
             (verticalTarget - jiggle.VerticalCurrent) * verticalStiffness
             - jiggle.VerticalVelocity * verticalDamping

             jiggle.VerticalVelocity += verticalAcceleration * deltaTime
               jiggle.VerticalCurrent += jiggle.VerticalVelocity * deltaTime

                jiggle.VerticalCurrent = math.clamp(
                 jiggle.VerticalCurrent,
                 -0.6,
                       0.6
               )

        -- Movimento desejado da mola
local target = Vector3.new(
    math.clamp(
        -localVelocity.Z * 0.45 - localAngularVelocity.Z * 1.5,
        -12,
        12
    ),

    math.clamp(
        localVelocity.X * 0.25 - localAngularVelocity.Y * 1.5,
        -8,
        8
    ),

    math.clamp(
        -localVelocity.X * 0.5 + localAngularVelocity.X * 1.5,
        -12,
        12
    )
)

        -- Movimento vertical durante saltos e quedas
        target += Vector3.new(
            math.clamp(-localVelocity.Y * 0.25, -10, 10),
            0,
            0
        )

        target *= intensity

        -- Física da mola
        local stiffness = settings.STIFFNESS
        local damping = settings.DAMPING

        local acceleration =
            (target - jiggle.Current) * stiffness
            - jiggle.Velocity * damping

        jiggle.Velocity += acceleration * deltaTime
        jiggle.Current += jiggle.Velocity * deltaTime

        -- Limite de rotação
        jiggle.Current = Vector3.new(
            math.clamp(jiggle.Current.X, -15, 15),
            math.clamp(jiggle.Current.Y, -12, 12),
            math.clamp(jiggle.Current.Z, -15, 15)
        )

        -- Pivô no topo da esfera
        local x = (i == 1) and distX or -distX

        weld.C0 = getRelativeCFrame(x)
    * CFrame.new(
        jiggle.TurnCurrent * 0.05,
        -sizeY / 2 + jiggle.VerticalCurrent,
        0
    )
    * CFrame.Angles(
        math.rad(jiggle.Current.X),
        math.rad(jiggle.Current.Y),
        math.rad(jiggle.Current.Z)
    )

weld.C1 = CFrame.new(0, sizeY / 2, 0)
    end
end
--==================================================
-- CRIAR UMA ESFERA
--==================================================

local function createSphere(name, x, folder, torso, textureUrl, sphereIndex)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(1, 1, 1)
    part.Shape = Enum.PartType.Block
    part.Transparency = 0
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Anchored = false

    part.Color = getTorsoColor(torso)
    part.Material = torso.Material

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(sizeX, sizeY, sizeZ)
    mesh.Parent = part

    local textures = {}

    if textureUrl then
        local faces = {
            Enum.NormalId.Front,
            Enum.NormalId.Back,
            Enum.NormalId.Bottom
        }

        for _, face in ipairs(faces) do
            local faceName = face.Name

            local texture = Instance.new("Texture")
            texture.Name = "ShirtTexture_" .. faceName
            texture.Face = face
            texture.Texture = textureUrl

            local tileU, tileV, offsetU, offsetV =
                getTextureScale(sizeX, sizeY, sphereIndex, faceName)

            texture.StudsPerTileU = math.max(0.1, tileU)
            texture.StudsPerTileV = math.max(0.1, tileV)

            texture.OffsetStudsU = offsetU
            texture.OffsetStudsV = offsetV

            texture.Parent = part

            textures[faceName] = texture
        end
    end

    -- Posiciona o centro da esfera abaixo do ponto de articulação
    part.CFrame = torso.CFrame
        * getRelativeCFrame(x)
        * CFrame.new(0, -sizeY / 2, 0)

    part.Parent = folder

    local weld = Instance.new("Weld")
    weld.Name = "SphereWeld"
    weld.Part0 = torso
    weld.Part1 = part

    -- Ponto de articulação no torso
    weld.C0 = getRelativeCFrame(x)

    -- Topo da esfera
    weld.C1 = CFrame.new(0, sizeY / 2, 0)

    weld.Parent = part

    return {
        Part = part,
        Mesh = mesh,
        Weld = weld,
        Textures = textures,

        Jiggle = {
    Current = Vector3.zero,
    Velocity = Vector3.zero,

    TurnCurrent = 0,
    TurnVelocity = 0,

    VerticalCurrent = 0,
    VerticalVelocity = 0
}
         }
end

--==================================================
-- GERAR AS DUAS ESFERAS
--==================================================

local function generateSpheres()
    local torso = getTorso()

    if not torso then
        warn("Torso não encontrado!")
        return
    end

    local textureUrl = getTextureFromCharacter()

    if workspace:FindFirstChild("LocalPlayer_TorsoSpheres") then
        workspace.LocalPlayer_TorsoSpheres:Destroy()
    end

    spheres = {}

    local folder = Instance.new("Folder")
    folder.Name = "LocalPlayer_TorsoSpheres"
    folder.Parent = workspace

    -- ESFERA 1
    spheres[1] = createSphere(
        "Sphere_1",
        distX,
        folder,
        torso,
        textureUrl,
        1
    )

    -- ESFERA 2
    spheres[2] = createSphere(
        "Sphere_2",
        -distX,
        folder,
        torso,
        textureUrl,
        2
    )

    print("Duas esferas criadas com sucesso!")
end

--==================================================
-- INICIALIZAÇÃO
--==================================================

local function setupCharacter(character)
    character:WaitForChild("HumanoidRootPart")
    character:WaitForChild("Humanoid")

    task.wait(1)

    if player.Character ~= character then
        return
    end

    generateSpheres()
end

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
    task.spawn(setupCharacter, player.Character)
end

--==================================================
-- INICIAR JIGGLE
--==================================================

local jiggleConnection

jiggleConnection = RunService.Heartbeat:Connect(function(deltaTime)
    updateJiggle(math.min(deltaTime, 1 / 30))
end)
