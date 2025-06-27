require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.GOHOME, "action"),
}

local events = {
    EventHandler("cocoon", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.wantstococoon = false
            inst.sg:GoToState("cocoon_pre")
        end
    end),

    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("moving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),

    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
}

local states = {
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            if inst.components.lootdropper ~= nil then
                inst.components.lootdropper:DropLoot()
            end
        end,

        timeline =
        {
            TimeEvent(23 * FRAMES, function(inst) PL_LandFlyingCreature(inst) end),
        },
    },

    State{
        name = "action",

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
            inst:PerformBufferedAction()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", false)
        end,

        timeline = {
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/glowfly/buzz") end),
            TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/glowfly/buzz") end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/glowfly/buzz") end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("moving")
            end),
        }
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("walk_loop", false)
        end,

        timeline = {
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/glowfly/buzz") end),
            TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/glowfly/buzz") end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/glowfly/buzz") end),
        },

        events = {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },


    State{
        name = "cocoon_pre",
        tags = {"cocoon", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("cocoon_idle_pre")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
                PL_LandFlyingCreature(inst)
            end)
        },

        events = {
            EventHandler("animover", function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local rotation = inst.Transform:GetRotation()
                inst:Remove()
                local cocoon = SpawnPrefab("glowfly_cocoon")
                cocoon.Transform:SetRotation(rotation)
                cocoon.Transform:SetPosition(x, y, z)
            end),
        },

        onexit = PL_RaiseFlyingCreature,
    },
}


CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(24 * FRAMES, PL_LandFlyingCreature),
    },
    waketimeline =
    {
        TimeEvent(19 * FRAMES, PL_RaiseFlyingCreature),
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

CommonStates.AddFrozenStates(states, PL_LandFlyingCreature, PL_RaiseFlyingCreature)

return StateGraph("glowfly", states, events, "idle", actionhandlers)
