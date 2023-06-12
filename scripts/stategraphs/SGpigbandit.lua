require("stategraphs/commonstates")

local actionhandlers = 
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.GOHOME, "disappear"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(true),
    CommonHandlers.OnDeath(),
    EventHandler("doaction", 
        function(inst, data) 
            if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            end
        end),
}

local states =
{
    State
    {
        name = "funnyidle",
        tags = {"idle"},
        
        onenter = function(inst)
			inst.Physics:Stop()
            local daytime = not GetClock():IsNight()
            inst.SoundEmitter:PlaySound("dontstarve/pig/oink")
            
            if inst.components.follower.leader and inst.components.follower:GetLoyaltyPercent() < 0.05 then
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")
            elseif inst:HasTag("guard") then
                inst.AnimState:PlayAnimation("idle_angry")
            elseif daytime then
                if inst.components.combat.target then
                    inst.AnimState:PlayAnimation("idle_angry")
                elseif inst.components.follower.leader and inst.components.follower:GetLoyaltyPercent() > 0.3 then
                    inst.AnimState:PlayAnimation("idle_happy")
                else
                    inst.AnimState:PlayAnimation("idle_creepy")
                end
            else
                inst.AnimState:PlayAnimation("idle_scared")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },        
    },

    State
    {
		name = "frozen",
		tags = {"busy"},
		
        onenter = function(inst)
            inst.AnimState:PlayAnimation("frozen")
            inst.Physics:Stop()
        end,
    },

    State
    {
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State
    {
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
            -- inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh",nil,.5)
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,
        
        timeline =
        {
            TimeEvent(13*FRAMES, function(inst) inst.components.combat:DoAttack() inst.sg:RemoveStateTag("attack") inst.sg:RemoveStateTag("busy") end),
        },
        
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State
    {
        name = "eat",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()            
            inst.AnimState:PlayAnimation("eat")
        end,
        
        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },        
    },

    State
    {
        name = "hit",
        tags = {"busy","evade"},
        
        onenter = function(inst)
        print("HIT")
            inst.SoundEmitter:PlaySound("dontstarve/pig/oink")
            inst.AnimState:PlayAnimation("hit")
            --inst.components.locomotor:Stop() 
        end,
        
        timeline =
        {
            TimeEvent(10*FRAMES, function(inst)  inst.sg:GoToState("evade_loop")  end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                    inst.sg:GoToState("evade_loop") 
                end),
        },        
    },
--[[
    State
    {
        name = "hit", --evade
        tags = {"busy", "evade","no_stun"},

        onenter = function(inst) 
            inst.components.locomotor:Stop()           
            inst.AnimState:PlayAnimation("run_pre")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("evade_loop") 
            end ),
        },               
    },
]]
   State
   {
        name = "evade_loop",
        tags = {"busy", "evade","no_stun"},

        onenter = function(inst)   
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst.sg:SetTimeout(0.15)
                
                inst:ForceFacePoint(inst.components.combat.target:GetPosition() )
                
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("run_loop",true)
                inst.Physics:SetMotorVelOverride(-20,0,0)
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            else
                inst.sg:GoToState("idle")  
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("evade_pst")
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
        end,        
    },

    State
    {
        name = "evade_pst",
        tags = {"busy", "evade","no_stun"},

        onenter = function(inst)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition() )
            end
     
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("run_pst")  
        end,

        events =
        {
            EventHandler("animover", function(inst)                
                inst.sg:GoToState("idle")                
            end ),
        },  

        onexit = function(inst)            
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
        end,        
    },

    State
    {
        name = "disappear",
        tags = {"doing", "busy"},

        onenter = function(inst, timeout)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(20*FRAMES, function(inst) 
                    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition()) 
                end),
            TimeEvent(23*FRAMES, function(inst) 
                    if GetWorld().components.banditmanager then
                        GetWorld().components.banditmanager:deactivatebandit(inst)
                    end
                    inst:PerformBufferedAction()                    
                    inst:RemoveFromScene()
                    inst.sg:GoToState("idle")
                end),
        },
    },  


    State
    {
        name = "pickup",
        tags = {"busy"},

        onenter = function(inst, timeout)
            inst.AnimState:PlayAnimation("pig_pickup")
            inst.components.locomotor:StopMoving()    
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) inst:PerformBufferedAction() end),
            TimeEvent(12*FRAMES, function(inst) inst.sg:GoToState("idle") end),
        },
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },          
    }, 
  
}

local walkanims = 
{
    startwalk = "sneak_pre",
    walk = "sneak_loop",
    stopwalk = "sneak_pst",
}

CommonStates.AddWalkStates(states,
{
	walktimeline =
    {
		TimeEvent(0*FRAMES, PlayFootstep),
        TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bandit/walk") end),
		TimeEvent(6*FRAMES, PlayFootstep),
        TimeEvent(7*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bandit/walk") end),
	},
}, walkanims)

CommonStates.AddRunStates(states,
{
	runtimeline =
    {
		TimeEvent(0*FRAMES, PlayFootstep),
        -- TimeEvent(1*FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/bandit/walk") end),
		TimeEvent(10*FRAMES, PlayFootstep),
	},
})

CommonStates.AddSleepStates(states,
{
	sleeptimeline = 
	{
		TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/pig/sleep") end),
	},
})

CommonStates.AddIdle(states, "funnyidle")
CommonStates.AddSimpleState(states, "refuse", "pig_reject", {"busy"})
CommonStates.AddFrozenStates(states)

--CommonStates.AddSimpleActionState(states, "pickup", "pig_pickup", 10*FRAMES, {"busy"})

CommonStates.AddSimpleActionState(states, "gohome", "pig_pickup", 4*FRAMES, {"busy"})

return StateGraph("pig", states, events, "idle", actionhandlers)

