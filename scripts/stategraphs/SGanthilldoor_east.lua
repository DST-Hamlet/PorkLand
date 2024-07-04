require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
}

local states_east =
{
    State{
        name = "idle_east",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.components.door:UpdateDoorVis()
            inst.AnimState:PlayAnimation("east", true)
        end,
    },

    State{
        name = "open_east",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.door:SetHidden(false)
            inst.components.door:UpdateDoorVis()
            inst.AnimState:PlayAnimation("east_open", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_east")
            end),
        }
    },

    State{
        name = "shut_east",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("east_shut", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.door:SetHidden(true)
                inst.components.door:UpdateDoorVis()
                inst.sg:GoToState("idle_east")
            end),
        }
    },
}

return StateGraph("anthilldoor_east", states_east, events, "idle_east", actionhandlers)
