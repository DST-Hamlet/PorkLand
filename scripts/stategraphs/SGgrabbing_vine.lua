require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst)
        if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("attack")
        end
    end),

    EventHandler("locomote", function(inst)
        local is_idling = inst.sg:HasStateTag("idle")
        local is_moving = inst.sg:HasStateTag("moving")
        if not is_idling and not is_moving then
            return
        end

        local should_move = inst.components.locomotor:WantsToMoveForward()
        if not should_move then
            if not is_idling then
                inst.sg:GoToState("idle")
            end
        else
            if not is_moving then
                inst.sg:GoToState("move")
            end
        end
    end),

    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,

        ontimeout= function(inst)
            if inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("move")
            else
                inst.sg:GoToState("idle")
            end
        end,
    },

    State{
        name = "up",
        tags = {"idle", "busy", "noattack", "up"},
        onenter = function(inst, playanim)
            inst:AddTag("noattack")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("up")
        end,
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_up") end),
        },
    },

    State{
        name = "idle_up",
        tags = {"idle", "canrotate", "noattack", "up"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("away_idle", true)
            inst:ShadowOff()
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle_up")
        end,
    },


    State{
        name = "down",
        tags = {"busy"},
        onenter = function(inst, playanim)
            inst:RemoveTag("noattack")
            inst:ShadownOn()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("down")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/drop")

        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst:PerformBufferedAction()
        end,
        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "move",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("walk_pre")
            inst.AnimState:PushAnimation("walk")
            inst.AnimState:PushAnimation("walk_pst", false)
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.components.locomotor:WalkForward()
            end ),
            TimeEvent(11 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/move")
            end),

            TimeEvent(29 * FRAMES, function(inst)
                inst.Physics:Stop()
            end ),
        },

        events =
        {
            EventHandler("animqueueover", function (inst)
                local should_move = inst.components.locomotor:WantsToMoveForward()
                if should_move then
                    inst.sg:GoToState("move")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/attack_pre") end),
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/attack") end),
            TimeEvent(15 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },


    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("steal")
        end,

        timeline=
        {
            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/eat_drop") end),
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/eat") end),
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/eat_up") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/eat_drop") end),
            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),

        },
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("down") end),
        },
    },


}

CommonStates.AddFrozenStates(states)

return StateGraph("grabbing_vine", states, events, "idle", actionhandlers)
