require("stategraphs/commonstates")
local AncientHulkUtil = require("prefabs/ancient_hulk_util")

local SpawnLaser = AncientHulkUtil.SpawnLaser
local SetLightValue = AncientHulkUtil.SetLightValue
local SetLightValueAndOverride = AncientHulkUtil.SetLightValueAndOverride
local SetLightColour = AncientHulkUtil.SetLightColour

local SHAKE_DIST = 40

local AncientRobot =
{
    ActionHandlers = {},
    Events = {},
    States = {},
}

-----[[ ActionHandlers ]]-----

AncientRobot.ActionHandlers.ASSEMBLE_ROBOT = function ()
    return ActionHandler(ACTIONS.ASSEMBLE_ROBOT, "action")
end 

-----[[     Events     ]]-----

AncientRobot.Events.OnStep = CommonHandlers.OnStep

AncientRobot.Events.OnLocomote = function()
    return CommonHandlers.OnLocomote(true, true)
end

AncientRobot.Events.DoBeamAttack = function()
    return EventHandler("dobeamattack", function(inst, data)
        if not inst.sg:HasStateTag("activating") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("laserbeam", data.target)
        end
    end)
end

AncientRobot.Events.DoLeapAttack = function()
    return EventHandler("doleapattack", function(inst, data)
        if not inst.sg:HasStateTag("activating") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("leap_attack_pre", data.target)
        end
    end)
end

AncientRobot.Events.OnAttacked = function()
    return EventHandler("attacked", function(inst, data)
        inst:PushEvent("removemoss")
        inst.hits = inst.hits + 1

        if inst.hits > 2 and math.random() * inst.hits >= 2 then
            local x, y, z= inst.Transform:GetWorldPosition()
            inst.components.lootdropper:SpawnLootPrefab("iron", Vector3(x,y,z))
            inst.hits = 0

            if inst:HasTag("dormant") then
                if  math.random() < 0.6 then
                    inst.wantstodeactivate = nil
                    inst:RemoveTag("dormant")
                    inst:PushEvent("shock")
                    inst.components.timer:SetTimeLeft("discharge", 20)
                    if not TheWorld.state.isaporkalypse then
                        inst.components.timer:ResumeTimer("discharge")
                    end
                end
            elseif not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("activating") then
                inst.sg:GoToState("hit")
            end
        end

        if inst:HasTag("dormant") and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("hit_dormant")
        end
    end)
end

AncientRobot.Events.OnShocked = function()
    return EventHandler("shock", function(inst, data)
        inst.wantstodeactivate = nil
        inst:RemoveTag("dormant")
        inst.sg:GoToState("shock")
    end)
end

AncientRobot.Events.OnActivate = function()
    return EventHandler("activate", function(inst, data)
        inst.wantstodeactivate = nil
        inst:RemoveTag("dormant")
        inst.sg:GoToState("activate")
    end)
end

AncientRobot.Events.OnDeactivate = function()
    return EventHandler("deactivate", function(inst, data)
        if not inst:HasTag("dormant") then
            inst.wantstodeactivate = nil
            inst:AddTag("dormant")
            inst.sg:GoToState("deactivate")
        end
    end)
end

-----[[     States     ]]-----

AncientRobot.States.AddIdle = function(states, is_leg)
    table.insert(states, State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
            inst.sg:SetTimeout(2 + 2 * math.random())
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("taunt")
        end,
    })

    local idle_dormant_timeline = is_leg and {
        TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo") end),
        TimeEvent(27 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo_small", nil, 0.5) end),
        TimeEvent(31 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo_small", nil, 0.5) end),
        TimeEvent(45 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/leg/servo", nil, 0.6) end),
    } or {}

    table.insert(states, State{
        name = "idle_dormant",
        tags = {"idle","dormant"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.SoundEmitter:SetParameter("gears", "intensity", 1)
            inst.SoundEmitter:KillSound("gears")

            if inst:HasTag("mossy") then
                inst.AnimState:PlayAnimation("mossy_full")
            else
                inst.AnimState:PlayAnimation("full")
            end
        end,

        timeline = idle_dormant_timeline,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },
    })
end

AncientRobot.States.AddCommonStates = function(states)
    table.insert(states, State{
        name = "fall",
        tags = {"busy"},

        onenter = function(inst, pushanim)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0, -35, 0)
            inst.AnimState:PlayAnimation("idle_fall", true)
        end,

        onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()

            if y < 2 then
                inst.Physics:SetMotorVel(0, 0, 0)
            end

            if y <= 0.1 then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.25)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step")

                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(x, 0, z)
                inst.sg:GoToState("separate")

                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 2, inst, SHAKE_DIST)
            end
        end,

        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x, 0, z)
        end,
    })

    table.insert(states, State{
        name = "separate",
        tags = {"busy", "dormant"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("separate")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_dormant")
            end),
        },
    })

    table.insert(states, State{
        name = "hit_dormant",
        tags = {"busy", "dormant", "hit"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("dormant_hit")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle_dormant")
            end),
        },
    })

    table.insert(states, State{
        name = "shock",
        tags = {"busy", "activating"},

        onenter = function(inst, pushanim)
            inst:PushEvent("removemoss")
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shock")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro", nil, 0.5) end),
            TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro", nil, 0.5) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("activate")
            end),
        },
    })

    table.insert(states, State{
        name = "action",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("shock", false)
            inst:PerformBufferedAction()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end)
        },
    })

    CommonStates.AddSimpleState(states, "hit", "hit")
end

AncientRobot.States.AddActivate = function(states, timeline)
    table.insert(states, State{
        name = "activate",
        tags = {"busy", "activating"},

        onenter = function(inst, pushanim)
            inst:PushEvent("removemoss")

            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/gears_LP", "gears")
            inst.SoundEmitter:SetParameter("gears", "intensity", 0.5)
            inst:AddTag("hostile")
        end,

        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("taunt")
            end),
        },
    })
end

AncientRobot.States.AddDeactivate = function(states, timeline, onenter_sound)
    table.insert(states, State{
        name = "deactivate",
        tags = {"busy", "deactivating"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("deactivate")
            inst.SoundEmitter:PlaySound(onenter_sound)
            inst:RemoveTag("hostile")
        end,

        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_dormant") end),
        },
    })
end

AncientRobot.States.AddTaunt = function(states, timeline)
    table.insert(states, State{
        name = "taunt",
        tags = {"busy", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    })
end

AncientRobot.States.AddLocomoteStates = function(states, starttimeline, runtimeline, endtimeline)
    CommonStates.AddWalkStates(states)

    CommonStates.AddRunStates(states,
    {
        starttimeline = starttimeline,
        runtimeline = runtimeline,
        endtimeline = endtimeline,

    },
    {
        startrun = "walk_pre",
        run = "walk_loop",
        stoprun = "walk_pst"
    }, true, nil,
    {
        startonexit = function(inst)
            if not inst.AnimState:AnimDone()  then
                inst.SoundEmitter:KillSound("robo_walk_LP")
            end
        end,
        runonexit = function(inst)
            if not inst.AnimState:AnimDone()  then
                inst.SoundEmitter:KillSound("robo_walk_LP")
            end
        end,
        endonexit = function(inst)
            inst.SoundEmitter:KillSound("robo_walk_LP")
        end,
    })
end

AncientRobot.States.AddLaserBeam = function(states, sound_timeline, sixfaced)
    local timeline = JoinArrays(sound_timeline, {
        TimeEvent(6 * FRAMES, function(inst) SetLightValue(inst, 0.97) end),
        TimeEvent(8  * FRAMES, function(inst) inst.Light:Enable(true) end),
        TimeEvent(8  * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.05, 0.2) end),
        TimeEvent(9  * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.10, 0.15) end),
        TimeEvent(10 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.15, 0.05) end),
        TimeEvent(11 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.20, 0.00) end),
        TimeEvent(12 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.25, 0.35) end),
        TimeEvent(13 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.30, 0.30) end),
        TimeEvent(14 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.35, 0.05) end),
        TimeEvent(15 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.40, 0.00) end),
        TimeEvent(16 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.45, 0.30) end),
        TimeEvent(17 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.50, 0.15) end),
        TimeEvent(18 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.55, 0.05) end),
        TimeEvent(19 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.60, 0.00) end),
        TimeEvent(20 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.65, 0.35) end),
        TimeEvent(21 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.70, 0.30) end),
        TimeEvent(22 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.75, 0.05) end),
        TimeEvent(23 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.80, 0.00) end),
        TimeEvent(24 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.85, 0.30) end),
        TimeEvent(25 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.90, 0.15) end),
        TimeEvent(26 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.95, 0.05) end),
        TimeEvent(27 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.00, 0.35) end),
        TimeEvent(28 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.01, 0.35) end),
        TimeEvent(29 * FRAMES, function(inst) SetLightValueAndOverride(inst, 0.90, 0.00) end),
        TimeEvent(30 * FRAMES, function(inst)
            SpawnLaser(inst)
            inst.sg.statemem.target = nil
            SetLightValueAndOverride(inst, 1.08, 0.70)
        end),
        TimeEvent(31 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.12, 1.00) end),
        TimeEvent(32 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.10, 0.90) end),
        TimeEvent(33 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.06, 0.40) end),
        TimeEvent(34 * FRAMES, function(inst) SetLightValueAndOverride(inst, 1.10, 0.60) end),
        TimeEvent(35 * FRAMES, function(inst) inst.sg.statemem.lightval = 1.1 end),
        TimeEvent(36 * FRAMES, function(inst)
            inst.sg.statemem.lightval = 1.035
            SetLightColour(inst, .9)
        end),
        TimeEvent(37 * FRAMES, function(inst)
            inst.sg.statemem.lightval = nil
            SetLightValueAndOverride(inst, .9, 0)
            SetLightColour(inst, .9)
        end),
        TimeEvent(38 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            SetLightValue(inst, 1)
            SetLightColour(inst, 1)
            inst.Light:Enable(false)
        end),
    })

    table.insert(states, State{
        name = "laserbeam",
        tags = { "busy", "attack" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")

            if target and target:IsValid() then
                if inst.components.combat:TargetIs(target) then
                    inst.components.combat:StartAttack()
                end
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
            end

            inst.components.timer:StopTimer("laserbeam_cd")
            inst.components.timer:StartTimer("laserbeam_cd", TUNING.DEERCLOPS_ATTACK_PERIOD * (math.random(3) - 0.5))
        end,

        onupdate = function(inst)
            if inst.sg.statemem.lightval then
                inst.sg.statemem.lightval = inst.sg.statemem.lightval * 0.99
                SetLightValueAndOverride(inst, inst.sg.statemem.lightval, (inst.sg.statemem.lightval - 1) * 3)
            end
        end,

        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.keepfacing = true
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if sixfaced then
                inst.Transform:SetSixFaced()
            else
                inst.Transform:SetFourFaced()
            end
            SetLightValueAndOverride(inst, 1, 0)
            SetLightColour(inst, 1)

            inst.Light:Enable(false)
        end,
    })
end

AncientRobot.States.AddLeap = function(states, pre_timeline, loop_timeline, pst_timeline)
    table.insert(states, State{
        name = "leap_attack_pre",
        tags = {"attack", "canrotate", "busy", "leapattack"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
            inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
        end,

        timeline = pre_timeline,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("leap_attack", {startpos = inst.sg.statemem.startpos, targetpos = inst.sg.statemem.targetpos})
            end),
        },
    })

    table.insert(states, State{
        name = "leap_attack",
        tags = {"attack", "canrotate", "busy", "leapattack"},

        onenter = function(inst, data)
            inst.sg.statemem.startpos = data.startpos
            inst.sg.statemem.targetpos = data.targetpos
            inst.sg.statemem.leap_time = 0
            inst.components.locomotor:Stop()
            inst.Physics:SetActive(false)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_loop")
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
        end,

        onupdate = function(inst, dt)
            local percent = inst.sg.statemem.leap_time / inst.AnimState:GetCurrentAnimationLength()
            inst.sg.statemem.leap_time = inst.sg.statemem.leap_time + dt
            local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
            local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z

            inst.Transform:SetPosition(inst.sg.statemem.startpos.x + xdiff * percent, 0, inst.sg.statemem.startpos.z + zdiff * percent)
        end,

        onexit = function(inst)
            inst.Physics:SetActive(true)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.sg.statemem.startpos = nil
            inst.sg.statemem.targetpos = nil
        end,

        timeline = loop_timeline,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack_pst") end),
        },
    })

    table.insert(states, State{
        name = "leap_attack_pst",
        tags = {"busy"},

        onenter = function(inst, target)
            ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 2, inst, SHAKE_DIST)

            SpawnPrefab("laser_ring").Transform:SetPosition(inst.Transform:GetWorldPosition())

            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pst")
        end,

        timeline = pst_timeline,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    })
end

return AncientRobot
