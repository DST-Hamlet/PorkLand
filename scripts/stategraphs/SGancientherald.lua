require("stategraphs/commonstates")

local AncientHulkUtil = require("prefabs/ancient_hulk_util")
local DoDamage = AncientHulkUtil.DoDamage
local AncientHeraldUtil = require("prefabs/ancient_herald_util")

local herald_summons = {
    AncientHeraldUtil.SpawnFireRain,
    AncientHeraldUtil.SpawnFrogRain,
    AncientHeraldUtil.SpawnGhosts,
    AncientHeraldUtil.SpawnNightmares,
}

-- these shouldn't spawn inside room
local herald_summons_interior = {
    AncientHeraldUtil.SpawnGhosts,
    AncientHeraldUtil.SpawnNightmares,
}

local function SpawnHeraldSummons(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local player
    if inst.components.combat.target
        and inst.components.combat.target:HasTag("player")
        and inst.components.combat:CanTarget(inst.components.combat.target) then

        player = inst.components.combat.target
    else
        player = FindClosestPlayerInRange(x, y, z, 20, true)
    end

    if not player then
        return
    end

    local fn
    if player:GetCurrentInteriorID() ~= nil then
        fn = GetRandomItem(herald_summons_interior)
    else
        fn = GetRandomItem(herald_summons)
    end

    fn(player, inst)
end

local function StartAura(inst)
    inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_attack_LP", "angry")
end

local function StopAura(inst)
    inst.SoundEmitter:KillSound("angry")
end

local events =
{
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(TUNING.BOSS_HITREACT_COOLDOWN, TUNING.BOSS_MAX_STUN_LOCKS),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(false, true),

    EventHandler("startaura",  StartAura),
    EventHandler("stopaura", StopAura),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate", "canslide"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },

    State{
        name = "appear",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl")
            -- inst.mixer:set(true)
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/appear") end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end)
        },

        onexit = function(inst)
            -- inst.mixer:set(false)
        end
    },

    State{
        name = "hit",
        tags = {"busy"}, -- hit tag用于控制生物在hit状态下也可以进行反击，由于先驱有硬直保护，因此不需要这个tag

        onenter = function(inst, cb)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/hit")
            inst.AnimState:PlayAnimation("hit")
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "disappear",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/death")
                AncientHeraldUtil.CancelFrogRain(inst)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst:Remove()
            end)
        },
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/taunt") end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end)
        },
    },

    State{
        name = "summon",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("summon")
            inst.mixer:set(true)
        end,

        timeline =
        {
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon") end),
            TimeEvent(1  * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/ancient_herald/summon_2d")
                inst.mixer:set(false)
            end),
            TimeEvent(30 * FRAMES, function(inst) SpawnHeraldSummons(inst) end)
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end)
        },

        onexit = function(inst)
            inst.mixer:set(false)
        end
    },

    State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("attack")
            inst.components.combat:StartAttack()

            inst.sg.statemem.target = target
        end,

        timeline = {
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack") end),
            TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/ancient_herald/attack_2d") end),
            TimeEvent(19 * FRAMES, function(inst) inst.mixer:set(true) end),
            TimeEvent(20 * FRAMES, function(inst)
                local ring = SpawnPrefab("laser_ring")
                ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
                ring.Transform:SetScale(1.1, 1.1, 1.1)
                DoDamage(inst, 6)
                inst.mixer:set(false)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.mixer:set(false)
        end
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/death")
                AncientHeraldUtil.CancelFrogRain(inst)
            end),
            TimeEvent(32 * FRAMES, function(inst)
                local pt = Vector3(inst.Transform:GetWorldPosition())
                pt.y = 5

                inst.components.lootdropper.y_speed = 4
                inst.components.lootdropper.min_speed = 3
                inst.components.lootdropper.max_speed = 3
                local loot_table = LootTables["ancient_herald_base"]
                if loot_table then
                    for i, entry in ipairs(loot_table) do
                        local prefab = entry[1]
                        local chance = entry[2]
                        if (chance >= 1.0) or (math.random() <= chance) then
                            inst.components.lootdropper:SpawnLootPrefab(prefab, pt)
                        end
                    end
                end

                inst.components.lootdropper.y_speed = 8
                inst.components.lootdropper.min_speed = 0
                inst.components.lootdropper.max_speed = 0
                local extra_loot_table = LootTables["ancient_remnant_extra"]
                if extra_loot_table then
                    for i, entry in ipairs(extra_loot_table) do
                        local prefab = entry[1]
                        local chance = entry[2]
                        if (chance >= 1.0) or (math.random() <= chance) then
                            inst.components.lootdropper:SpawnLootPrefab(prefab, pt)
                        end
                    end
                end
            end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/breath_in") end),
        TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/breath_out") end),
    }
})

return StateGraph("ancient_herald", states, events, "appear")
