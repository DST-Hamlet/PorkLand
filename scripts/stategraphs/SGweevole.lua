require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "burrow"),
    ActionHandler(ACTIONS.EAT, "eat"),
    -- ActionHandler(ACTIONS.BUILDHOME, "buildhome"),
}

local events =
{
    EventHandler("entershield", function(inst, data)
        if not inst:GetCurrentPlatform() then
            inst.sg:GoToState("burrow_shield")
        end
    end),
    EventHandler("exitshield", function(inst, data)
        inst.sg:GoToState("emerge")
    end),
    EventHandler("fly_in", function(inst, data)
        inst.sg:GoToState("enter_loop")
    end),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            if not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("shielding") then -- don't interrupt attack
                inst.sg:GoToState("hit") -- can still attack
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState(
                data.target:IsValid()
                and not inst:IsNear(data.target, TUNING.WEEVOLE_MELEE_RANGE)
                and "leap_attack" -- Do leap attack
                or "attack",
                data.target
            )
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnHop(),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                inst.sg:GoToState(wants_to_move and "premoving" or "idle")
            end
        end
    end),

    EventHandler("trapped", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("trapped")
        end
    end),
}

local states =
{
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/death")
            inst.AnimState:PlayAnimation("death")
            inst.AnimState:PushAnimation("dead")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,
    },

    State{
        name = "premoving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/walk") end),
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/walk") end),
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/walk") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        -- ontimeout = function(inst)
        --    inst.sg:GoToState("taunt")
        -- end,

        timeline =
        {

            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/idle") end),
        },

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            -- if math.random() < .3 then
            --     inst.sg:SetTimeout(math.random() * 2 + 2)
            -- end

            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle")
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < 0.01 then
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },


    State{
        name = "burrow_shield",
        tags = {"busy","shielding"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("burrow")
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
                inst.sg:AddStateTag("invisible")
                if inst.components.burnable:IsBurning() then
                    inst.components.burnable:Extinguish()
                end
            end),
        },
    },

    State{
        name = "burrow",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("burrow")
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/burrow", "move")
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
                inst.sg:AddStateTag("invisible")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst:PerformBufferedAction()
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("move")
        end,
    },

    State{
        name = "emerge",
        tags = {"busy", "invisible"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/burrow", "move")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("unburrow")
            inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(.9, .2))

            if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("move")
            inst.AnimState:SetDeltaTimeMultiplier(1)
            inst.DynamicShadow:Enable(true)
        end,

        timeline =
        {
            TimeEvent(0, function(inst)
                if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
            end),
            TimeEvent(32 * FRAMES, function(inst) inst.DynamicShadow:Enable(true) end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")

            if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end

        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/taunt") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "enter_loop",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()

            inst.AnimState:PlayAnimation("fly", true)

            inst.DynamicShadow:Enable(false)
            inst.components.health:SetInvincible(true)
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x,15,z)
        end,

        onexit = function(inst)
            if not inst.sg.statemem.onground then
                local x, y, z = inst.Transform:GetWorldPosition()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.DynamicShadow:Enable(true)
                inst.components.health:SetInvincible(false)
            end
        end,

        onupdate = function(inst)

            inst.Physics:SetMotorVel(0 , -10 + math.random() * 2, 0)
            local x, y, z = inst.Transform:GetWorldPosition()

            if y <= .1 or inst:IsAsleep() then
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.DynamicShadow:Enable(true)
                inst.components.health:SetInvincible(false)
                inst.sg.statemem.onground = true
                inst.sg:GoToState("enter_pst")
            end
        end,
    },

    State{
        name = "enter_pst",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("land")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
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
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1 + math.random() * 1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },


    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("attack")
            inst.sg.statemem.target = target
        end,

        timeline =
        {
            TimeEvent(25 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/attack") end),

        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "leap_attack",
        tags = {"attack", "canrotate", "busy", "jumping"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("leap_attack")
            inst.sg.statemem.target = target

            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target:GetPosition())
            end
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("buzz")
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/fly_LP", "buzz")
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("buzz")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/idle")
            end),

            TimeEvent(11 * FRAMES, function(inst)
                inst.Physics:SetMotorVelOverride(20,0,0)
            end),
            TimeEvent(18 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
            TimeEvent(19 * FRAMES, function(inst)
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "buildhome",
        tags = {"busy", "jumping"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("tree_attack")
            inst.AnimState:PushAnimation("taunt", false)
        end,

        -- onexit = function(inst)
            -- inst:ClearBufferedAction()
        -- end,

        timeline =
        {
            TimeEvent(27 * FRAMES, function(inst) inst:PerformBufferedAction() inst:ClearBufferedAction() end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddFrozenStates(states)
CommonStates.AddHopStates(states, true)
CommonStates.AddSinkAndWashAsoreStates(states)

-- make the pst animation play normally
for _, state in pairs(states) do
    if state.name == "hop_pst" then
        state.onenter = function(inst, data)
            inst.AnimState:PlayAnimation("jump_pst", false)
            inst.sg.statemem.nextstate = "hop_pst_complete"
        end

        for _, event in pairs(state.events) do
            if event.name == "animover" then
                event.fn = function(inst)
                    inst.components.embarker:Embark()
                    inst.sg:GoToState(inst.sg.statemem.nextstate)
                end
            end
        end
    end
end

return StateGraph("weevole", states, events, "emerge", actionhandlers)
