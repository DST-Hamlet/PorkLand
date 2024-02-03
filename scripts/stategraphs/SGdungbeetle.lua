require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.DIGDUNG, "dig"),
    ActionHandler(ACTIONS.MOUNTDUNG, "jump"),
}

local events = {
    EventHandler("bumped", function(inst)
        inst.SoundEmitter:KillSound("dungroll")
        inst.sg:GoToState("bumped")
    end),
    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 then
            if not inst.components.freezable:IsFrozen() then
                inst.SoundEmitter:KillSound("dungroll")
                inst.sg:GoToState("hit")
            end
        end
    end),
    EventHandler("death", function(inst)
        inst.SoundEmitter:KillSound("dungroll")
        if inst:HasTag("hasdung") then
            inst.sg:GoToState("bumped", true)
        else
            inst.sg:GoToState("death")
        end
    end),
    EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local is_idling = inst.sg:HasStateTag("idle")

        if not is_idling and not is_moving then
            return
        end

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        if not should_move then
            if not is_idling then
                if inst.sg:HasStateTag("dungmounting") then
                -- do nothing at the moment.
                elseif not is_running then
                    inst.SoundEmitter:KillSound("dungroll")
                    inst.sg:GoToState("idle")
                else
                    inst.sg:GoToState("stop_run")
                end
            end
        elseif should_run then
            if not is_running then
                inst.sg:GoToState("surprise")
            end
        else
            if not inst.sg:HasStateTag("hopping") then
                inst.sg:GoToState("hop")
            end
        end
    end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
}

local function ProcessAnim(inst, anim)
    if inst:HasTag("hasdung") then
        return "ball_" .. anim
    else
        return anim
    end
end

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation(ProcessAnim(inst,"idle"), true)
            else
                inst.AnimState:PlayAnimation(ProcessAnim(inst,"idle"), true)
            end
            inst.SoundEmitter:PlaySound ("dontstarve_DLC003/creatures/dungbeetle/idle")
            inst.sg:SetTimeout(1 + math.random() * 1)
        end,
    },

    State{
        name = "hop",
        tags = {"moving", "canrotate", "hopping"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(ProcessAnim(inst, "walk_pre"))
            inst.Physics:Stop()
            if inst:HasTag("hasdung") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/rollingbball_LP","dungroll")
                inst.SoundEmitter:SetParameter("dungroll", "speed", 0)
            end
        end,

        onupdate = function(inst)
            if not inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("idle")
            end
        end,

        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("hop_loop") end ),
        },
    },

    State{
        name = "hop_loop",
        tags = {"moving", "canrotate", "hopping"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"walk_loop"))
            inst.components.locomotor:WalkForward()
        end,

        onupdate = function(inst)
            if not inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("idle")
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sgloop = true
                inst.sg:GoToState("hop_loop")
            end),
        },

        onexit = function(inst)
            if not inst.sgloop then
                inst.SoundEmitter:KillSound("dungroll")
            end
            inst.sgloop = nil
        end,

        timeline = {
            TimeEvent(10*FRAMES, function(inst)
                if inst:HasTag("hasdung") then
                    inst.SoundEmitter:PlaySound("dontstarve/movement/run_marsh_small")
                else
                    PlayFootstep(inst)
                end
            end),
            TimeEvent(11*FRAMES, function(inst)
                if inst:HasTag("hasdung") then
                    inst.SoundEmitter:PlaySound("dontstarve/movement/run_marsh_small")
                else
                    PlayFootstep(inst)
                end
            end),
        },
    },

    State{
        name = "dig",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("dig_pre")
        end,

        events = {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("dig_loop")
            end),
        }
    },

    State{
        name = "dig_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation( "dig_loop", true)
            inst.sg:SetTimeout(2 * math.random() + .5)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("dig_pst")
        end,
    },

    State{
        name = "dig_pst",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("dig_pst")
            inst:PerformBufferedAction()
        end,

        events = {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "jump",
        tags = {"busy", "moving", "canrotate", "dungmounting"},

        onenter = function(inst)
            RemovePhysicsColliders(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("ball_get_on")
            inst.SoundEmitter:PlaySound("dontstarve/common/craftable/tent_sleep")

            local pos = inst.dung_target:GetPosition()
            local MAX_JUMPIN_DIST = 3
            local MAX_JUMPIN_DIST_SQ = MAX_JUMPIN_DIST*MAX_JUMPIN_DIST
            local MAX_JUMPIN_SPEED = 6
            local dist
            if pos ~= nil then
                inst:ForceFacePoint(pos)
                local distsq = inst:GetDistanceSqToPoint(pos)
                if distsq <= 0.25*0.25 then
                    dist = 0
                    inst.sg.statemem.speed = 0
                elseif distsq >= MAX_JUMPIN_DIST_SQ then
                    dist = MAX_JUMPIN_DIST
                    inst.sg.statemem.speed = MAX_JUMPIN_SPEED
                else
                    dist = math.sqrt(distsq)
                    inst.sg.statemem.speed = MAX_JUMPIN_SPEED * dist / MAX_JUMPIN_DIST
                end
            else
                inst.sg.statemem.speed = 0
                dist = 0
            end
            inst.Physics:SetMotorVel(inst.sg.statemem.speed * .5, 0, 0)
        end,

        onexit = function(inst)
            ChangeToCharacterPhysics(inst)
        end,

        timeline = {
            TimeEvent(1 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
            end),

            TimeEvent(12 * FRAMES, function(inst)
                inst.Physics:Stop()
            end),
        },

        events = {
            EventHandler("animover", function (inst)
                inst:PerformBufferedAction()
                inst.sg:GoToState("jump_pst")
            end),
        }
    },

    State{
        name = "jump_pst",
        tags = {"busy", "jumping", "noattack"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("ball_get_on_pst")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "surprise",
        tags = {"busy", "surprise"},

        onenter = function(inst)
            inst.Physics:Stop()
            local play_scream = true
            if inst.components.inventoryitem then
                play_scream = inst.components.inventoryitem.owner == nil
            end
            if play_scream then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/scream")
            end
            inst.AnimState:PlayAnimation(ProcessAnim(inst, "emote_surprise"))
        end,

        events = {
            EventHandler("animover", function(inst)
                if inst:HasTag("hasdung") then
                    inst.sg:GoToState("run")
                else
                    inst.sg:GoToState("run_noball")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"run_pre"))
            inst.AnimState:PushAnimation(ProcessAnim(inst,"run_loop"), true)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/rollingbball_LP","dungroll")
            inst.SoundEmitter:SetParameter("dungroll", "speed", 1)
            inst.components.locomotor:RunForward()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("run_loop")
            end),
        }
    },

    State{
        name = "run_loop",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PushAnimation(ProcessAnim(inst,"run_loop"))
            inst.components.locomotor:RunForward()
        end,

        onupdate = function(inst)
            if not inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("idle")
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sgloop = true
                inst.sg:GoToState("run_loop")
            end),
        },

        onexit = function(inst)
            if not inst.sgloop then
                inst.SoundEmitter:KillSound("dungroll")
            end
            inst.sgloop = nil
        end,

        timeline= {
            TimeEvent(10*FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(11*FRAMES, function(inst) PlayFootstep(inst) end),
        },
    },

    State{
        name = "run_noball",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
            inst.components.locomotor:RunForward()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("run_noball_loop")
            end),
        }
    },

    State{
        name = "run_noball_loop",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PushAnimation("walk_loop")
            inst.components.locomotor:RunForward()
        end,

        timeline = {
            TimeEvent(10*FRAMES, function(inst) PlayFootstep(inst) end ),
            TimeEvent(11*FRAMES, function(inst) PlayFootstep(inst) end ),
        },

        events = {
            EventHandler("animover", function (inst) inst.sg:GoToState("run_noball_loop") end),
        }
    },

    State{
        name = "stop_run",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            if inst:HasTag("hasdung") then
                inst.AnimState:PlayAnimation(ProcessAnim(inst, "run_pst"))
            else
                inst.AnimState:PlayAnimation(ProcessAnim(inst, "walk_pst"))
                inst.Physics:Stop()
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/scream")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

        timeline = {
            TimeEvent(3*FRAMES,function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/death")
            end),
        },
    },

    State{
        name = "fall",
        tags = {"busy", "stunned"},
        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0, -20 + math.random() * 10, 0)
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst:CheckTransformState()
        end,

        onupdate = function(inst)
            local pt = inst:GetPosition()
            if pt.y < 2 then
                inst.Physics:SetMotorVel(0,0,0)
            end

            if pt.y <= .1 then
                pt.y = 0

                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
                inst.DynamicShadow:Enable(true)
                inst.sg:GoToState("stunned")
            end
        end,

        onexit = function(inst)
            local pt = inst:GetPosition()
            pt.y = 0
            inst.Transform:SetPosition(pt:Get())
        end,
    },

    State{
        name = "stunned",
        tags = {"busy", "stunned"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(GetRandomWithVariance(6, 2))
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = true
            end
        end,

        onexit = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = false
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "bumped",
        tags = {"busy"},

        onenter = function(inst, dead)
            if inst:HasTag("hasdung") then
                inst:RemoveTag("hasdung")
                local ball = SpawnPrefab("dungball")
                ball.Transform:SetPosition(inst.Transform:GetWorldPosition())
                ball.AnimState:PlayAnimation("idle")
            end

            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation( "fall_off_pre" )
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/crash")
            inst.components.locomotor.runspeed = -TUNING.DUNG_BEETLE_RUN_SPEED
            inst.components.locomotor:RunForward()

            if dead then
                inst.sg:GoToState("death")
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bumped_loop")
            end),
        },

        onexit = function(inst)
            inst.components.locomotor.runspeed = TUNING.DUNG_BEETLE_RUN_SPEED
            inst.Physics:Stop()
        end,
    },

    State{
        name = "bumped_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"fall_off_loop"), true)
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/fall_off_LP","fallen")
            inst.sg:SetTimeout(2)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("bumped_pst")
        end,
    },

    State{
        name = "bumped_pst",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"fall_off_pst"))
            inst.SoundEmitter:KillSound("fallen")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            if inst:HasTag("hasdung") then
                inst.sg:GoToState("bumped")
            else
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/hit")
                inst.SoundEmitter:KillSound("fallen")
                inst.AnimState:PlayAnimation("hit")
                inst.Physics:Stop()
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "sleep",
        tags = {"busy", "sleeping"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"sleep_pre"))
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/yawn")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("sleeping")
            end),
            EventHandler("onwakeup", function(inst)
                inst.sg:GoToState("wake")
            end),
        },
    },

    State{
        name = "sleeping",
        tags = {"busy", "sleeping"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"sleep_loop"))
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("sleeping")
            end),
            EventHandler("onwakeup", function(inst)
                inst.sg:GoToState("wake")
            end),
        },

        timeline = {
            TimeEvent(3*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/dungbeetle/breath_out")
            end),
        },
    },

    State{
        name = "wake",
        tags = {"busy", "waking"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"sleep_pst"))
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "frozen",
        tags = {"busy", "frozen"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"frozen"), true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
        end,

        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,

        events = {
            EventHandler("onthaw", function(inst)
                inst.sg:GoToState("thaw")
            end),
            EventHandler("unfreeze", function(inst)
                if inst.sg.sg.states.hit then
                    inst.sg:GoToState("hit")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        }
    },

    State{
        name = "thaw",
        tags = {"busy", "thawing"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation(ProcessAnim(inst,"frozen_loop_pst"), true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,

        events = {
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
    }
}

return StateGraph("dungbeetle", states, events, "idle", actionhandlers)
