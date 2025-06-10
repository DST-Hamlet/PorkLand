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
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.components.door:UpdateDoorVis()
            if inst.components.door.hidden then
                inst.AnimState:PlayAnimation("east_closed", true)
            else
                inst.AnimState:PlayAnimation("east", true)
            end
        end,
    },

    State{
        name = "open",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.door:SetHidden(false)
            inst.components.door:UpdateDoorVis()
            inst.AnimState:PlayAnimation("east_open", false)
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
            inst.AnimState:PlayAnimation("east_shut", false)
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

return StateGraph("anthilldoor_east", states_east, events, "idle", actionhandlers)
