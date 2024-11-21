require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.EAT, "eat_loop"),
    ActionHandler(ACTIONS.PICKUP, "eat_enter"),
    ActionHandler(ACTIONS.VAMPIREBAT_FLYAWAY, "flyaway"),
}

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttackWithTarget(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("fly_loop", true)
            else
                inst.AnimState:PlayAnimation("fly_loop", true)
            end
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(13 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "action",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("fly_loop", true)
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
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/taunt") end),
            TimeEvent(3 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(14 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(24 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(41 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "eat_enter",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat", false)
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(8 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/bite")
                PL_LandFlyingCreature(inst)
            end), --take food
            TimeEvent(10 * FRAMES, function(inst) PL_RaiseFlyingCreature(inst) end),
            TimeEvent(14 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1 + math.random() * 2)
        end,

        ontimeout= function(inst)
            inst.lastmeal = GetTime()
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle")
        end,

        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst) inst:PushEvent("wingdown")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/chew") end),
            TimeEvent(13 * FRAMES, function(inst) inst:PushEvent("wingdown")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/chew") end),
        },

        events =
        {
            EventHandler("attacked", function(inst)
                inst.components.inventory:DropEverything() -- drop food
                inst.sg:GoToState("idle")
            end)
        },
    },

    State{
        name = "glide",
        tags = {"idle", "flight", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.DynamicShadow:Enable(false)
            inst.AnimState:PlayAnimation("glide", true)
            inst.Physics:SetMotorVelOverride(0, -25,0)
        end,

        onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y <= 0.1 or inst:IsAsleep() then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.DynamicShadow:Enable(true)

                inst.sg:GoToState("land")
            end
        end,

        onexit = function(inst)
            inst.Physics:Stop()
            inst.Physics:ClearMotorVelOverride()
            inst.DynamicShadow:Enable(true)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
        end,
    },

    State{
        name = "land",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("land", false)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/land")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "flyaway",
        tags = {"flight", "busy"},

        onenter = function(inst)
            local bat_cave = TheWorld.components.interiorspawner:GetExteriorById(inst._target_exterior)
            if bat_cave ~= nil then
                local outside_pos = bat_cave:GetPosition() + Vector3(bat_cave:GetPhysicsRadius(1), 0, 0)
                inst.Transform:SetPosition(outside_pos.x, 0, outside_pos.z)
            end

            inst.Physics:Stop()

            inst.DynamicShadow:Enable(false)
            inst.components.health:SetInvincible(true)

            inst.AnimState:PlayAnimation("fly_away_pre")
            inst.AnimState:PushAnimation("fly_away_loop", true)

            inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
        end,

        timeline =
        {
            TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
            TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
            TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
            TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
            TimeEvent(51 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
    },

    State{
        name = "flyout",
        tags = {"busy", "noattack", "nointerrupt"},

        onenter = function(inst, offset)
            inst.AnimState:PlayAnimation("flyout", false)
            inst.AnimState:SetFloatParams(0.25, 1.0, 0)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_taunt")
            inst.sg.statemem.offset = offset or Vector3(0, 0, 0)
        end,

        timeline =
        {
            TimeEvent(44 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(54 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(56 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(64 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(74 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(76 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(84 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(94 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(96 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(104 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(114 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(116 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(120 * FRAMES, function(inst) inst.sg.statemem.can_down = true end),
            TimeEvent(124 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(124 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(136 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(144 * FRAMES, function(inst) inst:PushEvent("wingdown")
                inst.sg:RemoveStateTag("noattack")
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nointerrupt") end),
            TimeEvent(154 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(156 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
            TimeEvent(164 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(174 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            TimeEvent(176 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
        },

        onupdate = function(inst, dt)
            if inst.sg.statemem.can_down then
                local offset = inst.sg.statemem.offset
                local x, y, z = inst.Transform:GetWorldPosition()
                inst.Transform:SetPosition(x + offset.x * dt * 0.5, y, z + offset.z * dt * 0.5)
            end
        end,

        onexit = function(inst)
            inst.AnimState:SetFloatParams(0, 0, 0)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end)
        },
    },
}

local walkanims =
{
    startwalk = "fly_loop",
    walk = "fly_loop",
    stopwalk = "fly_loop",
}

CommonStates.AddWalkStates(states, {
    starttimeline =
    {
        TimeEvent(7 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
        TimeEvent(17 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
    },

    walktimeline =
    {
        TimeEvent(7 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
        TimeEvent(17 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
    },

    endtimeline =
    {
        TimeEvent(7 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
        TimeEvent(17 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
    },

}, walkanims, true)

CommonStates.AddSleepStates(states, {
    starttimeline =
    {
        TimeEvent(7 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/breathe_out") end),
        TimeEvent(17 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
    },

    sleeptimeline =
    {
        TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/sleep") end),
    },

    endtimeline =
    {
        TimeEvent(12 * FRAMES, function(inst) PL_RaiseFlyingCreature(inst) end),
        TimeEvent(13 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
    },
})

CommonStates.AddExtraStateFn(states, "sleep",
{
    onexit = PL_RaiseFlyingCreature
})

CommonStates.AddExtraStateFn(states, "sleeping",
{
    onenter = PL_LandFlyingCreature,
    onexit = PL_RaiseFlyingCreature
})

CommonStates.AddExtraStateFn(states, "wake",
{
    onenter = PL_LandFlyingCreature,
    onexit = PL_RaiseFlyingCreature
})

CommonStates.AddCombatStates(states, {
    attacktimeline =
    {
        TimeEvent(7 * FRAMES, function(inst)
            inst:PushEvent("wingdown")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/bite")
        end),
        TimeEvent(14 * FRAMES, function(inst)
            inst.components.combat:DoAttack(inst.sg.statemem.target)
            inst:PushEvent("wingdown")
        end),
    },

    hittimeline =
    {
        TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/hit") end),
        TimeEvent(3 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
    },

    deathtimeline =
    {
        TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/death") end),
        TimeEvent(4 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        TimeEvent(17 * FRAMES, function(inst) PL_LandFlyingCreature(inst) end),
    },
})

CommonStates.AddFrozenStates(states, PL_LandFlyingCreature, PL_RaiseFlyingCreature)

return StateGraph("vampirebat", states, events, "idle", actionhandlers)
