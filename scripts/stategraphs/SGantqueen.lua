require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(TUNING.BOSS_HITREACT_COOLDOWN, TUNING.BOSS_MAX_STUN_LOCKS),
    CommonHandlers.OnDeath(),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
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
            TimeEvent(18 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/antqueen/taunt")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.combat.canattack = true
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "jump_attack",
        tags = {"busy"},

        onenter = function (inst)
            local jump_count = inst.jump_count or 1

            for i = 1, jump_count do
                if i ~= 1 then
                    inst.AnimState:PushAnimation("atk2", false)
                else
                    inst.AnimState:PlayAnimation("atk2", false)
                end
            end
        end,

        timeline =
        {
            TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_2_fly") end),
            TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_2_VO") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/land") end),
            TimeEvent(24 * FRAMES, function(inst)
                local interiorID = inst:GetCurrentInteriorID()
                TheWorld:PushEvent("interior_startquake", {quake_level = INTERIOR_QUAKE_LEVELS.QUEEN_ATTACK, interiorID = interiorID})
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "summon_warriors",
        tags = {"busy"},

        onenter = function (inst)
            inst.AnimState:PlayAnimation("atk1", false)

            if inst.current_summon_count <= 0 then
                inst.current_summon_count = inst.summon_count
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.current_summon_count = inst.current_summon_count - 1

                if inst.current_summon_count > 0 then
                    inst.sg:GoToState("summon_warriors")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },

        timeline =
        {
            TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_1_rumble") end),
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_1_pre") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_1") end),
            TimeEvent(20 * FRAMES, function(inst) inst:SpawnWarrior() end),
        },
    },

    State{
        name = "music_attack",
        tags = {"busy"},

        onenter = function (inst)
            inst.AnimState:PlayAnimation("atk3_pre", false)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_3_breath_in")
        end,

        timeline =
        {
            TimeEvent(5  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/atk_3_breath_in") end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/antqueen/insane_LP", "insane") end),
            TimeEvent(25 * FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local players = TheSim:FindEntities(x, y, z, 50, {"player"}, {"player_ghost"})
                for _, player in pairs(players) do
                    player:PushEvent("sanity_stun", {duration = 3.5})
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.dontstopinsane = true
                inst.sg:GoToState("music_loop")
            end),
        },

        onexit = function(inst)
            if not inst.dontstopinsane then
                inst.SoundEmitter:KillSound("insane")
            end
            inst.dontstopinsane = nil
        end,
    },

    State{
        name = "music_loop",
        tags = {"busy"},

        onenter = function (inst)
            inst.mixer:set(true) -- mixer runs on client side
            inst.AnimState:PlayAnimation("atk3_loop", true)
            inst.sg:SetTimeout(4 * 23 / 30)
        end,

        ontimeout= function(inst)
            inst.dontstopinsane = true
            inst.sg:GoToState("music_pst")
        end,

        onexit = function(inst)
            if not inst.dontstopinsane then
                inst.SoundEmitter:KillSound("insane")
            end
            inst.dontstopinsane = nil
            inst.mixer:set(false)
        end,
    },

    State{
        name = "music_pst",
        tags = {"busy"},

        onenter = function (inst)
            inst.AnimState:PlayAnimation("atk3_pst", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("insane")
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(6  * FRAMES, function (inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/antqueen/death") end),
            TimeEvent(6  * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode", nil, 0.2) end),
            TimeEvent(10 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode", nil, 0.3) end),
            TimeEvent(14 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode", nil, 0.4) end),
            TimeEvent(18 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode", nil, 0.5) end),
            TimeEvent(22 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode", nil, 0.6) end),
            TimeEvent(26 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode", nil, 0.7) end),
            TimeEvent(28 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/explode") end),
            TimeEvent(43 * FRAMES, function (inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/land")
                inst.components.lootdropper:DropLoot()
            end),
            TimeEvent(2, function(inst)
                local throne = SpawnPrefab("antqueen_throne")
                local x, y, z = inst.Transform:GetWorldPosition()
                throne.Transform:SetPosition(x - 0.025, y, z)

                inst.AnimState:ClearOverrideBuild("throne")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(35 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/breath_out") end),
    },

    sleeptimeline = {
        TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/breath_in") end),
        TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/antqueen/breath_out") end),
    },
}, {
    -- The queen always taunts the player after waking up
    onwake = function(inst)
        inst:DoTaskInTime(18 * FRAMES, function()
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("taunt")
            end
        end)
    end,
})

CommonStates.AddFrozenStates(states)

return StateGraph("antqueen", states, events, "sleep", actionhandlers)
