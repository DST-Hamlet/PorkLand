require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{

    EventHandler("enter", function(inst) inst.sg:GoToState("enter") end),
    EventHandler("exit", function(inst) inst.sg:GoToState("exit") end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("tail_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "enter",
        tags = {"idle","canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("tail_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "exit",
        tags = {"idle","canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("tail_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst:Remove()
            end),
        }
    },
}

return StateGraph("roc_tail", states, events, "idle", actionhandlers)
