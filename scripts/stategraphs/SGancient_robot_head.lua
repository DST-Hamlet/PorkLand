require("stategraphs/commonstates")
local AncientRobot = require("stategraphs/SGancient_robot")
local AncientHulkUtil = require("prefabs/ancient_hulk_util")

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

AncientRobot.States.AddIdle(states, false)
AncientRobot.States.AddCommonStates(states)
AncientRobot.States.AddActivate(states, {
    TimeEvent(0 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/start")
    end),
    TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(5  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/active") end),
    TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(27 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(40 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(54 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(57 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
})
AncientRobot.States.AddDeactivate(states, {
    TimeEvent(5  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green") end),
    TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green") end),
    TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green") end),
    TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green") end),
    TimeEvent(38 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/green") end),
}, "dontstarve_DLC003/creatures/enemy/metal_robot/head/stop")
AncientRobot.States.AddTaunt(states, {
    TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
    TimeEvent(2  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/taunt") end),
    TimeEvent(12 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", .05)
    end),
    TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
    TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/taunt") end),
    TimeEvent(24 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step","steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", 0.08)
    end),
    TimeEvent(32 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
})
AncientRobot.States.AddLocomoteStates(states, {
    TimeEvent(0 * FRAMES, function(inst)
        inst.Physics:Stop()
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
},
{
    TimeEvent(0 * FRAMES, function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:WalkForward()
    end),
    TimeEvent(1 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(17 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
    end),
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end),
},
{
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end),
})
AncientRobot.States.AddLeap(states, {
    TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
    TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
},
{
    TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
    TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/attack") end),
    TimeEvent(25 * FRAMES, PowerGlow),
},
{
    TimeEvent(5  * FRAMES, function(inst) DoDamage (inst, 1.5) end),
    TimeEvent(10 * FRAMES, function(inst) DoDamage (inst, 2.5) end),
    TimeEvent(15 * FRAMES, function(inst) DoDamage (inst, 3.3) end),

    TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash") end),
    TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/servo") end),
    TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step") end),
    TimeEvent(31 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/head/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", 0.08)
    end),
})

return StateGraph("ancient_robot_head", states, events, "idle", actionhandlers)
