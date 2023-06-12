require("stategraphs/commonstates")

local events = {}

local states = {

	State{
		name = "rise",
		tags = {"rising"},

		onenter = function(inst)
            inst.waveactive = true
			inst.AnimState:PlayAnimation("appear")
		end,

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
            	if inst.soundrise then inst.SoundEmitter:PlaySound(inst.soundrise) end
            	if inst.soundloop then inst.SoundEmitter:PlaySound(inst.soundloop, inst.soundloop) end
            end),
        },

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end)
		},
	},

	State{
		name = "idle",
		tags = {"idle"},

		onenter = function(inst)
			inst.waveactive = true
			inst.AnimState:PlayAnimation("idle", false)
			inst.sg:SetTimeout(inst.idle_time or 5)
		end,

		events =
		{
			EventHandler("animover", function(inst)

				if inst.waitingtolower then
					inst.sg:GoToState("lower")
				else
					inst.AnimState:PlayAnimation("idle", false)
				end
			end)
		},

		ontimeout = function(inst)
			--inst.sg:GoToState("lower")
			inst.waitingtolower = true
		end,
	},

	State{
		name = "lower",
		tags = {"lowering"},

		onenter = function(inst)
            inst.waveactive = true
			inst.AnimState:Resume()
			inst.AnimState:PlayAnimation("disappear")

			if inst.soundloop then
				inst.SoundEmitter:KillSound(inst.soundloop)
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst:Remove()
			end)
		},
	},
}

return StateGraph("wave", states, events, "rise")