require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
}

local states_north =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.components.door:UpdateDoorVis()
            if inst.components.door.hidden then
                inst.AnimState:PlayAnimation("north_closed", true)
            else
                inst.AnimState:PlayAnimation("north", true)
            end
        end,
    },

    State{
        name = "open",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.door:SetHidden(false)
            inst.components.door:UpdateDoorVis()
            inst.AnimState:PlayAnimation("north", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_north")
            end),
        }
    },

    State{
        name = "shut",
        tags = {"busy", "shut"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("north_shut", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.door:SetHidden(true)
                inst.components.door:UpdateDoorVis()
                inst.sg:GoToState("idle")
            end),
        }
    },

    -- 旧存档的sg

    State{
        name = "idle_north",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "open_north",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.door:SetHidden(false)
            inst.components.door:UpdateDoorVis()
            inst.AnimState:PlayAnimation("north_open", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_north")
            end),
        }
    },

    State{
        name = "shut_north",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("north_shut", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.door:SetHidden(true)
                inst.components.door:UpdateDoorVis()
                inst.sg:GoToState("idle_north")
            end),
        }
    },
}

return StateGraph("anthilldoor_north", states_north, events, "idle", actionhandlers)
