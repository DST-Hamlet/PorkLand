local WALK_SPEED = 4
local RUN_SPEED = 7

require("stategraphs/commonstates")

local actionhandlers = 
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
    ActionHandler(ACTIONS.GOHOME, "ascendtree"),
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("attacked", function(inst) if inst.components.health:GetPercent() > 0 then inst.sg:GoToState("hit") end end),
    EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack", data.target) end end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("trapped", function(inst) inst.sg:GoToState("trapped") end),
    EventHandler("locomote", 
        function(inst) 
            if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end
            
            if not inst.components.locomotor:WantsToMoveForward() then
                if not inst.sg:HasStateTag("idle") then
                    if not inst.sg:HasStateTag("running") then
                        inst.sg:GoToState("idle")
                    end

                    inst.sg:GoToState("idle")
                end
            elseif inst.components.locomotor:WantsToRun() then
                if not inst.sg:HasStateTag("running") then
                    inst.sg:GoToState("run")
                end
            else
                if not inst.sg:HasStateTag("hopping") then
                    inst.sg:GoToState("hop")
                end
            end
        end),
}

local states =
{
    State
    {
        name = "look",
        tags = {"idle", "canrotate" },

        onenter = function(inst)
            inst.data.lookingup = nil
            inst.data.donelooking = nil
            
            if math.random() > .5 then
                inst.AnimState:PlayAnimation("lookup_pre")
                inst.AnimState:PushAnimation("lookup_loop", true)
                inst.data.lookingup = true
            else
                inst.AnimState:PlayAnimation("lookdown_pre")
                inst.AnimState:PushAnimation("lookdown_loop", true)
            end
            
            inst.sg:SetTimeout(1 + math.random()*1)
        end,
        
        ontimeout = function(inst)
            inst.data.donelooking = true
            if inst.data.lookingup then
                inst.AnimState:PlayAnimation("lookup_pst")
            else
                inst.AnimState:PlayAnimation("lookdown_pst")
            end
        end,
        
        events =
        {
            EventHandler("animover", function(inst, data)
                if inst.data.donelooking then
                    inst.sg:GoToState("idle")
                end
            end),
        }
    },

    State
    {
        name = "idle",
        tags = {"idle", "canrotate"},

        timeline = 
        {
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/idle") end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/idle") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/idle") end),
        },

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end                                
            inst.sg:SetTimeout(1 + math.random()*1)
        end,
        
        ontimeout= function(inst)
            -- inst.sg:GoToState("look")
        end,
    },

    State
    {
        name = "attack",
        tags = {"attack"},
        
        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("attack")
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/attack")  end),
        },

        events =
        {
            EventHandler("animover", function(inst, data) inst.sg:GoToState("idle") end),
        },
    },

    State
    {
        name = "action",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst, data) inst.sg:GoToState("idle") end),
        }
    },

    State
    {
        name = "ascendtree",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("climbuptree")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                 inst:PerformBufferedAction()
                 inst.sg:GoToState("idle") 
                 end),
        }
    },

    State
    {
        name = "descendtree",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("climbdowntree")
        end,

        events =
        {
            EventHandler("animover", function(inst, data)
                 inst.sg:GoToState("idle") 
                 end),
        }
    },

    State
    {
        name = "eat",
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre", false)
            inst.AnimState:PushAnimation("eat_loop", true)
            inst.sg:SetTimeout(2+math.random()*4)
        end,
        
        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },

    State
    {
        name = "pickup",
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre", false)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/steal")
        end,
        
        events =
        {
            EventHandler("animover", function(inst, data) 
                    inst:PerformBufferedAction() 
                    inst.sg:GoToState("pickup_pst")
                end),
        }
    },

    State
    {
        name = "pickup_pst",
        
        onenter = function(inst)
            inst.Physics:Stop()
            -- TODO: Change these animations to be pickup related.
            inst.AnimState:PlayAnimation("eat_pst", false)
        end,
        
        events =
        {
            EventHandler("animover", function(inst, data) inst.sg:GoToState("idle") end),
        }
    },

    State
    {
        name = "hop",
        tags = {"moving", "canrotate", "hopping"},
        
        timeline =
        {
            TimeEvent(5*FRAMES, function(inst) 
                inst.Physics:Stop() 
                inst.SoundEmitter:PlaySound("dontstarve/rabbit/hop")
            end ),
        },
        
        onenter = function(inst) 
            inst.AnimState:PlayAnimation("walk")
            inst.components.locomotor:WalkForward()
            inst.sg:SetTimeout(2*math.random()+0.5)
        end,
        
        onupdate = function(inst)
            if not inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("idle")
            end
        end,        
        
        ontimeout = function(inst)
            inst.sg:GoToState("hop")
        end,
    },

    State
    {
        name = "run",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst) 
            local play_scream = true
            if inst.components.inventoryitem then
                play_scream = inst.components.inventoryitem.owner == nil
            end
            if play_scream and not inst.currentlyRabid then
                inst.SoundEmitter:PlaySound(inst.sounds.scream)                
            end
            inst.AnimState:PlayAnimation("run_pre")
            inst.AnimState:PushAnimation("run", true)
            inst.components.locomotor:RunForward()
        end,

        onupdate = function(inst)
            if inst.components.locomotor:GetRunSpeed() > 0.0 then
                inst.components.locomotor:RunForward()
            end
        end,   
    },

    State
    {
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)        
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            inst.components.inventory:DropEverything(false, false)           
        end,
    },

    State
    {
        name = "fall",
        tags = {"busy", "stunned"},

        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0,-20+math.random()*10,0)
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst:CheckTransformState()
        end,
        
        onupdate = function(inst)
            local pt = Point(inst.Transform:GetWorldPosition())
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

    State
    {
        name = "stunned",
        tags = {"busy", "stunned"},
        
        onenter = function(inst) 
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(GetRandomWithVariance(6, 2) )
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = true
            end
        end,
        
        onexit = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = false
            end
        end,
        
        ontimeout = function(inst) inst.sg:GoToState("idle") end,
    },

    State
    {
        name = "trapped",
        tags = {"busy", "trapped"},
        
        onenter = function(inst) 
            inst.Physics:Stop()
			inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("stunned_loop", true)
            inst.sg:SetTimeout(1)
        end,
        
        ontimeout = function(inst) inst.sg:GoToState("idle") end,
    },

    State
    {
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/piko/scream")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()            
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },        
    },
}
CommonStates.AddSleepStates(states)
CommonStates.AddFrozenStates(states)


return StateGraph("piko", states, events, "idle", actionhandlers)

