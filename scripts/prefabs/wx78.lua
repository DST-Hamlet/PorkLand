local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/wx78.fsb"),
    Asset("ANIM", "anim/player_idles_wx.zip"),
}

local prefabs =
{
    "sparks",
    "cracklehitfx",
}

local start_inv =
{
    default =
    {
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WX78
end

prefabs = FlattenTree({prefabs, start_inv}, true)

--hunger, health, sanity
local function ApplyUpgrades(inst)
    local max_upgrades = 15
    inst.level = math.min(inst.level, max_upgrades)

    local hunger_percent = inst.components.hunger:GetPercent()
    local health_percent = inst.components.health:GetPercent()
    local sanity_percent = inst.components.sanity:GetPercent()

    inst.components.hunger:SetMax(TUNING.WX78_MIN_HUNGER + inst.level * (TUNING.WX78_MAX_HUNGER - TUNING.WX78_MIN_HUNGER) / max_upgrades)
    inst.components.health:SetBaseHealth(TUNING.WX78_MIN_HEALTH + inst.level * (TUNING.WX78_MAX_HEALTH - TUNING.WX78_MIN_HEALTH) / max_upgrades)
    inst.components.health:SetMaxHealth(inst.components.health.basehealth * (inst._shapescale or 1)) -- 考虑可能的体型机制
    inst.components.sanity:SetMax(TUNING.WX78_MIN_SANITY + inst.level * (TUNING.WX78_MAX_SANITY - TUNING.WX78_MIN_SANITY) / max_upgrades)

    inst.components.hunger:SetPercent(hunger_percent)
    inst.components.health:SetPercent(health_percent)

    local ignoresanity = inst.components.sanity.ignore
    inst.components.sanity.ignore = false
    inst.components.sanity:SetPercent(sanity_percent)
    inst.components.sanity.ignore = ignoresanity
end

local function OnEat(inst, food)
    if not food or not food.components.edible or food.components.edible.foodtype ~= FOODTYPE.GEARS then
        return
    end

    --give an upgrade!
    inst.level = inst.level + 1
    ApplyUpgrades(inst)
    inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
end

local SPEED_BONUS_NAME = "WX_CHARGE"

local function OnUpdate(inst, dt)
    inst.charge_time = inst.charge_time - dt
    if inst.charge_time <= 0 then
        inst.charge_time = 0
        if inst.charged_task ~= nil then
            inst.charged_task:Cancel()
            inst.charged_task = nil
        end
        inst.SoundEmitter:KillSound("overcharge_sound")
        inst:RemoveTag("overcharge")
        inst.Light:Enable(false)
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, SPEED_BONUS_NAME)
        inst.components.bloomer:PopBloom("overcharge")
        inst.components.temperature.mintemp = -20
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_DISCHARGE"))
    else
        local runspeed_bonus = 0.5
        local rad = 3
        if inst.charge_time < 60 then
            rad = math.max(0.1, rad * (inst.charge_time / 60))
            runspeed_bonus = (inst.charge_time / 60) * runspeed_bonus
        end

        inst.Light:Enable(true)
        inst.Light:SetRadius(rad)
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, SPEED_BONUS_NAME, 1 + runspeed_bonus)
        inst.components.temperature.mintemp = 10
    end
end

local function OnLongUpdate(inst, dt)
    inst.charge_time = math.max(0, inst.charge_time - dt)
end

local function OnPreLoad(inst, data)
    if data ~= nil and data.level ~= nil then
        inst.level = data.level
        ApplyUpgrades(inst)
        --re-set these from the save data, because of load-order clipping issues
        if data.health ~= nil and data.health.health ~= nil then
            inst.components.health:SetCurrentHealth(data.health.health)
        end
        if data.hunger ~= nil and data.hunger.hunger ~= nil then
            inst.components.hunger.current = data.hunger.hunger
        end
        if data.sanity ~= nil and data.sanity.current ~= nil then
            inst.components.sanity.current = data.sanity.current
        end
        inst.components.health:DoDelta(0)
        inst.components.hunger:DoDelta(0)
        inst.components.sanity:DoDelta(0)
    end
end

local function StartOvercharge(inst, duration)
    inst.charge_time = duration

    inst:AddTag("overcharge")
    inst:PushEvent("ms_overcharge") -- ziwbi: This one is for glow berry, maybe we should remove this

    inst.SoundEmitter:KillSound("overcharge_sound")
    inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/charged", "overcharge_sound")
    inst.SoundEmitter:SetParameter("overcharge_sound", "intensity", 0.5) -- keep it quiet
    inst.components.bloomer:PushBloom("overcharge", "shaders/anim.ksh", 50)

    if inst.charged_task == nil then
        inst.charged_task = inst:DoPeriodicTask(1, OnUpdate, nil, 1)
        OnUpdate(inst, 0)
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.charge_time ~= nil then
        StartOvercharge(inst, data.charge_time)
    end
end

local function OnSave(inst, data)
    data.level = inst.level > 0 and inst.level or nil
    data.charge_time = inst.charge_time > 0 and inst.charge_time or nil
end

local function OnLightingStrike(inst)
    if inst.components.health ~= nil and not (inst.components.health:IsDead() or inst.components.health:IsInvincible()) then
        if inst.components.inventory:IsInsulated() then
            inst:PushEvent("lightningdamageavoided")
        else
            inst.sg:GoToState("electrocute")
            inst.components.health:DoDelta(TUNING.HEALING_SUPERHUGE, false, "lightning")
            inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE"))

            StartOvercharge(inst, CalcDiminishingReturns(inst.charge_time, TUNING.TOTAL_DAY_TIME))
        end
    end
end

local function DoRainSparks(inst, dt)
    if not inst.components.moisture or inst.components.moisture:GetMoisture() <= 0 then
        return
    end

    local t = GetTime()

    -- Raining, no moisture-giving equipment on head, and moisture is increasing. Pro-rate damage based on waterproofness.
    if inst.components.inventory:GetEquippedMoistureRate(EQUIPSLOTS.HEAD) <= 0 and inst.components.moisture:GetRate() > 0 then
        local waterproofmult =
            (   inst.components.sheltered ~= nil and
                inst.components.sheltered.sheltered and
                inst.components.sheltered.waterproofness or 0
            ) +
            (   inst.components.inventory ~= nil and
                inst.components.inventory:GetWaterproofness() or 0
            )
        if waterproofmult < 1 and t > inst.spark_time + inst.spark_time_offset + waterproofmult * 7 then
            inst.components.health:DoDelta(TUNING.WX78_MAX_MOISTURE_DAMAGE, false, "rain")
            inst.spark_time_offset = 3 + math.random() * 2
            inst.spark_time = t
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("sparks").Transform:SetPosition(x, y + 1 + math.random() * 1.5, z)
        end
    elseif t > inst.spark_time + inst.spark_time_offset then -- We have moisture-giving equipment on our head or it is not raining and we are just passively wet (but drying off). Do full damage.
        inst.components.health:DoDelta(
            inst.components.moisture:GetRate() >= 0 and
            TUNING.WX78_MAX_MOISTURE_DAMAGE or
            TUNING.WX78_MOISTURE_DRYING_DAMAGE,
            false, "water")
        inst.spark_time_offset = 3 + math.random() * 2
        inst.spark_time = t
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
    end
end

local function OnBecameRobot(inst)
    inst.spark_task = inst:DoPeriodicTask(0.1, DoRainSparks, nil, 0.1)

    --Override with overcharge light values
    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetIntensity(0.9)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)
end

local function OnBecameGhost(inst)
    --Cancel overcharge mode
    if inst.charged_task ~= nil then
        inst.charged_task:Cancel()
        inst.charged_task = nil
        inst.charge_time = 0
        inst.SoundEmitter:KillSound("overcharge_sound")
        inst:RemoveTag("overcharge")
        inst.components.temperature.mintemp = -20
        inst.components.bloomer:PopBloom("overcharge")
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, SPEED_BONUS_NAME)
        --Ghost mode already sets light and bloom
    end

    if inst.spark_task ~= nil then
        inst.spark_task:Cancel()
        inst.spark_task = nil
    end
end

local function OnDeath(inst)
    if inst.level <= 0 then
        return
    end

    local num_gears = math.random(math.floor(inst.level / 3), math.ceil(inst.level / 2))

    for i = 1, num_gears do -- no need to check num_gears > 0 since "for i = 1, 0 do ... end" will not execute
        local gear = SpawnPrefab("gears")
        if gear ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            if gear.Physics ~= nil then
                local speed = 2 + math.random()
                local angle = math.random() * 2 * PI
                gear.Transform:SetPosition(x, y + 1, z)
                if gear.components.inventoryitem then
                    gear.components.inventoryitem:Launch(Vector3(speed * math.cos(angle), speed * 3, speed * math.sin(angle)))
                else
                    gear.Physics:SetVel(speed * math.cos(angle), speed * 3, speed * math.sin(angle))
                end
            else
                gear.Transform:SetPosition(x, y, z)
            end
            if gear.components.propagator ~= nil then
                gear.components.propagator:Delay(5)
            end
        end
    end

    inst.level = 0
    ApplyUpgrades(inst)
end

local function common_postinit(inst)
    -- electricdamageimmune is for combat and not lightning strikes
    -- also used in stategraph for not stomping custom light values
    inst:AddTag("electricdamageimmune")
    -- immune to poison, but still need the poisonable component
    inst:RemoveTag("poisonable")

    inst.components.talker.mod_str_fn = string.utf8upper

    inst.foleysound = "dontstarve/movement/foley/wx78"
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidlestate = "wx78_funnyidle"

    inst.level = 0
    inst.charged_task = nil
    inst.charge_time = 0
    inst.spark_task = nil
    inst.spark_time = 0
    inst.spark_time_offset = 3
    inst.watching_rain = false

    if inst.components.eater ~= nil then
        inst.components.eater.ignoresspoilage = true
        inst.components.eater:SetCanEatGears()
        inst.components.eater:SetOnEatFn(OnEat)
    end
    ApplyUpgrades(inst)

    inst:ListenForEvent("ms_respawnedfromghost", OnBecameRobot)
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_playerreroll", OnDeath) --delevel, give back some gears

    inst.components.playerlightningtarget:SetHitChance(1)
    inst.components.playerlightningtarget:SetOnStrikeFn(OnLightingStrike)

    OnBecameRobot(inst)

    inst.OnLongUpdate = OnLongUpdate
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnPreLoad = OnPreLoad
end

return MakePlayerCharacter("wx78", prefabs, assets, common_postinit, master_postinit)
