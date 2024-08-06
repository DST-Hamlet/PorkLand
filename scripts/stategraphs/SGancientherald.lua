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
    local fn
    if inst:GetCurrentInteriorID() ~= nil then
        fn = GetRandomItem(herald_summons_interior)
    else
        fn = GetRandomItem(herald_summons)
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local player
    if inst.components.combat.target and inst.components.combat.target:HasTag("player") then
        player = inst.components.combat.target
    else
        player = FindClosestPlayerInRange(x, y, z, 20, true)
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
    CommonHandlers.OnAttacked(),
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
            TheMixer:PushMix("shadow") -- this doesn't work at all actually
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
        end,

        timeline =
        {
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon") end),
            TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon_2d") end),
            TimeEvent(30 * FRAMES, function(inst) SpawnHeraldSummons(inst) end)
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end)
        },
    },
}

CommonStates.AddCombatStates(states, {
    attacktimeline =
    {
        TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack") end),
        TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack_2d") end),
        TimeEvent(20 * FRAMES, function(inst)
            local ring = SpawnPrefab("laser_ring")
            ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
            ring.Transform:SetScale(1.1, 1.1, 1.1)
            DoDamage(inst, 6)
        end)
    },

    hittimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/hit") end),
    },

    deathtimeline =
    {
        TimeEvent(0 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/death")
            AncientHeraldUtil.CancelFrogRain(inst)
        end),
        TimeEvent(32 * FRAMES, function(inst)
            local pt = Vector3(inst.Transform:GetWorldPosition())
            pt.y = 5

            inst.components.lootdropper.speed = 3
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("ancient_remnant"), pt, math.random() * 360)
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("ancient_remnant"), pt, math.random() * 360)
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("ancient_remnant"), pt, math.random() * 360)
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("ancient_remnant"), pt, math.random() * 360)
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("ancient_remnant"), pt, math.random() * 360)

            inst.components.lootdropper.speed = 0
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("nightmarefuel"), pt, math.random() * 360)
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("nightmarefuel"), pt, math.random() * 360)
            inst.components.lootdropper:DropLootPrefab(SpawnPrefab("armorvortexcloak_blueprint"), pt, math.random() * 360)
        end),
    },
}, {attack = "attack",})

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/breath_in") end),
        TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/breath_out") end),
    }
})

return StateGraph("ancient_herald", states, events, "appear")
