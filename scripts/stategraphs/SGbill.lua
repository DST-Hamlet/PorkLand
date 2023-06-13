require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
	ActionHandler(ACTIONS.PICK, "pick"),
}

local events =
{
	--CommonHandlers.OnDeath(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("attacked", function(inst) if inst.components.health:GetPercent() > 0 then inst.sg:GoToState("hit") end end),
    EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack", data.target) end end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("locomote", 
        function(inst) 
            if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end

            if not inst.components.locomotor:WantsToMoveForward() then            	
                if not inst.sg:HasStateTag("idle") then
                    inst.sg:GoToState("idle")
                end
            else
                if not (inst.sg:HasStateTag("running") or inst.sg:HasStateTag("tumbling")) then
                    inst.sg:GoToState("run")
                end
            end
        end),
}

local states =
{
    State
	{
		name = "surface",
		tags = {"surface", "canrotate"},

		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("surface", true)
		end,

		events =
		{
			EventHandler("animover", function(inst, data) inst.sg:GoToState("idle") end),
		}
	},

    State
	{
		name = "idle",
		tags = {"idle", "canrotate"},

		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle", true)
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
		end,
	},

	State
	{
		name = "run",
		tags = {"moving", "running", "canrotate"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("run_pre")
			inst.components.locomotor.runspeed = TUNING.BILL_RUN_SPEED
			inst.components.locomotor:RunForward()
		end,

		onupdate = function(inst)
			if inst.components.locomotor:GetRunSpeed() > 0.0 then
				inst.components.locomotor:RunForward()

				if inst.letsGetReadyToTumble then
					inst.letsGetReadyToTumble = false
					inst.sg:GoToState("tumbling")
				end
			end		
		end,	

		events =
		{
			EventHandler("animover", function(inst, data) inst.sg:GoToState("run_loop") end),
		}	
	},

	State
	{
		name = "run_loop",
		tags = {"moving", "running", "canrotate"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("run_loop", true)
			inst.components.locomotor.runspeed = TUNING.BILL_RUN_SPEED
			inst.components.locomotor:RunForward()
			
			
		end,

		onupdate = function(inst)
			if inst.components.locomotor:GetRunSpeed() > 0.0 then
				inst.components.locomotor:RunForward()

				if inst.letsGetReadyToTumble then
					inst.letsGetReadyToTumble = false
					inst.sg:GoToState("tumbling")
				end
			end		
		end,

		timeline =
		{
			TimeEvent(4* FRAMES, function(inst) 
					if inst.components.amphibiouscreature.in_water then
						inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/thrust_small")
					else
						PlayFootstep(inst)
					end
			 	end),

			TimeEvent(8* FRAMES, function(inst) 
					if inst.components.amphibiouscreature.in_water then
						inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/thrust_small")
					else
						PlayFootstep(inst)
					end
			 	end),
		},		

		events =
		{
			EventHandler("animover", function(inst, data) inst.sg:GoToState("run_loop") end),
		}		
	},

	State
	{
		name = "attack",
		tags = {"attack"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk")
		end,

		timeline =
		{
			TimeEvent(4 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
			-- TODO: Put in a custom sound for the BILL attack later.
			TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/attack") end),
		},

		events =
		{
			EventHandler("animover", function(inst, data) inst.sg:GoToState("idle") end),
		}
	},

	State
	{
		name = "eat",

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat_pre", false)
			

		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("eat_pst") end),
		},
	},

	State
	{
		name = "eat_pst",

		onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/eat")
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat_loop", true)
			inst:PerformBufferedAction()
			inst.sg:SetTimeout(2 + math.random() * 4)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
	},

	State
	{
		name = "hit",
		tags = {"busy"},

		onenter = function(inst)
			-- inst.SoundEmitter:PlaySound(inst.sounds.hurt)
			inst.AnimState:PlayAnimation("hit")
			inst.Physics:Stop()
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/hit")
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State
	{
		name = "threaten",
		tags = {"busy"},

		onenter = function(inst)
			-- inst.SoundEmitter:PlaySound(inst.sounds.threaten)
			inst.AnimState:PlayAnimation("threaten")
			inst.Physics:Stop()
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State
	{
		name = "tumbling",
		tags = {"moving", "tumbling"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("tumble_loop", true)
			inst.components.locomotor.runspeed = TUNING.BILL_TUMBLE_SPEED
			inst.components.locomotor:RunForward()
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/roll_land_LP","land_tumbling")
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/roll_land_LP","water_tumbling")

			if inst.components.amphibiouscreature.in_water then
				inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/roll_water_LP","water_tumbling")				
			else
				inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/roll_land_LP","land_tumbling")				
			end
		end,

		events =
		{
			EventHandler("switch_to_water", function(inst)
					inst.SoundEmitter:KillSound("land_tumbling")
					inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/roll_water_LP","water_tumbling")

				end),
			EventHandler("switch_to_land", function(inst) 
					inst.SoundEmitter:KillSound("water_tumbling")
					inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/roll_land_LP","land_tumbling")
				end),
		},

        onexit = function(inst)
            inst.SoundEmitter:KillSound("water_tumbling")   
            inst.SoundEmitter:KillSound("land_tumbling")           
        end,

		onupdate = function(inst)
			if inst.components.locomotor:GetRunSpeed() > 0.0 then
				inst.components.locomotor:RunForward()
			end

			if inst.letsGetReadyToTumble then
				inst.letsGetReadyToTumble = false
				inst.sg:GoToState("run")
			end			
		end,
	},

	State
	{
		name = "death",
		tags = {"busy", "stunned"},

		onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/platapine_bill/death")
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			-- inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			-- inst.components.inventory:DropEverything(false, false)
		end,
	},
}
CommonStates.AddFrozenStates(states)
CommonStates.AddSleepStates(states)
CommonStates.AddSimpleActionState(states, "pick", "eat_loop", 9*FRAMES, {"busy"})

return StateGraph("bill", states, events, "idle", actionhandlers)
