require("stategraphs/commonstates")

local actionhandlers =
{
	ActionHandler(ACTIONS.EAT, "eat"),
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

local function get_loco_state(inst, override, default)
    local anim = default
    if override then
        anim = type(override) == "function" and override(inst) or override
    end
    return anim
end

local states=
{

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            ----inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/pant")
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
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline=
        {

			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/whip") end),
            TimeEvent(12*FRAMES, function (inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/attack") end),
                -- body
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events=
        {
            EventHandler("animover", function(inst) if math.random() < .333 then inst.components.combat:SetTarget(nil) inst.sg:GoToState("taunt") else inst.sg:GoToState("idle") end end),
        },
    },

	State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()

            inst.AnimState:PlayAnimation("atk")
        end,

		timeline=
        {
			---TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/bite") end),
        },

        events=
        {
			EventHandler("animover", function(inst) if inst:PerformBufferedAction() then inst.components.combat:SetTarget(nil) inst.sg:GoToState("taunt") else inst.sg:GoToState("idle") end end),
        },
    },

	State{
		name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/hurt")
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
        end,

		timeline=
        {
			TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/taunt") end),
			--TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/bark") end),
        },

        events=
        {
			EventHandler("animover", function(inst) if math.random() < .333 then inst.sg:GoToState("taunt") else inst.sg:GoToState("idle") end end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
			inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),
        },
     },

     State{
        name = "run",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop")
            -- inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run_LP", "runsound")
            -- inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/talk_LP", "talksound")
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run") end),
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run") end),
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run") end),
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run") end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/run") end),
       },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end ),
        },

        onexit = function(inst)
            -- inst.SoundEmitter:KillSound("runsound")
            -- inst.SoundEmitter:KillSound("talksound")
        end,
    },

    State{
        name = "run_stop",
        tags = {"idle"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
           -- local should_softstop = (type(softstop) == "function" and softstop(inst)) or softstop
            inst.AnimState:PushAnimation("run_pst")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
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
        name = "hatch",
        tags = {"busy"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emerge")
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/glowfly/hatch") end),
            TimeEvent(2 *FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/enemy/rabid_beetle/taunt",nil,.5) end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
}

CommonStates.AddSleepStates(states,
{
	sleeptimeline = {
        --TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/sleep") end),
	},
})

CommonStates.AddFrozenStates(states)

return StateGraph("rabid_beetle", states, events, "taunt", actionhandlers)
