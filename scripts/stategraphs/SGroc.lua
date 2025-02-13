require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
    EventHandler("fly", function(inst)
        if not inst.sg:HasStateTag("turn") then
            inst.sg:GoToState("fly")
        end
    end),
    EventHandler("turn", function(inst)
        if not inst.sg:HasStateTag("turn") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("turn")
        end
    end),
    EventHandler("land", function(inst) inst.sg:GoToState("land") end),
    EventHandler("takeoff", function(inst)
        if not inst.sg:HasStateTag("moving") then
            inst.sg:GoToState("takeoff")
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle" },

        onenter = function(inst)
            inst.components.shadeanimstate:PlayAnimation("roc_shadow_ground_loop")
        end,
    },

    State{
        name = "land",
        tags = {"busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.shadeanimstate:PlayAnimation("roc_shadow_ground_pre")
        end,

        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst) inst.components.roccontroller:Spawnbodyparts() end),
            TimeEvent(5 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flaps")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/porkland_soundpackage","flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flaps")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/porkland_soundpackage","flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),

            TimeEvent(42 * FRAMES, function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "takeoff",
        tags = {"busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.shadeanimstate:PlayAnimation("roc_shadow_ground_pst")
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.components.glidemotor:EnableMove(true) end),
            TimeEvent(54 * FRAMES, function(inst) inst.sg:GoToState("fly") end),
        },

        onexit = function(inst)
            inst.components.glidemotor:EnableMove(false)
        end,
    },

    State{
        name = "fly",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.glidemotor:EnableMove(true)
            inst.sg:SetTimeout(1 + 2 * math.random())
            inst.components.shadeanimstate:PlayAnimation("roc_shadow_shadow")
        end,

        ontimeout=function(inst)
            inst.sg:GoToState("flap")
        end,

        onexit = function(inst)
            inst.components.glidemotor:EnableMove(false)
        end,
    },

    State{
        name = "flap",
        tags = {"moving","canrotate"},

        onenter = function(inst)
            inst.components.glidemotor:EnableMove(true)
            inst.components.shadeanimstate:PlayAnimation("roc_shadow_shadow_flap_loop")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flaps")
                inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/roc/flap", "flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),

            TimeEvent(1 * FRAMES, function(inst)
                if math.random() < 0.5 then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/roc/call", "calls")
                end
                inst.SoundEmitter:SetParameter("calls", "intensity", inst.sound_distance)
            end),

            TimeEvent(37 * FRAMES, function(inst)
                if not inst.flap then
                    inst.sg:GoToState("flap")
                    inst.flap = true
                else
                    inst.sg:GoToState("fly")
                    inst.flap = nil
                end
            end),
        },

        onexit = function(inst)
            inst.components.glidemotor:EnableMove(false)
        end,
    },

    State{
        name = "turn",
        tags = {"moving","canrotate","turn","busy"},

        onenter = function(inst)
            inst.sg:SetTimeout(3)
            inst.components.glidemotor:EnableMove(true)
            inst.components.glidemotor:TurnFast(1.2)
            inst.components.shadeanimstate:PlayAnimation("roc_shadow_shadow_flap_loop")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flaps")
                inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/roc/flap", "flaps")
                inst.SoundEmitter:SetParameter("flaps", "intensity", inst.sound_distance)
            end),
        },

        onexit = function(inst)
            inst.components.glidemotor:TurnFast(-1)
            inst.components.glidemotor:EnableMove(false)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("fly")
        end,
    },
}

return StateGraph("roc", states, events, "idle", actionhandlers)
