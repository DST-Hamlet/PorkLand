require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.HARVEST, "eat"),
}

local events =
{
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnLocomote(true, false),
    CommonHandlers.OnSleep(),

    CommonHandlers.OnExitWater(),
    CommonHandlers.OnEnterWater(),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/idle")
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
            inst.sg:SetTimeout(2 * math.random() + 0.5)
        end,
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/pre-attack")
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.AnimState:PushAnimation("atk_pst", false)
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),

            TimeEvent(14 * FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
                inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/attack")
            end),

            TimeEvent(20 * FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),

            TimeEvent(27 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre") -- ziwbi: add an eating animation like what hounds got?
            inst.AnimState:PushAnimation("atk", false)
            inst.AnimState:PushAnimation("atk_pst", false)
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/attack") end),
            TimeEvent(24 * FRAMES, function(inst) if inst:PerformBufferedAction() then inst.components.combat:SetTarget(nil) end end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/hurt")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/taunt") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,
    },

    State{
        name = "fall",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0, -20 + math.random() * 10, 0)
            inst.AnimState:PlayAnimation("idle", true)
        end,

        onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 2 then
                inst.Physics:SetMotorVel(0, 0, 0)
            end

            if y <= 0.1 then
                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(x, 0, z)
                inst.SoundEmitter:PlaySound("dontstarve/frog/splat")
                inst.sg:GoToState("idle")
            end
        end,

        onexit = function(inst)
            local x, _, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, 0, z)
        end,
    },

    State{
        name = "emerge",
        tags = {"canrotate", "busy"},

        onenter = function(inst, noanim)
            if noanim then
                inst.AnimState:SetBank("snake")
                inst.sg:GoToState("taunt") -- Default State.
                return
            end

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("snake_water")
            inst.AnimState:PlayAnimation("emerge")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.AnimState:SetBank("snake")
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "submerge",
        tags = {"canrotate", "busy"},

        onenter = function(inst, noanim)
            if noanim then
                inst.AnimState:SetBank("snake_water")
                inst.sg:GoToState("taunt") -- Default State.
                return
            end

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("snake_water")
            inst.AnimState:PlayAnimation("submerge")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddSleepStates(states,
{
    sleeptimeline = {
        TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/sleep") end),
    },
})

CommonStates.AddRunStates(states,
{
    runtimeline = {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/move") end),
        TimeEvent(4 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/move") end),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("snake", states, events, "taunt", actionhandlers)
