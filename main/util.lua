modimport("main/tileutil")
GLOBAL.setfenv(1, GLOBAL)

function GetWorldSetting(setting, default)
    local worldsettings = TheWorld and TheWorld.components.worldsettings
    if worldsettings then
        return worldsettings:GetSetting(setting)
    end
    return default
end


function SpawnWaves(inst, numWaves, totalAngle, waveSpeed, wavePrefab, initialOffset, idleTime, instantActive, random_angle)
    return SpawnAttackWaves(inst:GetPosition(), (random_angle and math.random(-180, 180)) or inst.Transform:GetRotation(), initialOffset or (inst.Physics and inst.Physics:GetRadius()) or 0.0, numWaves, totalAngle, waveSpeed, wavePrefab or "wave_med",  idleTime or 5, instantActive)
end

