require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
}

local states_west =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.components.door:UpdateDoorVis()
            if inst.components.door.hidden then
                inst.AnimState:PlayAnimation("west_closed", true)
            else
                inst.AnimState:PlayAnimation("west", true)
            end
        end,
    },

    State{
        name = "open",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.door:SetHidden(false)
            inst.components.door:UpdateDoorVis()
            inst.AnimState:PlayAnimation("west_open", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
            EventHandler("entitysleep", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "shut",
        tags = {"busy", "shut"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("west_shut", false)
        end,

        onexit = function(inst)
            inst.components.door:SetHidden(true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.door:UpdateDoorVis()
                inst.sg:GoToState("idle")
            end),
            EventHandler("entitysleep", function(inst)
                inst.components.door:UpdateDoorVis()
                inst.sg:GoToState("idle")
            end),
        }
    },
}

return StateGraph("anthilldoor_west", states_west, events, "idle", actionhandlers)
