require("stategraphs/commonstates")
local AncientRobot = require("stategraphs/SGancient_robot")

local actionhandlers =
{
    AncientRobot.ActionHandlers.ASSEMBLE_ROBOT(),
}

local events =
{
    AncientRobot.Events.OnStep(),
    AncientRobot.Events.OnLocomote(),
    AncientRobot.Events.DoBeamAttack(),
    AncientRobot.Events.OnAttacked(),
    AncientRobot.Events.OnShocked(),
    AncientRobot.Events.OnActivate(),
    AncientRobot.Events.OnDeactivate(),
}

local states = {}

AncientRobot.States.AddIdle(states, false)
AncientRobot.States.AddCommonStates(states)
AncientRobot.States.AddActivate(states, {
    TimeEvent(3 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/start")
    end),
    TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") end),
    TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") end),
    TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") end),
    TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") end),
    TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/active") end),
    TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(50 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(51 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(53 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(62 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(70 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
})
AncientRobot.States.AddDeactivate(states, {
    TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green") end),
    TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green") end),
    TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green") end),
    TimeEvent(38 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/green") end),
    TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
}, "dontstarve_DLC003/creatures/enemy/metal_robot/arm/stop")
AncientRobot.States.AddTaunt(states, {
    TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/taunt") end),
    TimeEvent(29 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
})
AncientRobot.States.AddLocomoteStates(states, {
    TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end),
},
{
    TimeEvent(0 * FRAMES, function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:WalkForward()
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/drag")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(6 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
    end),
    TimeEvent(14 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(25 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
    end),
    TimeEvent(28 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end),
},
{
    TimeEvent(33 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo")
    end),
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end ),
})
AncientRobot.States.AddLaserBeam(states, {
    TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(7  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser_pre") end),
    TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/servo") end),
    TimeEvent(30 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.12)
    end),
    TimeEvent(32 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.24)
    end),
    TimeEvent(34 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.48)
    end),
    TimeEvent(36 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.60)
    end),
    TimeEvent(38 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.72)
    end),
    TimeEvent(40 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.84)
    end),
    TimeEvent(42 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.96)
    end),
    TimeEvent(44 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 1)
    end),
    TimeEvent(47 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/arm/step") end),
}, true)

return StateGraph("ancient_robot_claw", states, events, "idle", actionhandlers)
