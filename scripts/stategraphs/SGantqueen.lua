require("stategraphs/commonstates")
-- require "prefabs/antqueen_spawner"

local events=
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(true),
    CommonHandlers.OnDeath(),
}

local states=
{
    State{
        name= "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            -- inst.SoundEmitter:PlaySound("pl/creatures/crickant/hunger")
            inst.AnimState:PlayAnimation("idle")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name= "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline=
        {
            TimeEvent(18*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/taunt")end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.combat.canattack = true
                inst.sg:GoToState("idle")
            end ),
        },
    },

    State{
        name = "jump_attack",
        tags = {"busy"},

        onenter = function (inst)
            local jump_count = inst.jump_count or 1

            for i=1, jump_count do
                if i ~= 1 then
                    inst.AnimState:PushAnimation("atk2", false)
                else
                    inst.AnimState:PlayAnimation("atk2", false)
                end
            end
        end,

        timeline=
        {
            TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_2_fly") end),
            TimeEvent(7*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_2_VO") end),
            TimeEvent(21*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/land") end),
            -- TimeEvent(24*FRAMES, function(inst) TheWorld:PushEvent("ms_forcequake") end),
            -- TimeEvent(24*FRAMES, function(inst) TheWorld.components.quaker_interior:ForceQuake("queenattack") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
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
            TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_1_rumble") end),
            TimeEvent(18*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_1_pre") end),
            TimeEvent(20*FRAMES, function(inst)inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_1") end),
            TimeEvent(20*FRAMES, function(inst)  inst.SpawnWarrior(inst) end),
        },
    },

    State{
        name = "music_attack",
        tags = {"busy"},

        onenter = function (inst)
            inst.AnimState:PlayAnimation("atk3_pre", false)
            inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_3_breath_in")
        end,

        timeline =
        {
            TimeEvent(5*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/atk_3_breath_in") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/insane_LP","insane") end),
            TimeEvent(25*FRAMES, function(inst)
            --让范围内玩家都进入掉san和不能移动的状态
                local pt = inst:GetPosition()
                local players = TheSim:FindEntities(pt.x, pt.y, pt.z, 25, {"player"})
                for k, player in pairs(players) do
                    player:PushEvent("sanity_stun", {duration = 3.5})
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.dontstopinsane = true inst.sg:GoToState("music_loop") end ),
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
            TheMixer:PushMix("mute")
            inst.AnimState:PlayAnimation("atk3_loop", true)
            inst.sg:SetTimeout((23/30)*4)
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
            TheMixer:PopMix("mute")
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
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("insane")
        end,
    },


    State {
        name = "frozen",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("frozen")
            inst.Physics:Stop()
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            local pt = Vector3(inst.Transform:GetWorldPosition())
            inst.components.lootdropper:DropLoot(pt)
        end,

        timeline =
        {

            TimeEvent(6*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/death") end),
            TimeEvent(6*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode",nil,.2) end),
            TimeEvent(10*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode",nil,.3) end),
            TimeEvent(14*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode",nil,.4) end),
            TimeEvent(18*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode",nil,.5) end),
            TimeEvent(22*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode",nil,.6) end),
            TimeEvent(26*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode",nil,.7) end),
            TimeEvent(28*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/explode") end),
            TimeEvent(43*FRAMES, function (inst)  inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/land") end),
            TimeEvent(1*FRAMES, function(inst, data)
                inst:DoTaskInTime(2, function()
                    local throne = SpawnPrefab("antqueen_throne")
                    local x,y,z = inst.Transform:GetWorldPosition()
                    throne.Transform:SetPosition(x-0.025, y, z)

                    inst.AnimState:ClearOverrideBuild("throne")
                end)
            end ),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
}

CommonStates.AddSleepStates(states,
    {

        starttimeline =
        {
            TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/breath_out") end),
        },

        sleeptimeline =
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/breath_in") end ),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/boss/antqueen/breath_out") end ),
        },
    },
    {
        -- The queen always taunts the player after waking up
        onwake = function(inst)
            inst:DoTaskInTime(18*FRAMES, function() inst.sg:GoToState("taunt") end)
        end,
    }
)

CommonStates.AddFrozenStates(states)
return StateGraph("antqueen", states, events, "sleep")
