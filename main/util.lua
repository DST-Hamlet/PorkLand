GLOBAL.setfenv(1, GLOBAL)

function GetWorldSetting(setting, default)
    local worldsettings = TheWorld and TheWorld.components.worldsettings
    if worldsettings then
        return worldsettings:GetSetting(setting)
    end
    return default
end

function SpawnWaves(inst, num_waves, total_angle, wave_speed, wave_prefab, initialOffset, idleTime, instantActive, random_angle)
    wave_prefab = wave_prefab or "wave_rogue"
    total_angle = math.clamp(total_angle, 1, 360)

    local pos = inst:GetPosition()
    local start_angle = (random_angle and math.random(-180, 180)) or inst.Transform:GetRotation()
    local angle_per_wave = total_angle/(num_waves - 1)

    if total_angle == 360 then
        angle_per_wave = total_angle/num_waves
    end

    for i = 0, num_waves - 1 do
        local wave = SpawnPrefab(wave_prefab)

        local angle = (start_angle - (total_angle/2)) + (i * angle_per_wave)
        local rad = initialOffset or (inst.Physics and inst.Physics:GetRadius()) or 0
        local total_rad = rad + wave.Physics:GetRadius() + 0.1
        local offset = Vector3(math.cos(angle * DEGREES), 0, -math.sin(angle * DEGREES)):Normalize()
        local wavepos = pos + (offset * total_rad)

        if TheWorld.Map:IsOceanTileAtPoint(wavepos.x, wavepos.y, wavepos.z) then
            wave.Transform:SetPosition(wavepos:Get())

            local speed = wave_speed or 6
            wave.Transform:SetRotation(angle)
            wave.Physics:SetMotorVel(speed, 0, 0)
            wave.idle_time = idleTime or 5

            if instantActive then
                wave.sg:GoToState("idle")
            end

            if wave.soundtidal then
                wave.SoundEmitter:PlaySound("dontstarve_DLC002/common/rogue_waves/"..wave.soundtidal)
            end
        else
            wave:Remove()
        end
    end
end

---FindWalkableOffset and allow_water but not allow_boats
---@param position Vector3
---@param start_angle number
---@param radius number
---@param attempts number
---@param check_los boolean
---@param ignore_walls boolean
---@param customcheckfn function
---@return Vector3
function FindAmphibiousOffset(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn)
    return FindWalkableOffset(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn, true, false)
end

--- Nudge instance to nearest 0.5 grid
--- example:
---     x = 2.8, z = 3.3 -> x = 3.0, z = 3.5
--- copied from prefabs/wall.lua
function NudgeToHalfGrid(inst)
    local function normalize(coord)
        local temp = coord % 0.5
        coord = coord + 0.5 - temp

        if coord % 1 == 0 then
            coord = coord - 0.5
        end

        return coord
    end

    local pt = Vector3(inst.Transform:GetWorldPosition())
    pt.x = normalize(pt.x)
    pt.z = normalize(pt.z)
    inst.Transform:SetPosition(pt.x, pt.y, pt.z)
end
