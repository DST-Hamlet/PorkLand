local WorldWaveManager = Class(function(self, inst)
    self.inst = inst

    self.next_wave_id = 0

    self.waves = {}
end)

function WorldWaveManager:GenerateID()
    self.next_wave_id = self.next_wave_id + 1
    return self.next_wave_id
end

function WorldWaveManager:AddWave(prefab, id)
    if prefab == nil or not prefab:IsValid() then
        return
    end
    local id = id or self:GenerateID()
    prefab.id = id
    self.waves[id] = prefab
    return prefab
end

function WorldWaveManager:RemoveWave(id)
    if self.waves[id] then
        local wave = self.waves[id]
        self.waves[id] = nil
        if wave:IsValid() then
            wave:Remove()
        end
    end
end

function WorldWaveManager:SpawnServerWave(prefab, wavepos, angle, speed, idle_time, instantActive)
    local wave = SpawnPrefab(prefab)

    if not wave then
        return
    end

    self:AddWave(wave)
    
    wave.Transform:SetPosition(wavepos:Get())

    wave.Transform:SetRotation(angle)
    wave.Physics:SetMotorVel(speed, 0, 0)
    wave.idle_time = idle_time

    if instantActive then
        wave.sg:GoToState("idle")
    end

    if wave.soundtidal then
        wave.SoundEmitter:PlaySound("dontstarve_DLC002/common/rogue_waves/"..wave.soundtidal)
    end

    SendModRPCToClient(GetClientModRPC("PorkLand", "spawn_wave"), nil, prefab, wavepos.x, wavepos.y, wavepos.z, angle, speed, idle_time, instantActive, wave.id) -- 当数据量特别大时, RPC数据存在一定的滞后性, 并不会像其他游戏数据一样即时同步

    local function OnServerWaveRemove(wave)
        if self.waves[wave.id] then
            SendModRPCToClient(GetClientModRPC("PorkLand", "remove_wave"), nil, wave.id)
        end
        self:RemoveWave(wave.id)
    end
    
    self.inst:ListenForEvent("onremove", OnServerWaveRemove, wave)
end

function WorldWaveManager:SpawnClientWave(prefab, wavepos, angle, speed, idle_time, instantActive, id)
    if not ThePlayer or not ThePlayer:IsValid() then
        return
    end

    if ThePlayer:GetDistanceSqToPoint(wavepos) > 120 * 120 then
        return
    end

    local wave = SpawnPrefab(prefab)

    wave.Transform:SetPosition(wavepos:Get())

    wave.Transform:SetRotation(angle)
    wave.Physics:SetMotorVel(speed, 0, 0)
    wave.idle_time = idle_time

    wave.is_client = true

    if instantActive then
        wave.sg:GoToState("idle")
    end

    if wave.soundtidal then
        wave.SoundEmitter:PlaySound("dontstarve_DLC002/common/rogue_waves/"..wave.soundtidal)
    end

    self:AddWave(wave, id)
end

-- ThePlayer:DoPeriodicTask(0, function(inst) TheWorld.components.worldwavemanager:SpawnWaveCircle(inst, 6, 360, 2) end)
-- ThePlayer:DoPeriodicTask(0.5, function(inst) TheWorld.components.worldwavemanager:SpawnWaveCircle(inst, 2, 360, 1, "wave_ripple", nil, 1, nil, nil, inst.Transform:GetRotation() + 90) end)
function WorldWaveManager:SpawnWaveCircle(inst, num_waves, total_angle, wave_speed, wave_prefab, initialOffset, wave_idle_time, instantActive, random_angle, current_angle)
    wave_prefab = wave_prefab or "wave_rogue"
    total_angle = math.clamp(total_angle, 1, 360)

    local pos = inst:GetPosition()
    local start_angle = current_angle or (random_angle and math.random(-180, 180)) or inst.Transform:GetRotation()
    local angle_per_wave = total_angle/(num_waves - 1)

    if total_angle == 360 then
        angle_per_wave = total_angle/num_waves
    end
    
    for i = 0, num_waves - 1 do
        local angle = (start_angle - (total_angle/2)) + (i * angle_per_wave)
        local rad = initialOffset or (inst.Physics and inst.Physics:GetRadius()) or 0
        local total_rad = rad + 1 + 0.1 -- rad + wave.Physics:GetRadius() + 0.1
        local offset = Vector3(math.cos(angle * DEGREES), 0, -math.sin(angle * DEGREES)):Normalize()
        local wavepos = pos + (offset * total_rad)
        local speed = wave_speed or 6
        local idle_time = wave_idle_time or 5

        if TheWorld.Map:IsOceanTileAtPoint(wavepos.x, wavepos.y, wavepos.z) then
            self:SpawnServerWave(wave_prefab, wavepos, angle, wave_speed, idle_time, instantActive)
        end
    end
end

return WorldWaveManager
