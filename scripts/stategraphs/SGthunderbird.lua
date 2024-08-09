require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.THUNDERBIRD_CAST, nil),
    ActionHandler(ACTIONS.GOHOME, "gohome"),
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttacked(),

    EventHandler("cancel_charge", function(inst) inst.sg:GoToState("charge_pst") end),

    EventHandler("start_charging", function(inst)
        inst.Transform:SetFourFaced()
        if inst.lightning_target then
            inst:ForceFacePoint(inst.lightning_target.Transform:GetWorldPosition())
            inst.sg:GoToState("charge_pre")
            inst.charging = true
        end
    end),

    EventHandler("threat_gone", function(inst)
        inst.sg:GoToState("idle")
        inst.Transform:SetFourFaced()
        inst:ForceFacePoint(inst.lightning_target.Transform:GetWorldPosition())
        inst.lightning_target = nil
    end),
}

local states =
{
    State{
        name= "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            if inst.fx and math.random() < 0.1 then
                inst.fx.AnimState:PlayAnimation("idle")
            end

            inst.components.locomotor:StopMoving()
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
        name = "gohome",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.homeseeker:GetHome().components.pickable:Regen()
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/death")
            inst.AnimState:PlayAnimation("death")

            inst.components.locomotor:StopMoving()
            inst.components.lootdropper:DropLoot()
            RemovePhysicsColliders(inst)
        end,
    },

    State{
        name = "charge_pre",
        tags = {"busy"},

        onenter = function(inst)

            if inst.fx then
                inst.fx.AnimState:PlayAnimation("charge_pre")
                inst.fx.AnimState:PushAnimation("charge_loop", true)
            end

            inst.AnimState:PlayAnimation("charge_pre")
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/jacobshorn", nil, 0.25)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/shocked_electric", nil, 0.25)
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("charge") end ),
        },
    },

    State{
        name = "charge",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("charge_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/hum_LP", "hum")
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("hum")
        end,
    },

    State{
        name = "charge_pst",
        tags = {"busy"},

        onenter = function(inst)
            if inst.fx then
                inst.fx.AnimState:PlayAnimation("charge_pst")
            end

            inst.AnimState:PlayAnimation("charge_pst")
        end,

        events=
        {
            EventHandler("animover", function(inst)
                inst.charging = false
                inst.sg:GoToState("idle")
            end ),
        },
    },

    State{
        name = "thunder_attack",
        tags = {"attack"},

        onenter = function(inst)
            if inst.fx then
                inst.fx.AnimState:PlayAnimation("shoot")
            end

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/attack_swipe")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/shoot")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("shoot")
            inst:DoLightning(inst.lightning_target)
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "pickup",

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst:PerformBufferedAction()
                inst.sg:GoToState("pickup_pst")
            end),
        },
    },

    State{
        name = "pickup_pst",

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("appear")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline = {

        TimeEvent(2 * FRAMES, PlayFootstep),
        TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/run", nil, 0.5) end),
    },
})
CommonStates.AddRunStates(states,
{
    runtimeline = {
        TimeEvent(2 * FRAMES, PlayFootstep),
        TimeEvent(2 * FRAMES, function(inst)
            if inst.should_play_idle then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/thunderbird/run")
                inst.should_play_idle = false
            else
                inst.should_play_idle = true
            end
        end),
    },
})

CommonStates.AddFrozenStates(states)

CommonStates.AddSleepStates(states, {
    starttimeline = {
        TimeEvent(0 * FRAMES, function(inst)
            if inst.fx then
                inst.fx.AnimState:PlayAnimation("idle")
            end
        end),
    },
})

return StateGraph("thunderbird", states, events, "idle", actionhandlers)
