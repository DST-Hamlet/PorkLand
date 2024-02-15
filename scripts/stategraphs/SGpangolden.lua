require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.PANGOLDEN_DRINK, "drink_pre"),
    ActionHandler(ACTIONS.PANGOLDEN_POOP, "poop"),
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("attack") then
            if inst.components.health:GetPercent() >= 0.5 and not inst.sg:HasStateTag("ball") then
                inst.sg:GoToState("ball_pre")
            elseif inst.components.health:GetPercent() < 0.5 and inst.sg:HasStateTag("ball") then
                inst.sg:GoToState("idle","ball_pst")
            elseif inst.components.health:GetPercent() >= 0.5 and inst.sg:HasStateTag("ball") then
                inst.sg:GoToState("ball_hit")
            else
                inst.sg:GoToState("hit")
            end
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()

            if math.random() < 0.2 then
                if math.random() < 0.5 then
                    inst.sg:GoToState("shake")
                else
                    inst.sg:GoToState("preen")
                end
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
                inst.sg:SetTimeout(2 + 2 * math.random())
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "shake",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shake")
        end,

       timeline =
        {
            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/shake") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(29 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "preen",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("preen_pre")
            for _ = 1, math.random(1, 3)  do
                inst.AnimState:PushAnimation("preen_loop", false)
            end
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, 0.5) end),
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/lick") end),
            TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/lick") end),
            TimeEvent(57 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/lick") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("preen_pst") end),
        },
    },

    State{
        name = "preen_pst",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("preen_pst")
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/lick") end),
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "ball_pre",
        tags = {"ball", "busy"},

        onenter = function(inst, target)
            inst.components.health:SetAbsorptionAmount(TUNING.PANGOLDEN_BALL_DEFENCE) -- TODO
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("ball_pre")
            inst:AddTag("avoidonhit")
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", 0.01)
            end),
            TimeEvent(6 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", 0.33)
            end),
            TimeEvent(9 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", 0.66)
            end),
             TimeEvent(20 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/ball_hit")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk")
             end),
             TimeEvent(30 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        onexit = function(inst)
            inst:RemoveTag("avoidonhit")
            inst.components.health:SetAbsorptionAmount(0)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("ball") end),
        },
    },

    State{
        name = "ball",
        tags = {"ball", "busy"},

        onenter = function(inst, target)
            inst.components.health:SetAbsorptionAmount(TUNING.PANGOLDEN_BALL_DEFENCE)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("ball_idle", true)
            inst.sg:SetTimeout(10 + (5 * math.random()))
            inst:AddTag("avoidonhit")
        end,

        onexit = function(inst)
            inst:RemoveTag("avoidonhit")
            inst.components.health:SetAbsorptionAmount(0)
        end,

        ontimeout=function(inst)
            inst.sg:GoToState("ball_pst")
        end,

        timeline = {},
    },

    State{
        name = "ball_pst",
        tags = {"ball", "busy"},

        onenter = function(inst, target)
            inst.AnimState:PlayAnimation("ball_pst")
        end,

        timeline=
        {
            TimeEvent(11 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", 0.88)
            end),

            TimeEvent(14 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", 0.44)
            end),

            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement","scales")
                inst.SoundEmitter:SetParameter("scales", "intensity", 0.22)
            end),

            TimeEvent(20 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk")
             end),

            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk") end),

            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),

        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "ball_hit",
        tags = {"ball", "busy"},

        onenter = function(inst, target)
            inst.components.health:SetAbsorptionAmount(TUNING.PANGOLDEN_BALL_DEFENCE)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("ball_hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/ball_hit")
        end,

        onexit = function(inst)
            inst.components.health:SetAbsorptionAmount(0)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("ball") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,
    },

    State{
        name = "drink_pre",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("drink_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("drink_loop") end),
        },
    },

    State{
        name = "drink_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("drink_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/mouth")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/suck")
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle", "drink_pst")
            end),
        },
    },

    State{
        name = "poop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("poop")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/poop")
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(25 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(29 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/fart")
                inst:PerformBufferedAction()
            end),
            TimeEvent(45 * FRAMES, PlayFootstep),
            TimeEvent(43 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(56 * FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/step") end),
            TimeEvent(58 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(59 * FRAMES, PlayFootstep),
            TimeEvent(67 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(68 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/step") end),
            TimeEvent(70 * FRAMES, PlayFootstep),
            TimeEvent(68 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/step") end),
            TimeEvent(81 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("drink_pre")
            inst.AnimState:PushAnimation("drink_loop", false)
        end,

        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(32 * FRAMES, function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/mouth") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst:PerformBufferedAction()
                inst.sg:GoToState("idle", "drink_pst")
            end),
        },
    },
}

CommonStates.AddWalkStates(
    states,
    {
        walktimeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk", "steps")
                inst.SoundEmitter:SetParameter("steps", "intensity", 0.9 )
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement")
            end),

            TimeEvent(2 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk", "steps")
                inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            end),

            TimeEvent(2 * FRAMES, PlayFootstep),

            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),

            TimeEvent(20 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk", "steps")
                inst.SoundEmitter:SetParameter("steps", "intensity", -.9 )
            end),

            TimeEvent(21 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk", "steps")
                inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
            end),

            TimeEvent(21 * FRAMES, PlayFootstep),

            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
        },

        endtimeline =
        {
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/walk") end),
        }
    })

CommonStates.AddRunStates(
    states,
    {
        starttimeline =
        {
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/scared") end),
        },

        runtimeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/pangolden/walk", {timeoffset = math.random()})
            end),

            TimeEvent(2 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/pangolden/walk", {timeoffset = math.random()})
            end),

            TimeEvent(0 * FRAMES, PlayFootstep),

            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
            TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/scared") end),
        },
    })

CommonStates.AddSimpleState(states, "hit", "hit")

CommonStates.AddFrozenStates(states)

CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/yawn") end),
    },

    sleeptimeline =
    {
        TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/sleep") end),
    },

    waketimeline =
    {
        TimeEvent(22 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/movement") end),
        TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pangolden/step") end),
    },
})

return StateGraph("pangolden", states, events, "idle", actionhandlers)
