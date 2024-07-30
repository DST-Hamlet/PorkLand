require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst, push_anim)
            if push_anim then
                inst.AnimState:PushAnimation("idle")
            else
                inst.AnimState:PlayAnimation("idle")
            end
        end
    },

    State{
        name = "grow",
        tags = {"grow"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("grow")
        end,

        timeline =
        {
            TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bramble/grow") end),
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    }
}

CommonStates.AddHitState(states)

CommonStates.AddDeathState(states, nil, "wither")

return StateGraph("bramble", states, events, "idle", {})