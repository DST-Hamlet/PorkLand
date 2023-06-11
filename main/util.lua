modimport("main/tileutil")
GLOBAL.setfenv(1, GLOBAL)

function GetWorldSetting(setting, default)
    local worldsettings = TheWorld and TheWorld.components.worldsettings
    if worldsettings then
        return worldsettings:GetSetting(setting)
    end
    return default
end

-- Store the globals for optimization
local IA_OCEAN_PREFABS = IA_OCEAN_PREFABS
local DST_OCEAN_PREFABS = DST_OCEAN_PREFABS

local WAVE_SPAWN_DISTANCE = 1.5
local _SpawnAttackWaves = SpawnAttackWaves
function SpawnAttackWaves(position, rotation, spawn_radius, numWaves, totalAngle, waveSpeed, wavePrefab, idleTime, instantActive, ...)
    if TheWorld.has_ia_ocean then
        wavePrefab = IA_OCEAN_PREFABS[wavePrefab] or wavePrefab
        wavePrefab = wavePrefab or "wave_rogue"
    else
        wavePrefab = DST_OCEAN_PREFABS[wavePrefab] or wavePrefab
        wavePrefab = wavePrefab or "wave_med"
    end

    if wavePrefab ~= "wave_ripple" and wavePrefab ~= "wave_rogue" then
        return _SpawnAttackWaves(position, rotation, spawn_radius, numWaves, totalAngle, waveSpeed, wavePrefab, idleTime, instantActive, ...)
    end


    waveSpeed = waveSpeed or 6
    idleTime = idleTime or 5
    totalAngle = (numWaves == 1 and 0) or
            (totalAngle and (totalAngle % 361)) or
            360

    local anglePerWave = (totalAngle == 0 and 0) or
            (totalAngle == 360 and totalAngle/numWaves) or
            totalAngle/(numWaves - 1)

    local startAngle = rotation or math.random(-180, 180)
    local total_rad = (spawn_radius or 0.0) + WAVE_SPAWN_DISTANCE

    local wave_spawned = false
    for i = 0, numWaves - 1 do
        local angle = (startAngle - (totalAngle/2)) + (i * anglePerWave)
        local offset_direction = Vector3(math.cos(angle*DEGREES), 0, -math.sin(angle*DEGREES)):Normalize()
        local wavepos = position + (offset_direction * total_rad)

        if not TheWorld.Map:IsPassableAtPoint(wavepos:Get()) then
            wave_spawned = true

            local wave = SpawnPrefab(wavePrefab)
            wave.Transform:SetPosition(wavepos:Get())
            wave.Transform:SetRotation(angle)
            if type(waveSpeed) == "table" then
                wave.Physics:SetMotorVel(waveSpeed[1], waveSpeed[2], waveSpeed[3])
            else
                wave.Physics:SetMotorVel(waveSpeed, 0, 0)
            end
            wave.idle_time = idleTime

            -- Ugh just because of the next two blocks I had to hopy and paste all this -_- -Half
            if instantActive then
                wave.sg:GoToState("idle")
            end

            if wave.soundtidal then
                wave.SoundEmitter:PlaySound(wave.soundtidal)
            end
        end
    end

    -- Let our caller know if we actually spawned at least 1 wave.
    return wave_spawned
end

function SpawnWaves(inst, numWaves, totalAngle, waveSpeed, wavePrefab, initialOffset, idleTime, instantActive, random_angle)
    return SpawnAttackWaves(inst:GetPosition(), (random_angle and math.random(-180, 180)) or inst.Transform:GetRotation(), initialOffset or (inst.Physics and inst.Physics:GetRadius()) or 0.0, numWaves, totalAngle, waveSpeed, wavePrefab or "wave_med",  idleTime or 5, instantActive)
end

function IsPositionValidForEnt(inst, radius_check)
    return function(pt)
        return inst:IsAmphibious()
            or (inst:IsAquatic() and not inst:GetIsCloseToLand(radius_check, pt))
            or (inst:IsTerrestrial() and not inst:GetIsCloseToWater(radius_check, pt))
    end
end

