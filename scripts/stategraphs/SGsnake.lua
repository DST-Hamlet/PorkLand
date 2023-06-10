require("stategraphs/commonstates")

local function getsound(inst, id)
	return inst.sounds[id]
end

local actionhandlers =
{
	ActionHandler(ACTIONS.EAT, "eat"),
	ActionHandler(ACTIONS.HARVEST, "eat"),
	ActionHandler(ACTIONS.LAVASPIT, "spit"),
	ActionHandler(ACTIONS.GOHOME, "gohome"),
}

local events=
{
	EventHandler("attacked", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then inst.sg:GoToState("hit") end end),
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
	EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack", data.target) end end),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnLocomote(true,false),
	CommonHandlers.OnFreeze(),
}

local states=
{

	State{
		name = "gohome",
		tags = {"busy"},
		onenter = function(inst, playanim)
			if inst.components.homeseeker and 
			   inst.components.homeseeker.home and 
			   inst.components.homeseeker.home:IsValid() then

				inst.components.homeseeker.home.AnimState:PlayAnimation("chop", false)
			end
			inst:PerformBufferedAction()
		end,
	},

	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.SoundEmitter:PlaySound( getsound(inst, "idle"))
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle", true)
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
			inst.sg:SetTimeout(2*math.random()+.5)
		end,

	},

	
	State{
		name = "attack",
		tags = {"attack", "busy"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.SoundEmitter:PlaySound( getsound(inst, "pre_attack"))
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk", false)
			inst.AnimState:PushAnimation("atk_pst", false)
		end,

		timeline=
		{
			TimeEvent(8*FRAMES, function(inst) 
				if inst.components.combat.target then 
					inst:ForceFacePoint(inst.components.combat.target:GetPosition()) 
				end 
			end),

			TimeEvent(14*FRAMES, function(inst) 
				if inst.components.combat.target then 
					inst:ForceFacePoint(inst.components.combat.target:GetPosition()) 
				end 
				inst.SoundEmitter:PlaySound( getsound(inst, "attack")) 
			end),

			TimeEvent(20*FRAMES, function(inst) 
				if inst.components.combat.target then 
					inst:ForceFacePoint(inst.components.combat.target:GetPosition()) 
				end 
			end),

			TimeEvent(27*FRAMES, function(inst) 
				inst.components.combat:DoAttack(inst.sg.statemem.target) 
				if inst.components.combat.target then 
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end 
			end),
		},

		events=
		{
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "eat",
		tags = {"busy"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk", false)
			inst.AnimState:PushAnimation("atk_pst", false)
		end,

		timeline=
		{
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound( getsound(inst, "attack")) end),
			TimeEvent(24*FRAMES, function(inst) if inst:PerformBufferedAction() then inst.components.combat:SetTarget(nil) end end),
		},

		events=
		{
			EventHandler("animqueueover", function(inst)  inst.sg:GoToState("taunt")  end),
		},
	},

	State{
		name = "spit",
		tags = {"busy"},
		
		onenter = function(inst)
			-- print("snake spit")
			if ((inst.target ~= inst and not inst.target:HasTag("fire")) or inst.target == inst) and not (inst.recently_frozen) then
				if inst.components.locomotor then
					inst.components.locomotor:StopMoving()
				end
				inst.AnimState:PlayAnimation("atk_pre")
				inst.AnimState:PushAnimation("atk", false)
				inst.AnimState:PushAnimation("atk_pst", false)

				inst.components.propagator:StartSpreading()

				--print("vomitfire_fx spawned")
				-- inst.vomitfx = SpawnPrefab("vomitfire_fx")
				-- inst.vomitfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				-- inst.vomitfx.Transform:SetRotation(inst.Transform:GetRotation())
				--inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/vomitrumble", "vomitrumble")
			else
				-- print("no spit")
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle")
			end
		end,

		onexit = function(inst)
			-- print("spit onexit")
			if inst.last_target and inst.last_target ~= inst then
				inst.num_targets_vomited = inst.last_target.components.stackable and inst.num_targets_vomited + inst.last_target.components.stackable:StackSize() or inst.num_targets_vomited + 1
				inst.last_target_spit_time = GetTime()
			end
			--inst.Transform:SetFourFaced()
			-- if inst.vomitfx then 
				-- inst.vomitfx:Remove() 
			-- end
			-- inst.vomitfx = nil
			-- inst.SoundEmitter:KillSound("vomitrumble")

			inst.components.propagator:StopSpreading()
		end,
		
		events=
		{
			EventHandler("animqueueover", function(inst) 
				-- print("spit animqueueover")
				inst.sg:GoToState("idle")
			end),
		},

		timeline=
		{
			TimeEvent(2*FRAMES, function(inst) 
				-- print("spit timeline")
				inst:PerformBufferedAction()
				inst.last_target = inst.target
				inst.target = nil
				inst.spit_interval = math.random(20,30)
				inst.last_spit_time = GetTime()
			end),
		},
	},
	
	State{
		name = "hit",
		tags = {"busy", "hit"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("hit")
			inst.SoundEmitter:PlaySound( getsound(inst, "hurt"))
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "taunt",
		tags = {"busy"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/taunt")
		end,

		timeline=
		{
			TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound( getsound(inst, "taunt")) end),
			--TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/snake/taunt") end),
		},

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
		},
	},

	State{
		name = "death",
		tags = {"busy"},

		onenter = function(inst)
			inst.SoundEmitter:PlaySound( getsound(inst, "death"))
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)            
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
		end,

	},

	State{
        name = "fall",
        tags = {"busy"},
        onenter = function(inst)
			inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0,-20+math.random()*10,0)
            inst.AnimState:PlayAnimation("idle", true)
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
	           -- inst.DynamicShadow:Enable(true)
                inst.SoundEmitter:PlaySound("dontstarve/frog/splat")
                inst.sg:GoToState("idle")
            end
        end,

        onexit = function(inst)
            local pt = inst:GetPosition()
            pt.y = 0
            inst.Transform:SetPosition(pt:Get())
        end,
    },    

    State{
        name = "emerge",
        tags = {"canrotate", "busy"},
        
        onenter = function(inst, noanim)
			if noanim then
                inst.AnimState:SetBank("snake")
                inst.sg:GoToState("taunt") -- Default State.
                return
            end

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("snake_water")
            inst.AnimState:PlayAnimation("emerge")
        end,
       
        events=
        {
            EventHandler("animover", function(inst) 
            	inst.AnimState:SetBank("snake")
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "submerge",
        tags = {"canrotate", "busy"},
        
        onenter = function(inst, noanim)
			if noanim then
                inst.AnimState:SetBank("snake_water")
                inst.sg:GoToState("taunt") -- Default State.
                return
            end

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("snake_water")
            inst.AnimState:PlayAnimation("submerge")
        end,
       
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")
            end),
        },
    }, 
}

CommonStates.AddSleepStates(states,
{
	sleeptimeline = {
		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound( getsound(inst, "sleep")) end),
	},
})


CommonStates.AddRunStates(states,
{
	runtimeline = {
		TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound( getsound(inst, "move")) end),
		TimeEvent(4, function(inst) inst.SoundEmitter:PlaySound( getsound(inst, "move")) end),
	},
})
CommonStates.AddFrozenStates(states)


return StateGraph("snake", states, events, "taunt", actionhandlers)
