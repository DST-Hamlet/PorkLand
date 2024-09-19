require("stategraphs/commonstates")

local actionhandlers = {}

local events =
{

}

local states =
{
    State{
        name = "turn_on",
        tags = {"idle"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/on")
            inst.AnimState:PlayAnimation("turn_on")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end),
        }
    },

    State{
        name = "turn_off",
        tags = {"idle"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/off")
            inst.AnimState:PlayAnimation("turn_off")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_off") end),
        }
    },

    State{
        name = "idle_on",
        tags = {"idle"},

        onenter = function(inst)
            --Start some loop sound
            if not inst.SoundEmitter:PlayingSound("firesuppressor_idle") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/working", "firesuppressor_idle")
            end
            inst.AnimState:PlayAnimation("launch")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end),
        }
    },

    State{
        name = "idle_off",
        tags = {"idle"},

        onenter = function(inst)
            --Stop some loop sound
            inst.SoundEmitter:KillSound("firesuppressor_idle")
            inst.AnimState:PlayAnimation("idle_off", true)
        end,
    },

    State{
        name = "place",
        tags = {"busy"},

        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("place")
            -- inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/sprinkler/place")
            --Play some sound / good idea
        end,

        timeline = {},

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end)
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst, data)
            if inst.on then
                inst.AnimState:PlayAnimation("hit_on")
            else
                inst.AnimState:PlayAnimation("hit_off")
            end
            --Play some sound 
        end,

        timeline = {},

        events =
        {
            EventHandler("animover", function(inst)
                if inst.on then
                    inst.sg:GoToState("idle_on")
                else
                    inst.sg:GoToState("idle_off")
                end
            end)
        },
    },
}

return StateGraph("sprinkler", states, events, "idle_off", actionhandlers)