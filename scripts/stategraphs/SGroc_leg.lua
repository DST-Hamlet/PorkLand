require("stategraphs/commonstates")

local ROC_LEGDSIT = 6

local actionhandlers =
{
}

local events =
{
    EventHandler("enter", function(inst) inst.sg:GoToState("enter") end),
    EventHandler("exit", function(inst) inst.sg:GoToState("exit") end),
    EventHandler("walk", function(inst) inst.sg:GoToState("step") end),
    EventHandler("walkfast", function(inst) inst.sg:GoToState("faststep") end),
}

local function DoStep(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 3, inst, 40)

    inst.components.groundpounder:GroundPound()
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/foot_ground")
    -- GetWorld():PushEvent("bigfootstep")
    -- this line above is meant to wake up all sleepers
end

local states =
{
    State{
        name = "idle",
        tags = {"idle" },

        onenter = function(inst, pushanim)
            if pushanim then
                inst.AnimState:PlayAnimation(pushanim)
                inst.AnimState:PushAnimation("stomp_loop")
            else
                inst.AnimState:PlayAnimation("stomp_loop")
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("peek")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                if math.random() < 0.2 then
                    inst.sg:GoToState("peek")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        }
    },

    State{
        name = "peek",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("critter_pre")
            inst.AnimState:PushAnimation("critter_loop", false)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst, data)
                inst.sg:GoToState("idle", "critter_pst")
            end),
        }
    },

    State{
        name = "step",
        tags = {"idle", "canrotate", "walking"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("stepfinish")
            end),
        }
    },

    State{
        name = "stepfinish",
        tags = {"idle", "canrotate", "walking"},

        onenter = function(inst)
            local angle = inst.body.Transform:GetRotation() * DEGREES
            local offset = Vector3(math.cos(angle + inst.legoffsetdir), 0, -math.sin(angle + inst.legoffsetdir)) * ROC_LEGDSIT
            local newpos = Vector3(inst.body.Transform:GetWorldPosition()) + offset

            if not TheWorld.Map:IsPassableAtPoint(newpos.x, 0, newpos.z) then
                -- NEEDS TO PUSH TO BODY!
                inst.body:PushEvent("liftoff")
            end

            inst.Transform:SetPosition(newpos.x,0,newpos.z)
            inst.Transform:SetRotation(inst.body.Transform:GetRotation())
            inst.AnimState:PlayAnimation("stomp_pre")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                DoStep(inst)
            end)
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "faststep",
        tags = {"idle", "canrotate", "walking"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("step_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("faststepfinish")
            end),
        }
    },

    State{
        name = "faststepfinish",
        tags = {"idle", "canrotate", "walking"},

        onenter = function(inst)
            local angle = inst.body.Transform:GetRotation()*DEGREES
            local offset = Vector3(math.cos(angle + inst.legoffsetdir), 0, -math.sin(angle + inst.legoffsetdir)) * ROC_LEGDSIT
            local newpos = Vector3(inst.body.Transform:GetWorldPosition()) + offset

            if not TheWorld.Map:IsPassableAtPoint(newpos.x, 0, newpos.z) then
                -- NEEDS TO PUSH TO BODY!
                inst.body:PushEvent("liftoff")
            end

            inst.Transform:SetPosition(newpos.x,0,newpos.z)
            inst.Transform:SetRotation(inst.body.Transform:GetRotation())
            inst.AnimState:PlayAnimation("step_pre")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                DoStep(inst)
            end)
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "enter",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pre")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                DoStep(inst)
            end)
        },

        events =
        {
            EventHandler("animover", function(inst, data)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "exit",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("stomp_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                inst:Remove()
            end),
        }
    },
}

return StateGraph("roc_leg", states, events, "idle", actionhandlers)
