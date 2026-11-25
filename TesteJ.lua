--==================================================
-- MESHES NO TORSO - ADVANCED JIGGLE PHYSICS
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--==================================================
-- OPÇÕES GERAIS
--==================================================

local EnableCollison = false

--==================================================
-- IMPACTO CONTRA PAREDES
--==================================================

local WALL_SETTINGS = {
    ENABLED = true,
    RAY_DISTANCE = 2.5,
    MIN_SPEED = 12,
    IMPULSE = 1.2,
    VIBRATION = 0.8,
    COOLDOWN = 0.3
}

--==================================================
-- CONFIGURAÇÕES DA MESH
--==================================================

local MESH_ID = "rbxassetid://96671314316493"

local DEFAULT_SIZE_X = 1
local DEFAULT_SIZE_Y = 1
local DEFAULT_SIZE_Z = 1.1

local DEFAULT_DIST_X = 0.029
local DEFAULT_DIST_Y = 1.3
local DEFAULT_DIST_Z = -0.56

--==================================================
-- CONFIGURAÇÕES DE ROTAÇÃO
--==================================================

local DEFAULT_ROT_X = 0
local DEFAULT_ROT_Y = 0
local DEFAULT_ROT_Z = 0

local BASE_SIZE = 4

--==================================================
-- TAMANHO DA HITBOX
--==================================================

local HITBOX_SIZE = Vector3.new(1.75, 1.75, 1.75)

--==================================================
-- TEXTURAS
--==================================================

local TEXTURE_SETTINGS = {
    [1] = {
        Front = {TILE_U=30,TILE_V=20,OFFSET_U=11.5,OFFSET_V=2},
        Back = {TILE_U=30,TILE_V=20,OFFSET_U=7.5,OFFSET_V=2},
        Bottom = {TILE_U=30,TILE_V=40,OFFSET_U=11.5,OFFSET_V=9.5},
        Left = {TILE_U=30,TILE_V=20,OFFSET_U=15,OFFSET_V=2},
        Right = {TILE_U=30,TILE_V=20,OFFSET_U=7.6,OFFSET_V=2}
    },

    [2] = {
        Front = {TILE_U=30,TILE_V=20,OFFSET_U=15,OFFSET_V=2},
        Back = {TILE_U=30,TILE_V=20,OFFSET_U=18,OFFSET_V=2},
        Bottom = {TILE_U=30,TILE_V=40,OFFSET_U=15,OFFSET_V=9.5},
        Left = {TILE_U=30,TILE_V=20,OFFSET_U=19,OFFSET_V=2},
        Right = {TILE_U=30,TILE_V=20,OFFSET_U=15,OFFSET_V=2}
    }
}

--==================================================
-- JIGGLE PHYSICS
--==================================================

local JIGGLE_SETTINGS = {
    [1] = {
        INTENSITY = 2.8,
        STIFFNESS = 85,
        DAMPING = 7,
        RESPONSE = 1.15,
        LANDING = 1.2,
        PENDULUM = 1.1,
        VIBRATION = 0.65,
        SQUASH = 0.8
    },

    [2] = {
        INTENSITY = 3,
        STIFFNESS = 80,
        DAMPING = 6.5,
        RESPONSE = 1.2,
        LANDING = 1.3,
        PENDULUM = 1.15,
        VIBRATION = 0.7,
        SQUASH = 0.85
    }
}

local COLLISION_SETTINGS = {
    GAP = 0,
    RESPONSE_SPEED = 5,
    MAX_OFFSET = 0.05,
    SOFTNESS = 0.5
}

local SQUASH_SETTINGS = {
    STRENGTH = 0.12,
    RECOVERY_SPEED = 9,
    MAX_SQUASH = 0.12,
    MAX_STRETCH = 0.10,
    MOVEMENT_INFLUENCE = 0.009,
    LANDING_INFLUENCE = 0.045
}

local PENDULUM_SETTINGS = {
    STIFFNESS = 55,
    DAMPING = 7,
    INFLUENCE = 0.055,
    MAX_ANGLE = 15
}

local VIBRATION_SETTINGS = {
    STIFFNESS = 90,
    DAMPING = 8,
    IMPULSE = 1.5,
    MAX_ANGLE = 3,
    MOVEMENT_THRESHOLD = 10
}

local VERTICAL_SETTINGS = {
    MAX_MOVEMENT = 0.12,
    MAX_TARGET = 0.08,
    UP_STIFFNESS = 65,
    UP_DAMPING = 9,
    DOWN_STIFFNESS = 55,
    DOWN_DAMPING = 8,
    MAX_VELOCITY = 1.2
}

--==================================================
-- INÉRCIA DE POSIÇÃO
--==================================================

local POSITION_SETTINGS = {
    STIFFNESS = 42,
    DAMPING = 8,

    ACCELERATION_X = 0.0018,
    ACCELERATION_Z = 0.0015,

    VELOCITY_INFLUENCE = 0.012,

    MAX_X = 0.22,
    MAX_Z = 0.28,

    SIDE_DIFFERENCE = 0.12
}

local LANDING_SETTINGS = {
    ROTATION_IMPULSE = 7,
    VERTICAL_IMPULSE = 0.8,
    MIN_FALL_SPEED = 10,
    COOLDOWN = 0.2
}

local STOP_SETTINGS = {
    MIN_SPEED = 0.5,
    EXTRA_DAMPING = 2
}

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

local previousTorsoRelativeCFrame = nil
local previousFloorMaterial = Enum.Material.Air
local previousVerticalVelocity = 0
local lastLandingTime = 0

local previousLocalVelocity = Vector3.zero
local previousCollisionOffset = 0
local previousCollisionTilt = 0
local lastWallImpactTime = 0

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local updateSpheres

--==================================================
-- PERSONAGEM
--==================================================

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getTorso()
    local character = getCharacter()

    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("LowerTorso")
        or character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- COR DO TORSO
--==================================================

local function getTorsoColor(torso)
    if not torso then
        return Color3.new(1, 1, 1)
    end

    return torso.Color
end

--==================================================
-- TEXTURA DA ROUPA
--==================================================

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
-- ESCALA DA TEXTURA
--==================================================

local function getTextureScale(sx, sy, sphereIndex, faceName)
    local settings = TEXTURE_SETTINGS[sphereIndex][faceName]

    local scaleU = sx / BASE_SIZE
    local scaleV = sy / BASE_SIZE

    return
        settings.TILE_U * scaleU,
        settings.TILE_V * scaleV,
        settings.OFFSET_U * scaleU,
        settings.OFFSET_V * scaleV
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
-- ATUALIZAR TEXTURAS E APARÊNCIA
--==================================================

updateSpheres = function()
    for i, sphereData in ipairs(spheres) do
        local part = sphereData.Part

        if not part or not part.Parent then
            continue
        end

        sphereData.Mesh.Scale = Vector3.new(sizeX, sizeY, sizeZ)

        local torso = getTorso()

        if torso then
            part.Color = getTorsoColor(torso)
            part.Material = torso.Material
        end

        for faceName, texture in pairs(sphereData.Textures) do
            local tileU, tileV, offsetU, offsetV =
                getTextureScale(sizeX, sizeY, i, faceName)

            texture.StudsPerTileU = math.max(0.1, tileU)
            texture.StudsPerTileV = math.max(0.1, tileV)

            texture.OffsetStudsU = offsetU
            texture.OffsetStudsV = offsetV
        end
    end
end

--==================================================
-- IMPACTO CONTRA PAREDES
--==================================================

local function detectWallImpact(root, localVelocity)
    if not WALL_SETTINGS.ENABLED then
        return
    end

    local worldVelocity = root.AssemblyLinearVelocity

    local horizontalVelocity = Vector3.new(
        worldVelocity.X,
        0,
        worldVelocity.Z
    )

    local speed = horizontalVelocity.Magnitude

    if speed < WALL_SETTINGS.MIN_SPEED then
        return
    end

    if os.clock() - lastWallImpactTime < WALL_SETTINGS.COOLDOWN then
        return
    end

    local direction = horizontalVelocity.Unit

    local character = player.Character
    local folder = workspace:FindFirstChild("LocalPlayer_TorsoSpheres")

    local exclusions = {}

    if character then
        table.insert(exclusions, character)
    end

    if folder then
        table.insert(exclusions, folder)
    end

    raycastParams.FilterDescendantsInstances = exclusions

    local result = workspace:Raycast(
        root.Position,
        direction * WALL_SETTINGS.RAY_DISTANCE,
        raycastParams
    )

    if not result then
        return
    end

    local impactSpeed = -worldVelocity:Dot(result.Normal)

    if impactSpeed < WALL_SETTINGS.MIN_SPEED then
        return
    end

    lastWallImpactTime = os.clock()

    local localNormal = root.CFrame:VectorToObjectSpace(
        result.Normal
    )

    local power = math.clamp(impactSpeed / 20, 0.5, 2)

    for i, sphereData in ipairs(spheres) do
        local jiggle = sphereData.Jiggle
        local settings = JIGGLE_SETTINGS[i]

        jiggle.Velocity += Vector3.new(
            localNormal.Z * WALL_SETTINGS.IMPULSE,
            localNormal.X * WALL_SETTINGS.IMPULSE,
            -localNormal.X * WALL_SETTINGS.IMPULSE
        ) * power * settings.LANDING

        jiggle.VibrationVelocity += Vector3.new(
            WALL_SETTINGS.VIBRATION * power,
            0,
            WALL_SETTINGS.VIBRATION * power * 0.5
        ) * settings.VIBRATION

        jiggle.SquashTarget = math.clamp(
            jiggle.SquashTarget + 0.04 * power,
            0,
            SQUASH_SETTINGS.MAX_SQUASH
        )
    end
end

--==================================================
-- IMPULSO DE ATERRISSAGEM
--==================================================

local function detectLanding(humanoid, root)
    local currentFloor = humanoid.FloorMaterial

    local wasAirborne = previousFloorMaterial == Enum.Material.Air
    local isGrounded = currentFloor ~= Enum.Material.Air

    local fallingSpeed = -previousVerticalVelocity

    if wasAirborne
        and isGrounded
        and fallingSpeed >= LANDING_SETTINGS.MIN_FALL_SPEED
        and os.clock() - lastLandingTime >= LANDING_SETTINGS.COOLDOWN then

        lastLandingTime = os.clock()

        for i, sphereData in ipairs(spheres) do
            local jiggle = sphereData.Jiggle
            local settings = JIGGLE_SETTINGS[i]

            local power = math.clamp(fallingSpeed / 20, 0.5, 2)

            jiggle.Velocity += Vector3.new(
                LANDING_SETTINGS.ROTATION_IMPULSE
                    * power
                    * settings.LANDING,
                0,
                0
            )

            jiggle.VerticalVelocity +=
                LANDING_SETTINGS.VERTICAL_IMPULSE
                * settings.LANDING

            jiggle.VibrationVelocity += Vector3.new(
                VIBRATION_SETTINGS.IMPULSE * power,
                0,
                0
            ) * settings.VIBRATION

            jiggle.SquashTarget = math.clamp(
                jiggle.SquashTarget
                    + SQUASH_SETTINGS.LANDING_INFLUENCE * power,
                0,
                SQUASH_SETTINGS.MAX_SQUASH
            )
        end
    end

    previousFloorMaterial = currentFloor
    previousVerticalVelocity = root.AssemblyLinearVelocity.Y
end

--==================================================
-- COLISÃO ENTRE HITBOXES
--==================================================

local function updateCollision(deltaTime)
    if not EnableCollison then
        previousCollisionOffset = 0
        previousCollisionTilt = 0
        return 0
    end

    if #spheres < 2 then
        return 0
    end

    local leftHitbox = spheres[1].Hitbox
    local rightHitbox = spheres[2].Hitbox

    if not leftHitbox or not rightHitbox then
        return 0
    end

    local distance = (
        rightHitbox.Position - leftHitbox.Position
    ).Magnitude

    local leftRadius = leftHitbox.Size.X / 2
    local rightRadius = rightHitbox.Size.X / 2

    local overlap = leftRadius + rightRadius - distance

    local targetOffset = 0
    local targetTilt = 0

    if overlap > COLLISION_SETTINGS.GAP then
        targetOffset = math.min(
            overlap * COLLISION_SETTINGS.SOFTNESS,
            COLLISION_SETTINGS.MAX_OFFSET
        )

        targetTilt = math.min(overlap * 10, 8)
    end

    local alpha = math.clamp(
        deltaTime * COLLISION_SETTINGS.RESPONSE_SPEED,
        0,
        1
    )

    previousCollisionOffset +=
        (targetOffset - previousCollisionOffset) * alpha

    previousCollisionTilt +=
        (targetTilt - previousCollisionTilt) * alpha

    return previousCollisionOffset
end

--==================================================
-- SISTEMA PRINCIPAL DE JIGGLE
--==================================================

local function updateJiggle(deltaTime)
    local character = player.Character

    if not character then
        previousTorsoRelativeCFrame = nil
        previousFloorMaterial = Enum.Material.Air
        return
    end

    local torso = getTorso()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not torso or not humanoid or not root then
        return
    end

    if #spheres < 2 then
        return
    end

    local localVelocity = root.CFrame:VectorToObjectSpace(
        root.AssemblyLinearVelocity
    )

    --==================================================
    -- MOVIMENTO DAS ANIMAÇÕES
    --==================================================

    local torsoRelativeCFrame =
        root.CFrame:ToObjectSpace(torso.CFrame)

    local animationAngularVelocity = Vector3.zero

    if previousTorsoRelativeCFrame and deltaTime > 0 then
        local difference =
            previousTorsoRelativeCFrame:ToObjectSpace(
                torsoRelativeCFrame
            )

        local axis, angle = difference:ToAxisAngle()

        animationAngularVelocity = axis * (angle / deltaTime)
    end

    previousTorsoRelativeCFrame = torsoRelativeCFrame

    local localAngularVelocity =
        root.CFrame:VectorToObjectSpace(
            root.AssemblyAngularVelocity
        ) + animationAngularVelocity * 1.5

    --==================================================
    -- ATERRISSAGEM
    --==================================================

    detectLanding(humanoid, root)

    --==================================================
    -- ACELERAÇÃO DO PERSONAGEM
    --==================================================

    local acceleration = Vector3.zero

    if deltaTime > 0 then
        acceleration = (localVelocity - previousLocalVelocity)
            / deltaTime
    end

    previousLocalVelocity = localVelocity

    --==================================================
    -- IMPACTO CONTRA PAREDES
    --==================================================

    detectWallImpact(root, localVelocity)

    --==================================================
    -- GIRO DO PERSONAGEM
    --==================================================

    local turnTarget = math.clamp(
        -localAngularVelocity.Y * 3,
        -15,
        15
    )

    --==================================================
    -- COLISÃO OPCIONAL
    --==================================================

    local collisionOffset = updateCollision(deltaTime)

    --==================================================
    -- FÍSICA INDIVIDUAL
    --==================================================

    for i, sphereData in ipairs(spheres) do
        local part = sphereData.Part
        local weld = sphereData.Weld

        if not part or not part.Parent then
            continue
        end

        local settings = JIGGLE_SETTINGS[i]
        local jiggle = sphereData.Jiggle

        local intensity = settings.INTENSITY
        local response = settings.RESPONSE

        --==================================================
        -- MOLA LATERAL
        --==================================================

        local turnStiffness = 30
        local turnDamping = 5

        local turnAcceleration =
            (turnTarget - jiggle.TurnCurrent) * turnStiffness
            - jiggle.TurnVelocity * turnDamping

        jiggle.TurnVelocity += turnAcceleration * deltaTime
        jiggle.TurnCurrent += jiggle.TurnVelocity * deltaTime

        jiggle.TurnCurrent = math.clamp(
            jiggle.TurnCurrent,
            -10,
            10
        )

        --==================================================
        -- MOLA VERTICAL
        --==================================================

        local verticalTarget = math.clamp(
            -localVelocity.Y * 0.025,
            -VERTICAL_SETTINGS.MAX_TARGET,
            VERTICAL_SETTINGS.MAX_TARGET
        )

        local movingUp =
            verticalTarget > jiggle.VerticalCurrent

        local verticalStiffness = movingUp
            and VERTICAL_SETTINGS.UP_STIFFNESS
            or VERTICAL_SETTINGS.DOWN_STIFFNESS

        local verticalDamping = movingUp
            and VERTICAL_SETTINGS.UP_DAMPING
            or VERTICAL_SETTINGS.DOWN_DAMPING

        local verticalAcceleration =
            (verticalTarget - jiggle.VerticalCurrent)
            * verticalStiffness
            - jiggle.VerticalVelocity * verticalDamping

        jiggle.VerticalVelocity += verticalAcceleration * deltaTime

        jiggle.VerticalVelocity = math.clamp(
            jiggle.VerticalVelocity,
            -VERTICAL_SETTINGS.MAX_VELOCITY,
            VERTICAL_SETTINGS.MAX_VELOCITY
        )

        jiggle.VerticalCurrent += jiggle.VerticalVelocity * deltaTime

        jiggle.VerticalCurrent = math.clamp(
            jiggle.VerticalCurrent,
            -VERTICAL_SETTINGS.MAX_MOVEMENT,
            VERTICAL_SETTINGS.MAX_MOVEMENT
        )

        --==================================================
        -- INÉRCIA DE POSIÇÃO
        --==================================================

        local sideMultiplier = i == 1
            and 1
            or (1 - POSITION_SETTINGS.SIDE_DIFFERENCE)

        local positionTarget = Vector3.new(
            math.clamp(
                -acceleration.X * POSITION_SETTINGS.ACCELERATION_X
                    - localVelocity.X * POSITION_SETTINGS.VELOCITY_INFLUENCE,
                -POSITION_SETTINGS.MAX_X,
                POSITION_SETTINGS.MAX_X
            ),

            0,

            math.clamp(
                -acceleration.Z * POSITION_SETTINGS.ACCELERATION_Z
                    - localVelocity.Z * POSITION_SETTINGS.VELOCITY_INFLUENCE,
                -POSITION_SETTINGS.MAX_Z,
                POSITION_SETTINGS.MAX_Z
            )
        ) * sideMultiplier

        local positionAcceleration =
            (positionTarget - jiggle.PositionCurrent)
            * POSITION_SETTINGS.STIFFNESS
            - jiggle.PositionVelocity * POSITION_SETTINGS.DAMPING

        jiggle.PositionVelocity += positionAcceleration * deltaTime

        jiggle.PositionCurrent += jiggle.PositionVelocity * deltaTime

        jiggle.PositionCurrent = Vector3.new(
            math.clamp(
                jiggle.PositionCurrent.X,
                -POSITION_SETTINGS.MAX_X,
                POSITION_SETTINGS.MAX_X
            ),
            0,
            math.clamp(
                jiggle.PositionCurrent.Z,
                -POSITION_SETTINGS.MAX_Z,
                POSITION_SETTINGS.MAX_Z
            )
        )

        --==================================================
        -- MOVIMENTO PRINCIPAL
        --==================================================

        local target = Vector3.new(
            math.clamp(
                -localVelocity.Z * 0.45
                    - localAngularVelocity.Z * 1.5,
                -12,
                12
            ),

            math.clamp(
                localVelocity.X * 0.25
                    - localAngularVelocity.Y * 1.5,
                -8,
                8
            ),

            math.clamp(
                -localVelocity.X * 0.5
                    + localAngularVelocity.X * 1.5,
                -12,
                12
            )
        )

        target += Vector3.new(
            math.clamp(-localVelocity.Y * 0.25, -10, 10),
            0,
            0
        )

        target *= intensity * response

        --==================================================
        -- PÊNDULO
        --==================================================

        local pendulumTarget = Vector3.new(
            math.clamp(
                -acceleration.Z * PENDULUM_SETTINGS.INFLUENCE,
                -PENDULUM_SETTINGS.MAX_ANGLE,
                PENDULUM_SETTINGS.MAX_ANGLE
            ),

            math.clamp(
                acceleration.X * PENDULUM_SETTINGS.INFLUENCE,
                -PENDULUM_SETTINGS.MAX_ANGLE,
                PENDULUM_SETTINGS.MAX_ANGLE
            ),

            math.clamp(
                -acceleration.X * PENDULUM_SETTINGS.INFLUENCE,
                -PENDULUM_SETTINGS.MAX_ANGLE,
                PENDULUM_SETTINGS.MAX_ANGLE
            )
        ) * settings.PENDULUM

        local pendulumAcceleration =
            (pendulumTarget - jiggle.PendulumCurrent)
            * PENDULUM_SETTINGS.STIFFNESS
            - jiggle.PendulumVelocity * PENDULUM_SETTINGS.DAMPING

        jiggle.PendulumVelocity +=
            pendulumAcceleration * deltaTime

        jiggle.PendulumCurrent +=
            jiggle.PendulumVelocity * deltaTime

        --==================================================
        -- VIBRAÇÃO SECUNDÁRIA
        --==================================================

        if acceleration.Magnitude > VIBRATION_SETTINGS.MOVEMENT_THRESHOLD then
            local vibrationPower = math.clamp(
                acceleration.Magnitude / 50,
                0,
                1
            )

            jiggle.VibrationVelocity += Vector3.new(
                vibrationPower * VIBRATION_SETTINGS.IMPULSE,
                0,
                vibrationPower * VIBRATION_SETTINGS.IMPULSE * 0.5
            ) * settings.VIBRATION
        end

        local vibrationAcceleration =
            -jiggle.VibrationCurrent * VIBRATION_SETTINGS.STIFFNESS
            - jiggle.VibrationVelocity * VIBRATION_SETTINGS.DAMPING

        jiggle.VibrationVelocity +=
            vibrationAcceleration * deltaTime

        jiggle.VibrationCurrent +=
            jiggle.VibrationVelocity * deltaTime

        jiggle.VibrationCurrent = Vector3.new(
            math.clamp(jiggle.VibrationCurrent.X, -VIBRATION_SETTINGS.MAX_ANGLE, VIBRATION_SETTINGS.MAX_ANGLE),
            math.clamp(jiggle.VibrationCurrent.Y, -VIBRATION_SETTINGS.MAX_ANGLE, VIBRATION_SETTINGS.MAX_ANGLE),
            math.clamp(jiggle.VibrationCurrent.Z, -VIBRATION_SETTINGS.MAX_ANGLE, VIBRATION_SETTINGS.MAX_ANGLE)
        )

        --==================================================
        -- SQUASH & STRETCH
        --==================================================

        local movementSquash = math.clamp(
            math.abs(localVelocity.Y)
                * SQUASH_SETTINGS.MOVEMENT_INFLUENCE,
            0,
            SQUASH_SETTINGS.MAX_STRETCH
        )

        jiggle.SquashTarget = math.clamp(
            jiggle.SquashTarget - movementSquash * deltaTime,
            0,
            SQUASH_SETTINGS.MAX_SQUASH
        )

        local squashAlpha = 1 - math.exp(
            -SQUASH_SETTINGS.RECOVERY_SPEED * deltaTime
        )

        jiggle.SquashCurrent +=
            (jiggle.SquashTarget - jiggle.SquashCurrent)
            * squashAlpha

        jiggle.SquashTarget *= math.exp(-4 * deltaTime)

        local squash = jiggle.SquashCurrent * settings.SQUASH

        local stretch = math.clamp(
            squash * SQUASH_SETTINGS.STRENGTH
                + movementSquash,
            0,
            SQUASH_SETTINGS.MAX_STRETCH
        )

        local scaleX = sizeX * (1 + stretch)
        local scaleY = sizeY * (1 - squash)
        local scaleZ = sizeZ * (1 + stretch)

        sphereData.Mesh.Scale = Vector3.new(
            scaleX,
            scaleY,
            scaleZ
        )

        --==================================================
        -- ELASTICIDADE AO PARAR
        --==================================================

        local horizontalSpeed = Vector3.new(
            localVelocity.X,
            0,
            localVelocity.Z
        ).Magnitude

        local angularSpeed = localAngularVelocity.Magnitude

        local isStopping =
            horizontalSpeed < STOP_SETTINGS.MIN_SPEED
            and angularSpeed < STOP_SETTINGS.MIN_SPEED

        local extraDamping = isStopping
            and STOP_SETTINGS.EXTRA_DAMPING
            or 0

        --==================================================
        -- MOLA ROTACIONAL
        --==================================================

        local finalTarget =
            target
            + jiggle.PendulumCurrent
            + jiggle.VibrationCurrent

        local stiffness = settings.STIFFNESS
        local damping = settings.DAMPING + extraDamping

        local rotationalAcceleration =
            (finalTarget - jiggle.Current) * stiffness
            - jiggle.Velocity * damping

        jiggle.Velocity +=
            rotationalAcceleration * deltaTime

        jiggle.Current += jiggle.Velocity * deltaTime

        jiggle.Current = Vector3.new(
            math.clamp(jiggle.Current.X, -5, 60),
            math.clamp(jiggle.Current.Y, -12, 12),
            math.clamp(jiggle.Current.Z, -15, 15)
        )

        --==================================================
        -- PIVÔ NO TOPO
        --==================================================

        local x = (i == 1) and distX or -distX

        if EnableCollison then
            x += (i == 1) and collisionOffset or -collisionOffset
        end

        local outwardTilt = previousCollisionTilt

        if i == 2 then
            outwardTilt = -outwardTilt
        end

        weld.C0 = getRelativeCFrame(x)
            * CFrame.new(
                jiggle.TurnCurrent * 0.05 + jiggle.PositionCurrent.X,
                -sizeY / 2 + jiggle.VerticalCurrent,
                jiggle.PositionCurrent.Z
            )
            * CFrame.Angles(
                math.rad(jiggle.Current.X),
                math.rad(jiggle.Current.Y),
                math.rad(jiggle.Current.Z)
            )
            * CFrame.Angles(
                0,
                0,
                math.rad(outwardTilt)
            )

        weld.C1 = CFrame.new(0, sizeY / 2, 0)

        --==================================================
        -- ATUALIZAR HITBOX NO CENTRO DA MESH
        --==================================================

        local hitboxWeld = sphereData.HitboxWeld

        if hitboxWeld and hitboxWeld.Parent then
            hitboxWeld.C0 = weld.C0
            hitboxWeld.C1 = weld.C1
        end
    end
end

--==================================================
-- CRIAR UMA MESH
--==================================================

local function createSphere(name, torso, x, folder, textureConfig, textureUrl)

    --==================================================
    -- PART VISUAL
    --==================================================

    local part = Instance.new("Part")

    part.Name = name
    part.Size = Vector3.new(1, 1, 1)
    part.Transparency = 0

    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false

    part.Massless = true
    part.Anchored = false

    part.Color = getTorsoColor(torso)
    part.Material = torso.Material

    part.Parent = folder

    --==================================================
    -- MESH PERSONALIZADA
    --==================================================

    local mesh = Instance.new("SpecialMesh")

    mesh.Name = "CustomMesh"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = MESH_ID

    mesh.Scale = Vector3.new(
        sizeX,
        sizeY,
        sizeZ
    )

    mesh.Offset = Vector3.zero
    mesh.Parent = part

    --==================================================
    -- TEXTURAS
    --==================================================

    local textures = {}

    if textureUrl and textureConfig then
        local faces = {
            Enum.NormalId.Front,
            Enum.NormalId.Back,
            Enum.NormalId.Bottom,
            Enum.NormalId.Left,
            Enum.NormalId.Right
        }

        for _, face in ipairs(faces) do
            local faceName = face.Name
            local config = textureConfig[faceName]

            if config then
                local texture = Instance.new("Texture")

                texture.Name = "ShirtTexture_" .. faceName
                texture.Face = face
                texture.Texture = textureUrl

                local tileU, tileV, offsetU, offsetV =
                    getTextureScale(sizeX, sizeY,
                        (textureConfig == TEXTURE_SETTINGS[1]) and 1 or 2,
                        faceName
                    )

                texture.StudsPerTileU = math.max(0.1, tileU)
                texture.StudsPerTileV = math.max(0.1, tileV)

                texture.OffsetStudsU = offsetU
                texture.OffsetStudsV = offsetV

                texture.Parent = part

                textures[faceName] = texture
            end
        end
    end

    --==================================================
    -- POSICIONAMENTO INICIAL
    --==================================================

    part.CFrame = torso.CFrame
        * getRelativeCFrame(x)
        * CFrame.new(0, -sizeY / 2, 0)

    --==================================================
    -- WELD VISUAL
    --==================================================

    local weld = Instance.new("Weld")

    weld.Name = "SphereWeld"
    weld.Part0 = torso
    weld.Part1 = part

    weld.C0 = getRelativeCFrame(x)
    weld.C1 = CFrame.new(0, sizeY / 2, 0)

    weld.Parent = part

    --==================================================
    -- HITBOX INDEPENDENTE
    --==================================================

    local hitbox = Instance.new("Part")

    hitbox.Name = name .. "_Hitbox"
    hitbox.Shape = Enum.PartType.Ball
    hitbox.Size = HITBOX_SIZE

    hitbox.Transparency = 1

    hitbox.CanCollide = false
    hitbox.CanTouch = false
    hitbox.CanQuery = true

    hitbox.Massless = true
    hitbox.Anchored = false

    hitbox.CFrame = part.CFrame
    hitbox.Parent = folder

    --==================================================
    -- WELD DA HITBOX
    --==================================================

    local hitboxWeld = Instance.new("Weld")

    hitboxWeld.Name = "HitboxWeld"
    hitboxWeld.Part0 = torso
    hitboxWeld.Part1 = hitbox

    hitboxWeld.C0 = weld.C0
    hitboxWeld.C1 = weld.C1

    hitboxWeld.Parent = hitbox

    --==================================================
    -- DADOS INDIVIDUAIS
    --==================================================

    return {
        Part = part,
        Mesh = mesh,
        Weld = weld,

        Hitbox = hitbox,
        HitboxWeld = hitboxWeld,

        Textures = textures,

        Jiggle = {
            Current = Vector3.zero,
            Velocity = Vector3.zero,

            TurnCurrent = 0,
            TurnVelocity = 0,

            VerticalCurrent = 0,
            VerticalVelocity = 0,

            PositionCurrent = Vector3.zero,
            PositionVelocity = Vector3.zero,

            PendulumCurrent = Vector3.zero,
            PendulumVelocity = Vector3.zero,

            VibrationCurrent = Vector3.zero,
            VibrationVelocity = Vector3.zero,

            SquashCurrent = 0,
            SquashTarget = 0
        }
    }
end

--==================================================
-- GERAR AS DUAS MESHES
--==================================================

local function generateSpheres()
    local torso = getTorso()

    if not torso then
        warn("Torso não encontrado!")
        return
    end

    local textureUrl = getTextureFromCharacter()

    local oldFolder = workspace:FindFirstChild(
        "LocalPlayer_TorsoSpheres"
    )

    if oldFolder then
        oldFolder:Destroy()
    end

    spheres = {}

    local folder = Instance.new("Folder")

    folder.Name = "LocalPlayer_TorsoSpheres"
    folder.Parent = workspace

    spheres[1] = createSphere(
        "Mesh_1",
        torso,
        distX,
        folder,
        TEXTURE_SETTINGS[1],
        textureUrl
    )

    spheres[2] = createSphere(
        "Mesh_2",
        torso,
        -distX,
        folder,
        TEXTURE_SETTINGS[2],
        textureUrl
    )

    updateSpheres()

    print("Duas meshes e hitboxes criadas com sucesso!")
end

--==================================================
-- INICIALIZAÇÃO
--==================================================

local function setupCharacter(character)
    previousTorsoRelativeCFrame = nil
    previousFloorMaterial = Enum.Material.Air
    previousVerticalVelocity = 0
    previousLocalVelocity = Vector3.zero

    previousCollisionOffset = 0
    previousCollisionTilt = 0

    lastLandingTime = 0
    lastWallImpactTime = 0

    spheres = {}

    local root = character:WaitForChild("HumanoidRootPart", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if not root or not humanoid then
        warn("Não foi possível inicializar: personagem incompleto.")
        return
    end

    task.wait(1)

    if player.Character ~= character then
        return
    end

    generateSpheres()
end

--==================================================
-- DETECTAR PERSONAGEM
--==================================================

player.CharacterAdded:Connect(function(character)
    task.spawn(setupCharacter, character)
end)

if player.Character then
    task.spawn(setupCharacter, player.Character)
end

--==================================================
-- INICIAR JIGGLE
--==================================================

RunService.Heartbeat:Connect(function(deltaTime)
    updateJiggle(math.min(deltaTime, 1 / 30))
end)
