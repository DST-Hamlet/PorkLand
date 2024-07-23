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

local DAMAGE_CANT_TAGS = {"playerghost", "INLIMBO", "DECOR", "INLIMBO", "FX"}
local DAMAGE_ONEOF_TAGS = {"_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable", "HACK_workable", "SHEAR_workable"}
local LAUNCH_MUST_TAGS = {"_inventoryitem"}
local LAUNCH_CANT_TAGS = {"locomotor", "INLIMBO"}

local function is_valid_work_target(target)
    if not target.components.workable then
        return false
    end

    local valid_work_actions = {
        [ACTIONS.CHOP] = true,
        [ACTIONS.HAMMER] = true,
        [ACTIONS.MINE] = true,
        [ACTIONS.HACK] = true,
        [ACTIONS.DIG] = true,
    }

    local work_action = target.components.workable:GetWorkAction()
    --V2C: nil action for NPC_workable (e.g. campfires)
    return (not work_action and target:HasTag("NPC_workable")) or (target.components.workable:CanBeWorked() and valid_work_actions[work_action])
end

---@param params table configure launch speed, launch range, damage range etc
---@param targets_hit table|nil track entities hit with this table, not required
---@param targets_tossed table|nil track items tossed with this table, not required
function DoCircularAOEDamageAndDestroy(inst, params, targets_hit, targets_tossed)
    local damage_radius = params.damage_radius
    local launch_radius = params.launch_range or damage_radius
    local LAUNCH_SPEED = params.launch_speed or 0.2
    local SHOULD_LAUNCH = params.should_launch or false
    local ONATTACKEDFN = params.onattackedfn or function(...) end
    local ONLAUNCHEDFN = SHOULD_LAUNCH and params.onlaunchedfn or function(...) end
    local ONWORKEDFN = params.onworkedfn or function(...) end
    local VALIDFN = params.validfn or function(...) return true end

    targets_hit = targets_hit or {}
    targets_tossed = targets_tossed or {}
    local pugalisk_parts = {}

    local areahit_was_disabled = inst.components.combat.areahitdisabled
    inst.components.combat:EnableAreaDamage(false)
    inst.components.combat.ignorehitrange = true

    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, damage_radius + 3, nil, DAMAGE_CANT_TAGS, DAMAGE_ONEOF_TAGS)) do
        if not targets_hit[v] and v:IsValid() and VALIDFN(inst, v) and not (v.components.health and v.components.health:IsDead()) then
            local actual_damage_range = damage_radius + v:GetPhysicsRadius(0.5)
            if v:GetDistanceSqToPoint(x, 0, z) < actual_damage_range * actual_damage_range then
                if is_valid_work_target(v) then
                    targets_hit[v] = true
                    v.components.workable:Destroy(inst)
                    ONWORKEDFN(inst, v)
                    if v:IsValid() and v:HasTag("stump") then
                        v:Remove()
                    end
                elseif v.components.pickable and v.components.pickable:CanBePicked() then
                    targets_hit[v] = true
                    local success, loots = v.components.pickable:Pick(inst)
                    if loots and SHOULD_LAUNCH then
                        for _, vv in ipairs(loots) do
                            targets_tossed[vv] = true
                            targets_hit[vv] = true
                            Launch(vv, inst, LAUNCH_SPEED)
                            ONLAUNCHEDFN(inst, v)
                        end
                    end
                elseif v:HasTag("pugalisk") then -- don't insta kill pugalisk
                    local body = v._body and v._body:value() or v
                    if not body.invulnerable then -- only attack when it's vulnerable
                        pugalisk_parts[v] = v
                    end
                    targets_hit[v] = true
                elseif inst.components.combat:CanTarget(v) then
                    targets_hit[v] = true
                    inst.components.combat:DoAttack(v)
                    if v:IsValid() then
                        ONATTACKEDFN(inst, v)
                    end
                end
            end
        end
    end

    local pugalisk = next(pugalisk_parts)
    if pugalisk then
        inst.components.combat:DoAttack(pugalisk)
        if pugalisk:IsValid() then
            ONATTACKEDFN(inst, pugalisk)
        end
    end

    inst.components.combat.areahitdisabled = areahit_was_disabled
    inst.components.combat.ignorehitrange = false

    if not SHOULD_LAUNCH then
        return
    end

    for _, v in ipairs(TheSim:FindEntities(x, 0, z, launch_radius + 3, LAUNCH_MUST_TAGS, LAUNCH_CANT_TAGS)) do
        if not targets_tossed[v] then
            local actual_launch_range = launch_radius + v:GetPhysicsRadius(.5)
            if v:GetDistanceSqToPoint(x, 0, z) < actual_launch_range * actual_launch_range then
                if v.components.mine then
                    targets_hit[v] = true
                    targets_tossed[v] = true
                    v.components.mine:Deactivate()
                end
                if not v.components.inventoryitem.nobounce and v.Physics and v.Physics:IsActive() then
                    targets_hit[v] = true
                    targets_tossed[v] = true
                    Launch(v, inst, LAUNCH_SPEED)
                    ONLAUNCHEDFN(inst, v)
                end
            end
        end
    end
end

--- DoCircularAOEDamage except only between 2 certain angles
function DoSectorAOEDamageAndDestroy(inst, params, targets_hit, targets_tossed)
    if not params.start_angle or not params.end_angle then
        return DoCircularAOEDamageAndDestroy(inst, params, targets_hit, targets_tossed)
    end

    local function is_in_sector(_inst, v)
        local start_angle = params.start_angle + 90
        local end_angle = params.end_angle + 90

        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x)/DEGREES

        local dodamage = true
        local dir = _inst:GetAngleToPoint(Vector3(v.Transform:GetWorldPosition()))

        local dif = angle - dir
        while dif > 450 do
            dif = dif - 360
        end
        while dif < 90 do
            dif = dif + 360
        end
        if dif < start_angle or dif > end_angle then
            dodamage = false
        end

        return dodamage
    end

    local _validfn = params.validfn
    if _validfn then
        params.validfn = function (_inst, v)
            return _validfn(_inst, v) and is_in_sector(_inst, v)
        end
    else
        params.validfn = is_in_sector
    end

    return DoCircularAOEDamageAndDestroy(inst, params, targets_hit, targets_tossed)
end
