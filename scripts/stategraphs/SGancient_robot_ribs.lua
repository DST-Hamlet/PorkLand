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
    TimeEvent(2 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/start")
    end),
    TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active") end),
    TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
    TimeEvent(39 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
})
AncientRobot.States.AddDeactivate(states, {
    TimeEvent(0  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green") end),
    TimeEvent(9  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green") end),
    TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green") end),
    TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/green") end),
}, "dontstarve_DLC003/creatures/enemy/metal_robot/ribs/stop")
AncientRobot.States.AddTaunt(states, {
    TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo") end),
    TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo") end),
    TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/taunt") end),
    TimeEvent(45 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo") end),
})
AncientRobot.States.AddLocomoteStates(states, {
    TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end ),
    TimeEvent(1 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
    end),
},
{
    TimeEvent(0 * FRAMES, function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:WalkForward()
    end),
    TimeEvent(6 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(16 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step_wires", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(21 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(25 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(38 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end),
},
{
    TimeEvent(3 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step", "steps")
        inst.SoundEmitter:SetParameter("steps", "intensity", math.random())
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo", "servo")
        inst.SoundEmitter:SetParameter("servo", "intensity", math.random())
    end),
    TimeEvent(48 * FRAMES, function(inst)
        inst.Physics:Stop()
    end),
})
AncientRobot.States.AddLaserBeam(states, {
    TimeEvent(2  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser_pre") end),
    TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo") end),
    TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo") end),
    TimeEvent(22 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.12)
    end),
    TimeEvent(24 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.24)
    end),
    TimeEvent(26 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.48)
    end),
    TimeEvent(28 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.60)
    end),
    TimeEvent(30 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.72)
    end),
    TimeEvent(32 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.84)
    end),
    TimeEvent(34 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 0.96)
    end),
    TimeEvent(36 * FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser", "laserfilter")
        inst.SoundEmitter:SetParameter("laserfilter", "intensity", 1)
    end),
}, false)

return StateGraph("ancient_robot_ribs", states, events, "idle", actionhandlers)
