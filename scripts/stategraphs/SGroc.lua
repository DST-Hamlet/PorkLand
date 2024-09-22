require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
    EventHandler("turn", function(inst)
        if inst.sg:HasStateTag("turn") then
            return
        end
        inst.sg:GoToState("turn")
    end),
    EventHandler("fly", function(inst)
        if inst.sg:HasStateTag("turn") or inst.sg:HasStateTag("fly") then
            return
        end
        inst.sg:GoToState("fly")
    end),
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
            TimeEvent(30 * FRAMES, function(inst) inst:ShowBodyParts() end),
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
            TimeEvent(15 * FRAMES, function(inst) end),
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
        tags = {"moving", "canrotate", "fly"},

        onenter = function(inst)
            inst.sg:SetTimeout(1 + 2 * math.random())
            inst.AnimState:PlayAnimation("shadow")
        end,

        ontimeout=function(inst)
            inst.sg:GoToState("flap")
        end,
    },

    State{
        name = "flap",
        tags = {"moving","canrotate","fly"},

        onenter = function(inst)
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

    State{
        name = "turn",
        tags = {"moving", "canrotate", "turn"},

        onenter = function(inst)
            inst.components.timer:StartTimer("turn_cd", 3)
            inst.components.glidemotor:TurnFast(1.2)
            if inst.components.glidemotor.turnmode == "left" then
                inst.AnimState:PlayAnimation("shadow_flap_loop")
            else
                inst.AnimState:PlayAnimation("shadow_flap_loop")
            end
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/flap", "flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),
        },

        onexit = function(inst)
            inst.components.glidemotor:TurnFast(-1)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("fly")
            end),
        },
    },
}

return StateGraph("roc", states, events, "idle", actionhandlers)
