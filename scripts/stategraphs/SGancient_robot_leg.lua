require("stategraphs/commonstates")
local AncientRobot = require("stategraphs/SGancient_robot")
local AncientHulkUtil = require("prefabs/ancient_hulk_util")

local SHAKE_DIST = 40

local DoDamage = AncientHulkUtil.DoDamage
local PowerGlow = AncientHulkUtil.powerglow

local actionhandlers =
{
    AncientRobot.ActionHandlers.ASSEMBLE_ROBOT(),
}

local events =
{
    AncientRobot.Events.OnStep(),
    AncientRobot.Events.OnLocomote(),
    AncientRobot.Events.DoLeapAttack(),
    AncientRobot.Events.OnAttacked(),
    AncientRobot.Events.OnShocked(),
    AncientRobot.Events.OnActivate(),
    AncientRobot.Events.OnDeactivate(),
}

local states = {}
AncientRobot.States.AddIdle(states, true)
AncientRobot.States.AddCommonStates(states)
AncientRobot.States.AddActivate(states, {
    TimeEvent(0 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/start")
    end),
    TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active") end),
    TimeEvent(5  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active") end),
    TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/active") end),
    TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(27 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(44 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(58 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", nil, 0.06) end),
})
AncientRobot.States.AddDeactivate(states, {
    TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green") end),
    TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green") end),
    TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green") end),
    TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green") end),
    TimeEvent(31 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/green") end),
    TimeEvent(43 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step") end),
}, "dontstarve_DLC003/creatures/enemy/metal_robot/leg/stop")
AncientRobot.States.AddTaunt(states, {
    TimeEvent(5  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(42 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/taunt") end),
    TimeEvent(23 * FRAMES, function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local fx = SpawnPrefab("lightning")
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end
        ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 0.5, inst, SHAKE_DIST)
    end),
})
AncientRobot.States.AddLocomoteStates(states, {
    TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end),
},
{
    TimeEvent(0 * FRAMES, function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:WalkForward()
    end ),
    TimeEvent(5 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo", nil, 0.8)
    end),
    TimeEvent(14 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
    end),
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end ),
},
{
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end),
})
AncientRobot.States.AddLeap(states, {
    TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
},
{
    TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(25 * FRAMES, PowerGlow),
},
{
    TimeEvent(5  * FRAMES, function(inst) DoDamage (inst, 1.5) end),
    TimeEvent(10 * FRAMES, function(inst) DoDamage (inst, 2.5) end),
    TimeEvent(15 * FRAMES, function(inst) DoDamage (inst, 3.3) end),

    TimeEvent(2  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash") end),
    TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
    TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", nil, 0.06) end),
    TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
})

return StateGraph("ancient_robot_leg", states, events, "idle", actionhandlers)
