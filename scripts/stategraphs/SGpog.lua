require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.BARK, "bark_at_friend"),
    ActionHandler(ACTIONS.RANSACK, "ransack"),
}

local events=
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(true),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true,true),
    EventHandler("barked_at", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("preoccupied") and data.belly then
            inst.sg:GoToState("belly")
        else
            if inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("attack", data.target)
        end
    end),
}

local function testrummage(inst,target)
     if target and target.components.container then


        local notags = {"FX", "NOCLICK", "DECOR","INLIMBO", "aquatic"}
        local food = FindEntity(inst, TUNING.POG_SEE_FOOD, function(item) return inst.components.eater:CanEat(item) and item:IsOnValidGround() and item:GetTimeAlive() > TUNING.POG_EAT_DELAY end, nil, notags)

        local items = target.components.container:FindItems(function() return true end)
        if #items > 0 and not food then
            return true
        end
    end
end

local function tossitems(inst,target)
    if target and target.components.container then
        local items = target.components.container:FindItems(function() return true end)
        if #items > 0 then
            local item = items[math.random(1,#items)]
            item = target.components.container:RemoveItem(item)

            local x,y,z = target.Transform:GetWorldPosition()
            item.Transform:SetPosition(x,y,z)

            local vel = Vector3(0, 5, 0)
            local speed = 3 + math.random()
            local angle = math.random()*2*PI
            vel.x = speed*math.cos(angle)
            vel.y = speed*3
            vel.z = speed*math.sin(angle)
            item.Physics:SetVel(vel.x, vel.y, vel.z)
        end
    end
end

local function bark_at_friends(inst)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4, {"pog"})

    local nottriggered  = true
    for i, ent in ipairs(ents)do
        local belly = false
        if ent.sg:HasStateTag("idle") then

            if nottriggered then
                belly = true
                nottriggered = nil
            end
        end
        inst:DoTaskInTime(math.random()*0.3, function() ent:PushEvent("barked_at",{belly = belly})  end)
    end
end

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            if inst.wantstobark then
                inst.wantstobark = nil
                inst.sg:GoToState("bark_at_friend")
            else
                if inst:HasTag("can_beg") and math.random() < 0.6 then
                    inst.sg:GoToState("beg")
                else

                    inst.components.locomotor:StopMoving()

                    if playanim then
                        inst.AnimState:PlayAnimation(playanim)
                        inst.AnimState:PushAnimation("idle_loop", true)
                    else
                        inst.AnimState:PlayAnimation("idle_loop", true)
                    end

                    inst.sg:SetTimeout(2 + 2*math.random())
                end
            end
        end,

        timeline =
        {
            --TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/swipe_tail") end),
        },

        ontimeout=function(inst)
            local rand = math.random()

            if inst:HasTag("can_beg") then
                if rand < .5 then
                    inst.sg:GoToState("beg")
                elseif rand < 0.75 then
                    inst.sg:GoToState("cute")
                else
                    inst.sg:GoToState("tailchase")
                end
            else
                if rand < .5 then
                    inst.sg:GoToState("cute")
                else
                    inst.sg:GoToState("tailchase")
                end
            end
        end,
    },

    State{
        name = "cute",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_cute")
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/cute") end),
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/cute") end),
        },
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },


    State{
        name = "tailchase",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_pre")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("tailchase_loop") end),
        },
    },

    State{
        name = "tailchase_loop",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_loop")
        end,

        timeline =
        {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/bark") end),
        },
        events=

        {
            EventHandler("animover", function(inst)
                if math.random()<0.3 then
                    inst.sg:GoToState("tailchase_loop")
                else
                    inst.sg:GoToState("tailchase_pst")
                end
            end),

        },
    },

    State{
        name = "tailchase_pst",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_pst")
        end,
        timeline =
        {
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/bark") end),
        },
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "ransack_pre",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("rummage_pre")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("ransack") end),
        },
    },

    State{
        name = "ransack",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            print("ENTERING RANSACK")

            inst.components.locomotor:StopMoving()

            local act = inst:GetBufferedAction()
            if act and act.target and act.target:HasTag("pogproof") then
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle","rummage_pst")
                inst.wantstobark = act.target
            else

                if not act or not testrummage(inst, act.target) or act.target:HasTag("pogged") then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle","rummage_pst")
                else
                    inst.ransacking = act.target

                    act.target.components.container:Open(act.doer)
                    inst.ransacking = act.target
                    act.target:AddTag("pogged")

                    inst.AnimState:PlayAnimation("rummage_loop")
                end
            end
        end,

        timeline=
       {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/rummage") end),
       },

        onupdate = function(inst)
            local p_pt = Vector3(inst.ransacking.Transform:GetWorldPosition())
            local m_pt = Vector3(inst.Transform:GetWorldPosition())
            if distsq(p_pt, m_pt) > 1 * 1 then
                inst.sg:GoToState("idle","rummage_pst")
            end
        end,

        onexit = function(inst)
        --print("EXITING RANSACK",inst.keepransacking, inst.ransacking.GUID)
            if inst.ransacking and not inst.keepransacking then
                print("SHOULD CLOSE")
                inst.ransacking.components.container:Close()
                inst.ransacking:RemoveTag("pogged")
            end
            inst.keepransacking = nil
        end,

        events=
        {
            EventHandler("animover", function(inst)
                    inst.keepransacking = true
                    inst.sg:GoToState("ransack_throw")
                end),
        },
    },

    State{
        name = "ransack_throw",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("rummage_throw")
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) tossitems(inst,inst.ransacking) end),
            TimeEvent(9*FRAMES, function(inst) if math.random() < 0.5 then inst.SoundEmitter:PlaySound("pl/creatures/pog/bark",nil,.5) end end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/make_whoosh") end),
        },

        onexit = function(inst)
            print("SHOULD CLOSE")
            if not inst.keepransacking then
               inst.ransacking.components.container:Close()
            end
            if inst.ransacking then
                inst.ransacking:RemoveTag("pogged")
                --inst.ransacking
            end
            inst.keepransacking = nil
        end,

        events=
        {
            EventHandler("animover", function(inst)
                    inst.keepransacking = true
                    inst.sg:GoToState("ransack")
                end),
        },
    },

    State{
        name = "beg",
        tags = {"canrotate","preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_beg")
        end,

        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/beg") end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "belly",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_belly")

            inst.bellysoundtask = inst:DoTaskInTime(math.random()*(81/30), function() inst.SoundEmitter:PlaySound("pl/creatures/pog/belly")   end )
        end,

        onexit = function(inst)
            inst.bellysoundtask:Cancel()
            inst.bellysoundtask = nil
        end,

        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/belly") end),
            TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/belly") end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },


    State{
        name = "bark_at_friend",
        tags = {"canrotate","preoccupied","busy"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("emote_stretch")
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) bark_at_friends(inst) end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/bark") end),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/bark") end),
        },
    },

    State{
        name = "walk_start",
        tags = {"moving", "canrotate","walk"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("walk") end ),
        },
    },

    State{
        name = "walk",
        tags = {"moving", "canrotate","walk"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop")
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("walk") end ),
        },
        timeline=
        {
            TimeEvent(FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(8*FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(15*FRAMES, function(inst) PlayFootstep(inst) end),
            TimeEvent(23*FRAMES, function(inst) PlayFootstep(inst) end),
        },
    },

    State{
        name = "walk_stop",
        tags = {"canrotate","walk"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "eat",
        tags = {"preoccupied"},

        onenter = function(inst,data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
        end,

        timeline=
        {
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/eat") end),
            ---TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/bark") end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                if inst:PerformBufferedAction() then
                    inst.sg:GoToState("eat_loop")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1+math.random()*1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

}
CommonStates.AddSimpleState(states,"refuse", "emote_stretch", {"busy"})
CommonStates.AddCombatStates(states,
{
	hittimeline = {},

	attacktimeline =
	{
        TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/bark") end),
        --TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/swipe_whoosh") end),
        TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
	},

	deathtimeline =
	{
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/death") end),
	},
},
{attack="attack"})

CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/yawn") end)
    },

    sleeptimeline =
    {
        TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/sleep",nil,.25) end)
    },

    waketimeline =
    {
        --TimeEvent(31*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/pickup") end)
    },
})
CommonStates.AddFrozenStates(states)

CommonStates.AddRunStates(
    states,
    {
        runtimeline =
        {
            --TimeEvent(5*FRAMES, function(inst)  end), --inst.SoundEmitter:PlaySound(inst.sounds.walk)
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("pl/creatures/pog/step") end)
        }
    })

return StateGraph("pog", states, events, "idle", actionhandlers)
