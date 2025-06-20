require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.GOHOME, "eat"),
}

local events =
{
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("no_stun") then
            inst.sg:GoToState("evade")  -- can't attack during hit reaction
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("evade")  and data and data.target  then
            if math.random() < 0.4 then
                inst.sg:GoToState("tail_attack", data.target)
            else
                inst.sg:GoToState("attack", data.target)
            end
        end
    end),

    EventHandler("exitshield", function(inst)
        inst.sg:GoToState("shield_end")
    end),

    EventHandler("locomote", function(inst)
        if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("evade") then
            return
        end

        local is_moving = inst.sg:HasStateTag("moving")
        local wants_to_move = inst.components.locomotor:WantsToMoveForward()
        if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
            if wants_to_move then
                inst.sg:GoToState("premoving")
            else
                inst.sg:GoToState("idle")
            end
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        ontimeout = function(inst)
            inst.sg:GoToState("taunt")
        end,

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            if math.random() < 0.3 then
                inst.sg:SetTimeout(math.random() * 2 + 2)
            end

            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,
    },

    State{
        name = "premoving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/walk") end),
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/mumble") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("moving")
            end),
        },
    },

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,

        timeline =
        {
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/walk") end),
            TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/walk") end),
            TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/mumble") end),
            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/walk") end),
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/walk") end),
            TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/walk") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("moving")
            end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst:PerformBufferedAction() then
                    inst.sg:GoToState("eat_loop")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "born",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1 + math.random())
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/taunt")
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
        tags = {"attack", "busy", "no_stun"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,

        timeline =
        {
            TimeEvent(5  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/claw") end),
            TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/claw") end),
            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/claw") end),
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/claw") end),
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/claw") end),
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/attack_grunt") end),
            TimeEvent(25 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "tail_attack",
        tags = {"attack", "busy", "no_stun"},

        onenter = function(inst, target)
            inst.components.combat.poisonous = true
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("tail")
            inst.sg.statemem.target = target
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/attack_grunt") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/tail_attack") end),
            TimeEvent(20 * FRAMES, function(inst)
                inst.components.combat:SetRange(TUNING.SCORPION_STING_RANGE, TUNING.SCORPION_STING_RANGE)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.components.combat:SetRange(TUNING.SCORPION_ATTACK_RANGE, TUNING.SCORPION_ATTACK_RANGE)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.components.combat.poisonous = false
        end,
    },

    State{
        name = "leap_attack",
        tags = {"attack", "canrotate", "busy", "jumping"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        end,

        timeline =
        {
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/attack_grunt") end),
            TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/Jump") end),
            TimeEvent(8  * FRAMES, function(inst) inst.Physics:SetMotorVelOverride(20, 0, 0) end),
            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/tail_attack_pre") end),
            TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/scorpion/tail_attack") end),
            TimeEvent(19 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(20 * FRAMES, function(inst)
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:Stop()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "spitter_attack",
        tags = {"attack", "canrotate", "busy", "spitting"},

        onenter = function(inst, target)
            if inst.weapon and inst.components.inventory then
                inst.components.inventory:Equip(inst.weapon)
            end
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("spit")
        end,

        onexit = function(inst)
            if inst.components.inventory then
                inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
            end
        end,

        timeline =
        {
            TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spit_web") end),
            TimeEvent(21 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "hit",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit_stunlock",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/hit_response")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst.sg:GoToState("evade")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "evade",
        tags = {"busy", "evade", "no_stun"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("evade")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("evade_loop")
            end),
        },
    },

    State{
        name = "evade_loop",
        tags = {"busy", "evade", "no_stun"},

        onenter = function(inst)
            inst.sg:SetTimeout(0.1)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("evade_loop", true)
            inst.Physics:SetMotorVelOverride(-20, 0, 0)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("evade_pst")
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
        end,
    },

    State{
        name = "evade_pst",
        tags = {"busy", "evade", "no_stun"},

        onenter = function(inst)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("evade_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    local JUMP_DISTANCE = 3
                    local distance_square = inst:GetDistanceSqToInst(inst.components.combat.target)
                    if distance_square > JUMP_DISTANCE * JUMP_DISTANCE then
                        inst.sg:GoToState("leap_attack", inst.components.combat.target)
                    else
                        if math.random() < 0.3 then
                            inst.sg:GoToState("tail_attack", inst.components.combat.target)
                        else
                            inst.sg:GoToState("attack", inst.components.combat.target)
                        end
                    end
                else
                    inst.sg:GoToState("idle")
                end

            end ),
        },

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
        end,
    },

    State{
        name = "fall",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.sg.statemem.speed = -20 + math.random() * 10
            inst.Physics:SetMotorVel(0, inst.sg.statemem.speed, 0)
            inst.AnimState:PlayAnimation("idle", true)
        end,

        onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Physics:SetMotorVel(0, inst.sg.statemem.speed, 0)

            if y <= 0.1 then
                y = 0
                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(x, y, z)
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
        name = "dropper_enter",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("enter")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/descend")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("taunt")
            end),
        },
    },

}

CommonStates.AddSleepStates(states, {
    starttimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/fallAsleep") end),
    },

    sleeptimeline =
    {
        TimeEvent(35 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/sleeping") end),
    },

    waketimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/wakeUp") end),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("scorpion", states, events, "idle", actionhandlers)
