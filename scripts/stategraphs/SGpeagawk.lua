require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "gohome"),
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.PICK, "pick"),
    ActionHandler(ACTIONS.PEAGAWK_TRANSFORM, "transform")
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("transform") then
            if inst.is_bush then
                inst.sg:GoToState("transform")
            end
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst) if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("transform") then inst.sg:GoToState("attack") end end),
}

local function Gobble(inst)
    -- if not inst.SoundEmitter:PlayingSound("gobble") then
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/idle") -- , "gobble")
    -- end
end

local states =
{
    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            if not inst.is_bush then
                inst.Physics:Stop()
                Gobble(inst)
                inst.AnimState:PlayAnimation("idle_loop")
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst)
                if inst.is_bush then
                    -- print ("HEY DANY! ADD THE BLINKING SOUND HERE, DON'T FORGET TO SET THE PROPER FRAME TOO")
                end
            end),
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
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/death")
            inst.components.locomotor:StopMoving()
            inst.components.lootdropper:DropLoot()
            RemovePhysicsColliders(inst)

            if inst.is_bush then
                inst.TransformToAnimal(inst, true)
                inst.AnimState:PlayAnimation("appear")
                inst.AnimState:PushAnimation("death", false)
            else
                inst.AnimState:PlayAnimation("death")
            end
        end,

    },

    State{
        name = "transform",
        tags = {"busy"},

        onenter = function(inst)
            inst:PerformBufferedAction()
            if inst.is_bush then
                inst.sg:GoToState("transform_to_animal")
            else
                inst.sg:GoToState("transform_to_bush")
            end
        end,
    },

    State{
        name = "transform_to_animal",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.TransformToAnimal(inst)
        end,
    },

    State{
        name = "transform_to_bush",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hide_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.TransformToBush(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "appear",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move","appear")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("appear")
        end,

        timeline =
        {
            TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/appear") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge") end),
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/appear_pop") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("appear")
        end,
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/attack")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("eat")
            inst.Physics:Stop()
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("busy")
                inst.sg:AddStateTag("idle")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hit",
        tags = {"busy", "attacked"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/hurt")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    starttimeline =
    {
        TimeEvent(0 * FRAMES, Gobble),
    },

    walktimeline = {
        TimeEvent(0 * FRAMES, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
})

CommonStates.AddRunStates(
    states,
    {
        starttimeline =
        {
            TimeEvent(0 * FRAMES,
                function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/move") end),
        },

        runtimeline = {
            TimeEvent(0 * FRAMES, PlayFootstep),
            TimeEvent(5 * FRAMES,
                function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/move") end),
            TimeEvent(10 * FRAMES, PlayFootstep),
        },
    },
    nil, nil, nil,
    {
        startonenter = function(inst)
            if inst.is_bush then
                inst.sg:GoToState("transform")
            end
        end
    }
)


CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/sleep") end),
    },

    sleeptimeline = {
        TimeEvent(40 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/Peakcock/sleep") end),
    },
})

-- CommonStates.AddIdle(states, "idle")
CommonStates.AddSimpleActionState(states, "gohome", "hit", 4 * FRAMES, {"busy"})
CommonStates.AddSimpleActionState(states, "pick", "take", 9 * FRAMES, {"busy"})
CommonStates.AddFrozenStates(states)

return StateGraph("peagawk", states, events, "idle", actionhandlers)
