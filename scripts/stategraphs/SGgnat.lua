require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "land"),
    ActionHandler(ACTIONS.INFEST, "infest"),
    ActionHandler(ACTIONS.BUILD_MOUND, "land_pre"),
}

local events =
{
    EventHandler("locomote", function(inst)
        if inst.sg:HasStateTag("busy")  then
            return
        end

        local is_moving = inst.sg:HasStateTag("moving")
        local wants_to_move = inst.components.locomotor:WantsToMoveForward()
        if is_moving ~= wants_to_move then
            if wants_to_move then
                inst.sg.statemem.wantstomove = true
            else
                inst.sg:GoToState("idle")
            end
        end
    end),

    EventHandler("doattack", function(inst, data) inst.sg:GoToState("attack", data.target) end),
    EventHandler("blocked", function(inst) inst.sg:GoToState("hit") end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnFreeze(),
}

local states =
{
    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            if inst.components.locomotor:WantsToRun() then
                inst.sg:GoToState("running", true)
            else
                inst.components.locomotor:WalkForward()
                inst.AnimState:PlayAnimation("idle_loop")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/gnat/LP", "move")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State{
        name = "running",
        tags = {"moving", "canrotate"},

        onenter = function(inst, pre)
            if not inst.components.locomotor:WantsToRun() then
                inst.sg:GoToState("moving")
            else
                inst.components.locomotor:RunForward()
                if pre then
                    inst.AnimState:PlayAnimation("run_pre")
                    inst.AnimState:PushAnimation("run_loop")
                else
                    inst.AnimState:PlayAnimation("run_loop")
                end
            end
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("running") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
            inst.SoundEmitter:KillSound("move")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/gnat/death")
        end,
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.wantstomove then
                    inst.sg:GoToState("moving")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "spawn",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("spawn")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/gnat/hit")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "takeoff",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("sleep_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "infest",
        tags = {"busy"},

        onenter = function(inst)
            if inst.chasing_target_task then
                inst.chasing_target_task:Cancel()
                inst.chasing_target_task = nil
            end
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack_pre")
            inst.AnimState:PushAnimation("attack_pst", false)
            inst:PerformBufferedAction()
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/gnat/attack") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "attack",
        tags = {"busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            inst.AnimState:PlayAnimation("attack_pre")
            inst.AnimState:PushAnimation("attack_pst", false)

            inst.sg.statemem.target = target
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),

            TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/gnat/attack") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "land_pre",
        tags = {"busy", "landing"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("sleep_pre")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("land")
            end),
        },
    },

    State{
        name = "land",
        tags = {"busy", "landing"},

        onenter = function(inst)
            inst:PerformBufferedAction()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("sleep_loop", true)
        end,

        events =
        {
            EventHandler("takeoff", function(inst)
                inst.sg:GoToState("takeoff")
            end),
        },
    },
}

CommonStates.AddFrozenStates(states)

return StateGraph("gnat", states, events, "spawn", actionhandlers)
