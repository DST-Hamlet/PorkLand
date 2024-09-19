require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst:Show()
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },

    State{
        name = "hidden",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst:Hide()
        end,
    },

    State{
        name = "extend",
        tags = {"canrotate"},

        onenter = function(inst, intensity)
            inst:Show()
            inst.AnimState:PlayAnimation("place", false)

            inst.sg.statemem.intensity = intensity
            local actual_intensity = math.min(intensity, 10) / 10

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/pipe_craft", "pipesound_on")
            inst.SoundEmitter:SetParameter("pipesound_on", "intensity", actual_intensity)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst._next then
                    inst._next.sg:GoToState("extend", inst.sg.statemem.intensity + 1)
                end

                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "retract",
        tags = {"canrotate"},

        onenter = function(inst, intensity)
            inst.AnimState:PlayAnimation("retract", false)

            inst.sg.statemem.intensity = intensity
            local actual_intensity = math.min(intensity, 10) / 10

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/pipe_craft", "pipesound_on")
            inst.SoundEmitter:SetParameter("pipesound_on", "intensity", actual_intensity)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst._prev then
                    inst._prev.sg:GoToState("retract", inst.sg.statemem.intensity - 1)
                end

                inst:Remove()
            end),
        }
    },
}

return StateGraph("water_pipe", states, events, "hidden", actionhandlers)
