require("stategraphs/commonstates")

local actionhandlers = {}
local events = {}

local states = {
    State{
        name = "turn_on",
        tags = {"idle"},

        onenter = function(inst)
            -- inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_on")
            inst.AnimState:PlayAnimation("activate")
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end),
        }
    },

    State{
        name = "turn_off",
        tags = {"idle"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("deactivate")
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_off") end),
        }
    },

    State{
        name = "idle_on",
        tags = {"idle"},

        onenter = function(inst)
            if not inst.SoundEmitter:PlayingSound("firesuppressor_idle") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/fan/on_LP", "firesuppressor_idle")
            end
            inst.AnimState:PlayAnimation("idle_loop")
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_on") end),
        }
    },

    State{
        name = "idle_off",
        tags = {"idle"},

        onenter = function(inst)
            inst.SoundEmitter:KillSound("firesuppressor_idle")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/fan/off")
            inst.AnimState:PlayAnimation("off", true)
        end,
    },

    State{
        name = "place",
        tags = {"busy"},

        onenter = function(inst, data)
            inst.AnimState:PlayAnimation("place")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/fan/place")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_off")
            end)
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst, data)
            inst.AnimState:PlayAnimation(inst.on and "hit_on" or "hit_off")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/fan/hit")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState(inst.on and "idle_on" or "idle_off")
            end)
        },
    },
}

return StateGraph("basefan", states, events, "idle_off", actionhandlers)
