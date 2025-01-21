require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnDeath(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    EventHandler("doattack", function (inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead()
            and not inst.sg:HasStateTag("busy") then

            inst.sg:GoToState("attack")
        end
    end),
    EventHandler("newcombattarget", function(inst, data)
        if inst.sg:HasStateTag("idle") and data.target
            and not inst.sg:HasStateTag("busy") then

            inst.sg:GoToState("attack")
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            if inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.AnimState:PushAnimation("idle")
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/breath_out") end),
            TimeEvent(35 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/breath_in") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "taunt",
        tags = {"taunting", "busy", "caninterrupt"},

        onenter = function(inst)
            if inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/taunt") end),
        },

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

        onenter = function(inst, target)
            if target then
                inst:ForceFacePoint(target:GetPosition())
            end
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
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
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/attack_pre") end),
            TimeEvent(14 * FRAMES, function(inst)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/attack")
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                if inst.components.combat.target then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("taunt")
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/death_pre", nil, 0.5) end),
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/death") end),
        },

        events =
        {

        },
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/breath_out")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack") end),
        },
    },

    State{
        name = "grow",
        tags = {"busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/breath_out")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/death_pre")
            inst.AnimState:PlayAnimation("transform_pre")
        end,

        timeline =
        {
            TimeEvent(5  * FRAMES, function(inst)  inst.Transform:SetScale(inst.start_scale + (inst.inc_scale*1), inst.start_scale + (inst.inc_scale*1), inst.start_scale + (inst.inc_scale*1)) end),
            TimeEvent(10 * FRAMES, function(inst)  inst.Transform:SetScale(inst.start_scale + (inst.inc_scale*2), inst.start_scale + (inst.inc_scale*2), inst.start_scale + (inst.inc_scale*2)) end),
            TimeEvent(15 * FRAMES, function(inst)  inst.Transform:SetScale(inst.start_scale + (inst.inc_scale*3), inst.start_scale + (inst.inc_scale*3), inst.start_scale + (inst.inc_scale*3)) end),
            TimeEvent(20 * FRAMES, function(inst)  inst.Transform:SetScale(inst.start_scale + (inst.inc_scale*4), inst.start_scale + (inst.inc_scale*4), inst.start_scale + (inst.inc_scale*4)) end),
            TimeEvent(25 * FRAMES, function(inst)  inst.Transform:SetScale(inst.start_scale + (inst.inc_scale*5), inst.start_scale + (inst.inc_scale*5), inst.start_scale + (inst.inc_scale*5)) end),
        },

        onexit = function(inst)
            inst.Transform:SetScale(inst.start_scale + (inst.inc_scale*5), inst.start_scale + (inst.inc_scale*5), inst.start_scale + (inst.inc_scale*5))
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("grow_pst") end),
        },
    },

    State{
        name = "grow_pst",
        tags = {"busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("transform_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddFrozenStates(states)

return StateGraph("adult_flytrap", states, events, "idle")
