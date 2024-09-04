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
local _FindWalkableOffset = FindWalkableOffset
FindWalkableOffset = function(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn, allow_water, allow_boats, can_walk_in_water, ...)
    if can_walk_in_water then
        return FindValidPositionByFan(start_angle, radius, attempts,
                function(offset)
                    local x = position.x + offset.x
                    local y = position.y + offset.y
                    local z = position.z + offset.z
                    return (TheWorld.Map:IsAboveGroundAtPoint(x, y, z, allow_water) or (allow_boats and TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil))
                        and (not check_los or
                            TheWorld.Pathfinder:IsClear(
                                position.x, position.y, position.z,
                                x, y, z,
                                { ignorewalls = ignore_walls ~= false, ignorecreep = true, allowocean = can_walk_in_water }))
                        and (customcheckfn == nil or customcheckfn(Vector3(x, y, z)))
                end)
    else
        return _FindWalkableOffset(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn, allow_water, allow_boats, can_walk_in_water, ...)
    end
end

function FindAmphibiousOffset(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn)
    return FindWalkableOffset(position, start_angle, radius, attempts, check_los, ignore_walls, customcheckfn, true, false, true)
end

function CanPVPTarget(inst, target)
    local canpvp = TheNet:GetPVPEnabled() and (inst ~= target) -- 即使关闭pvp, 仍然可以伤害到玩家自己
    if not canpvp and inst:HasTag("player") and target:HasTag("player") then
        return false
    end
    if not canpvp and inst.owner and inst.owner:HasTag("player") and target:HasTag("player") then
        return false
    end
    if not canpvp and inst.host and inst.host:HasTag("player") and target:HasTag("player") then
        return false
    end
    return true
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
    local USE_WORLD_PICKER = params.use_world_picker == true -- using inst as picker might have unintended effects
    local ONATTACKEDFN = params.onattackedfn or function(...) end
    local ONLAUNCHEDFN = SHOULD_LAUNCH and params.onlaunchedfn or function(...) end
    local ONWORKEDFN = params.onworkedfn or function(...) end
    local ONPICKEDFN = params.onpickedfn or function(...) end
    local VALIDFN = params.validfn or function(...) return true end

    targets_hit = targets_hit or {}
    targets_tossed = targets_tossed or {}
    local pugalisk_parts = {}

    local areahit_was_disabled = inst.components.combat.areahitdisabled
    inst.components.combat:EnableAreaDamage(false)
    inst.components.combat.ignorehitrange = true

    local x, _, z = inst.Transform:GetWorldPosition()
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
                    local _, loots = v.components.pickable:Pick(USE_WORLD_PICKER and TheWorld or inst)
                    if loots then
                        for _, vv in ipairs(loots) do
                            targets_hit[vv] = true
                            ONPICKEDFN(inst, vv)
                            if SHOULD_LAUNCH then
                                targets_tossed[vv] = true
                                Launch(vv, inst, LAUNCH_SPEED)
                                ONLAUNCHEDFN(inst, v)
                            end
                        end
                    end
                elseif v:HasTag("pugalisk") then -- don't insta kill pugalisk
                    local body = v._body and v._body:value() or v
                    if not body.invulnerable then -- only attack when it's vulnerable
                        pugalisk_parts[v] = v
                    end
                    targets_hit[v] = true
                elseif inst.components.combat:CanTarget(v) and CanPVPTarget(inst, v) then
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

-- Putting these here because both gas cloud and gas jundle turf uses those
local POISON_DAMAGE_INSECT = 60
local POISON_DAMAGE_NON_INSECT = 5
function StartTakingGasDamage(inst, cause)
    if not inst.components.poisonable then
        return
    end

    inst.components.poisonable.gassources[cause] = true

    if inst._poison_damage_task then
        return
    end

    if inst.player_classified then
        inst.player_classified.isingas:set(true)
        inst.isingas = true
    end

    local delaytime = 0
    if inst.no_gas_time then
        delaytime = math.max(inst.no_gas_time - GetTime(), 0)
    end

    local damage = inst:HasTag("insect") and POISON_DAMAGE_INSECT or POISON_DAMAGE_NON_INSECT
    inst._poison_damage_task = inst:DoPeriodicTask(1, function()
        if inst.components.inventory and inst.components.inventory:EquipHasTag("has_gasmask") then
            return
        end

        if inst:HasTag("playerghost") then
            if not inst.components.poisonable:IsPoisoned() then
                inst.components.poisonable:DonePoisoning()
            end
            return
        end

        if inst.components.poisonable and inst.components.poisonable.show_fx then
            if inst.components.poisonable.show_fx then
                inst.components.poisonable:SpawnFX()
            end
        end
        inst.components.health:DoDelta(-damage, nil, "gascloud")
        inst:PushEvent("poisondamage") -- screen flash
        inst:PushEvent("gasdamage")
    end, delaytime) -- 结尾的0代表第一次判定开始的延迟
end

function StopTakingGasDamage(inst, cause)
    if not inst.components.poisonable then
        return
    end

    inst.components.poisonable.gassources[cause] = nil

    local has_gassource = false
    for k, v in pairs(inst.components.poisonable.gassources) do
        has_gassource = true
    end
    if has_gassource then
        return
    end

    if inst._poison_damage_task then
        if inst._poison_damage_task:NextTime() then
            inst.no_gas_time = inst._poison_damage_task:NextTime()  --防止频繁进出毒气导致毒气掉血判定超过1秒一次
        end
        inst._poison_damage_task:Cancel()
        inst._poison_damage_task = nil

        if inst.player_classified then
            inst.player_classified.isingas:set(false)
            inst.isingas = false
        end
    end

    if not inst.components.poisonable:IsPoisoned() then
        inst.components.poisonable:DonePoisoning()
    end
end

local SpeciaTileDrop =
{
    [WORLD_TILES.PIGRUINS] = "cutstone",
    [WORLD_TILES.PIGRUINS_NOCANOPY] = "cutstone",
}

local _HandleDugGround = HandleDugGround
function HandleDugGround(dug_ground, x, y, z, ...)
    if SpeciaTileDrop[dug_ground] then
        local loot = SpawnPrefab(SpeciaTileDrop[dug_ground])
        if loot.components.inventoryitem ~= nil then
            loot.components.inventoryitem:InheritWorldWetnessAtXZ(x, z)
        end
        loot.Transform:SetPosition(x, y, z)
        if loot.Physics ~= nil then
            local angle = math.random() * TWOPI
            loot.Physics:SetVel(2 * math.cos(angle), 10, 2 * math.sin(angle))
        end
    else
        return _HandleDugGround(dug_ground, x, y, z, ...)
    end
end

function IsPlayerInAntDisguise(player)
    return (player.components.inventory and (player.components.inventory:EquipHasTag("antmask") and player.components.inventory:EquipHasTag("antsuit")))
        or (player.replica.inventory and (player.replica.inventory:EquipHasTag("antmask") and player.replica.inventory:EquipHasTag("antsuit")))
        or false
end
