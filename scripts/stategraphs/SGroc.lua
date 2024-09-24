require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
    EventHandler("fly", function(inst) inst.sg:GoToState("fly") end),
    EventHandler("land", function(inst) inst.sg:GoToState("land") end),
    EventHandler("takeoff", function(inst) inst.sg:GoToState("takeoff") end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("ground_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "land",
        tags = {"busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("ground_pre")
        end,

        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst) inst.components.roccontroller:Spawnbodyparts() end),
            TimeEvent(5 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap","flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap","flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "takeoff",
        tags = {"busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("ground_pst")
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.components.locomotor:RunForward() end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("fly")
            end),
        }
    },

    State{
        name = "fly",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.sg:SetTimeout(1 + 2 * math.random())
            inst.AnimState:PlayAnimation("shadow")
        end,

        ontimeout=function(inst)
            inst.sg:GoToState("flap")
        end,
    },

    State{
        name = "flap",
        tags = {"moving","canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("shadow_flap_loop")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap", "flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),

            TimeEvent(1 * FRAMES, function(inst)
                if math.random() < 0.5 then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/call", "calls")
                end
                inst.SoundEmitter:SetParameter("calls", "intensity", inst.sound_distance)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if not inst.flap then
                    inst.sg:GoToState("flap")
                    inst.flap = true
                else
                    inst.sg:GoToState("fly")
                    inst.flap = nil
                end
            end),
        },
    },
}

return StateGraph("roc", states, events, "idle", actionhandlers)
