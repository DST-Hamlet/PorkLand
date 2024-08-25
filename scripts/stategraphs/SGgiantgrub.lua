require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),

    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            if inst.State == "above" then
                inst.sg:GoToState("attack", data.target)
            else
                inst.sg:GoToState("enter", "attack")
            end
        end
    end),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end

        if inst.components.locomotor:WantsToMoveForward() then
            if inst.State == "under" then
                if not inst.sg:HasStateTag("moving") then
                    inst.sg:GoToState("walk_pre")
                end
            else
                inst.sg:GoToState("exit")
            end
        elseif inst.sg:HasStateTag("moving") then
            inst.sg:GoToState("walk_pst")
        else
            inst.sg:GoToState("idle")
        end
    end),
}

local states =
{
    State{
        name = "enter",
        tags = {"busy"},

        onenter = function(inst, nextState)
            inst.attackUponSurfacing = (nextState == "attack")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("enter")
            inst:SetState("above")
            inst.SoundEmitter:KillSound("move")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local nextState = "idle"

                if inst.attackUponSurfacing then
                    nextState = "attack"
                end

                inst.sg:GoToState(nextState)
            end)
        },

        timeline =
        {
            TimeEvent(16* FRAMES,function (inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/emerge") end),
        },
    },

    State{
        name = "exit",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("exit")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:SetState("under")
                inst.last_above_time = GetTime()
                inst.sg:GoToState("idle")
            end)
        },

        timeline =
        {

            TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/jump") end),
            TimeEvent(22 * FRAMES, function(inst) inst.components.groundpounder:GroundPound() end),
            TimeEvent(20 * FRAMES, function(inst)
                if inst.components.burnable:IsBurning() then
                    inst.components.burnable:Extinguish()
                end
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/submerge")
            end),
            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/dig") end),
            TimeEvent(39 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/dig") end),
            TimeEvent(49 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/dig") end),
            TimeEvent(54 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/dig") end),
        },
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("move")

            if playanim then
                inst.AnimState:PlayAnimation(playanim)

                if inst.State == "above" then
                    inst.AnimState:PushAnimation("idle", true)
                elseif inst.State == "under" then
                    inst.AnimState:PushAnimation("idle_under", true)
                end
            else
                if inst.State == "above" then
                    inst.AnimState:PlayAnimation("idle", true)
                elseif inst.State == "under" then
                    inst.AnimState:PlayAnimation("idle_under", true)
                end
            end
        end,
    },

    State{
        name = "walk_pre",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
            if not inst.SoundEmitter:PlayingSound("move") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/walk_LP", "move")
            end
            inst.components.locomotor:WalkForward()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
        }
    },

    State{
        name = "walk",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
        end,
    },

    State{
        name = "walk_pst",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
            inst.SoundEmitter:KillSound("move")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        }
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("action")
        end,

        timeline =
        {
            TimeEvent(2  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/attack") end),
            TimeEvent(10 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events =
        {
            EventHandler("animover", function(inst, data) inst.sg:GoToState("idle") end),
        }
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "sleep",
        tags = {"busy", "sleeping"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if inst.State == "under" then
                inst.AnimState:PlayAnimation("enter")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/emerge")
                inst.AnimState:PushAnimation("sleep_pre", false)
            else
                inst.AnimState:PlayAnimation("sleep_pre")
            end
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("sleeping") end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst:SetState("above")
                inst.SoundEmitter:KillSound("sniff")
                inst.SoundEmitter:KillSound("stunned")
            end)
        }
    },

    State{
        name = "sleeping",
        tags = {"busy", "sleeping"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("sleeping") end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },

       timeline =
        {

            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/sleep_in") end),
            TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/sleep_in") end),
        },
    },

    State{
        name = "wake",
        tags = {"busy", "waking"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:KillSound("sleep")
            end)
        },
    },

    State{
        name = "death",
        tags = {"busy", "stunned"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/giant_grub/death") end),
        }
    },
}

CommonStates.AddFrozenStates(states)

return StateGraph("giantgrub", states, events, "idle", actionhandlers)
