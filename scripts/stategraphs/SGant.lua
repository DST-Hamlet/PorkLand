require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "gohome"),
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.CHOP, "chop"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
    ActionHandler(ACTIONS.EQUIP, "pickup"),
    ActionHandler(ACTIONS.ADDFUEL, "pickup"),
    ActionHandler(ACTIONS.TAKEITEM, "pickup"),
    ActionHandler(ACTIONS.UNPIN, "pickup"),

}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(TUNING.CHARACTER_HITREACT_COOLDOWN, TUNING.CHARACTER_MAX_STUN_LOCKS),
    CommonHandlers.OnDeath(),

    EventHandler("doaction", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            if data.action == ACTIONS.CHOP then
                inst.sg:GoToState("chop", data.target)
            end
        end
    end),
}

local states =
{
    State{
        name = "funnyidle",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/hunger")

            if inst.components.follower.leader and inst.components.follower:GetLoyaltyPercent() < 0.05 then
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")
            elseif inst:HasTag("guard") then
                inst.AnimState:PlayAnimation("idle_angry")
            else
                if inst.components.combat.target then
                    inst.AnimState:PlayAnimation("idle_angry")
                elseif inst.components.follower.leader and inst.components.follower:GetLoyaltyPercent() > 0.3 then
                    inst.AnimState:PlayAnimation("idle_creepy")
                else
                    inst.AnimState:PlayAnimation("alert")
                end
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "alert",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/alert_LP", "alert")
            inst:DoTaskInTime(2.5, function() inst.SoundEmitter:KillSound("alert") end)

            local player = inst.facing_target
            if player and IsPlayerInAntDisguise(player) then
                inst.AnimState:PlayAnimation("alert", true)
            else
                inst.AnimState:PlayAnimation("idle_angry", true)
            end
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("alert")
        end
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,
    },

    State{
        name = "abandon",
        tags = {"busy"},

        onenter = function(inst, leader)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("abandon")
            inst:FacePoint(Vector3(leader.Transform:GetWorldPosition()))
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/attack")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst.components.combat:DoAttack() inst.sg:RemoveStateTag("attack") inst.sg:RemoveStateTag("busy") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "chop",
        tags = {"chopping"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/eat")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "transform",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eggify")
            local egg = ReplacePrefab(inst, "antman_warrior_egg")
            egg:eggify(inst.components.homeseeker and inst.components.homeseeker:GetHome())
            egg:AddTag("aporkalypse_cleanup")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },
}

CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(0  * FRAMES, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
})

CommonStates.AddRunStates(states, {
    runtimeline = {
        TimeEvent(0  * FRAMES, PlayFootstep),
        TimeEvent(10 * FRAMES, PlayFootstep),
    },
})

CommonStates.AddSleepStates(states, {
    sleeptimeline =
    {
        TimeEvent(35 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/crickant/sleep") end),
    },
})

CommonStates.AddIdle(states, "funnyidle")
CommonStates.AddSimpleState(states, "refuse", "pig_reject", {"busy"})
CommonStates.AddFrozenStates(states)

CommonStates.AddSimpleActionState(states, "gohome", "pig_pickup", 4  * FRAMES, {"busy"})
CommonStates.AddSimpleActionState(states, "pickup", "pig_pickup", 10 * FRAMES, {"busy"})

return StateGraph("ant", states, events, "idle", actionhandlers)
