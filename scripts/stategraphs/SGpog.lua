require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.BARK, "bark_at_friend"),
    ActionHandler(ACTIONS.RANSACK, "ransack_pre"),
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(nil, TUNING.CHARACTER_MAX_STUN_LOCKS),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true, true),
    EventHandler("barked_at", function(inst, data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("preoccupied") and data.belly then
            inst.sg:GoToState("belly")
        else
            if inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end
    end),
}

local EAT_FOOD_DIST = 30
local EAT_FOOD_NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO", "poisonous"}
local function can_ransack(inst, target)
    if not target or not target:IsValid() or not (target.components.container or target.components.container_proxy) then
        return false
    end

    local food_on_ground = FindEntity(inst, EAT_FOOD_DIST, function(item) -- priorities
        return inst.components.eater:CanEat(item)
            and item:IsOnValidGround()
            and item:GetTimeAlive() > TUNING.POG_EAT_DELAY
    end, nil, EAT_FOOD_NO_TAGS)

    if food_on_ground then
        return false
    end

    if target.components.container_proxy then
        return not target.components.container_proxy:GetMaster().components.container:IsEmpty()
    end

    return not target.components.container:IsEmpty()
end

local function toss_items(inst, target)
    if not target or not target:IsValid() or not (target.components.container or target.components.container_proxy) then
        return
    end

    local container = target.components.container_proxy and target.components.container_proxy:GetMaster() or target

    local items = container.components.container:GetAllItems()
    if next(items) then
        local item = items[math.random(1, #items)]
        item = container.components.container:RemoveItem(item)

        local x, _, z = target.Transform:GetWorldPosition()
        item.Transform:SetPosition(x, 1, z)

        local vel = Vector3(0, 5, 0)
        local speed = 3 + math.random()
        local angle = math.random() * 2 * PI
        vel.x = speed * math.cos(angle)
        vel.y = speed * 3
        vel.z = speed * math.sin(angle)
        item.Physics:SetVel(vel.x, vel.y, vel.z)
    end
end

local BARK_AT_FRIENDS_RANGE = 4
local POG_TAGS = {"pog"}
local function bark_at_friends(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, BARK_AT_FRIENDS_RANGE, POG_TAGS)

    local nottriggered = true
    for _, ent in pairs(ents) do
        local belly = false
        if ent.sg:HasStateTag("idle") then
            if nottriggered then
                belly = true
                nottriggered = false
            end
        end
        inst:DoTaskInTime(math.random() * 0.3, function() ent:PushEvent("barked_at", {belly = belly}) end)
    end
end

local states =
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

                    inst.sg:SetTimeout(2 + 2 * math.random())
                end
            end
        end,

        ontimeout = function(inst)
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
            TimeEvent(4  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/cute") end),
            TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/cute") end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "tailchase",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("tailchase_loop")
            end),
        },
    },

    State{
        name = "tailchase_loop",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_loop")
        end,

        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < 0.3 then
                    inst.sg:GoToState("tailchase_loop")
                else
                    inst.sg:GoToState("tailchase_pst")
                end
            end),
        },
    },

    State{
        name = "tailchase_pst",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_tailchase_pst")
        end,

        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "ransack_pre",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("rummage_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("ransack")
            end),
        },
    },

    State{
        name = "ransack",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()

            local act = inst:GetBufferedAction()
            if act and act.target and act.target:HasTag("pogproof") then
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", "rummage_pst")
                inst.wantstobark = act.target
            else
                if not act or not can_ransack(inst, act.target) or act.target:HasTag("pogged") then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", "rummage_pst")
                else
                    inst.AnimState:PlayAnimation("rummage_loop")
                    inst.sg.statemem.ransack_target = act.target

                    act.target:AddTag("pogged")
                    if act.target.components.container_proxy then
                        act.target.components.container_proxy:Open(inst)
                    else
                        act.target.components.container:Open(inst)
                    end
                end
            end
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/rummage") end),
        },

        onupdate = function(inst)
            if not inst.sg.statemem.ransack_target
                or not inst.sg.statemem.ransack_target:IsValid()
                or not inst:IsNear(inst.sg.statemem.ransack_target, 1.5) then
                inst.sg:GoToState("idle", "rummage_pst")
            end
        end,

        onexit = function(inst)
            if inst.sg.statemem.ransack_target and inst.sg.statemem.ransack_target:IsValid() and not inst.keepransacking then
                if inst.sg.statemem.ransack_target.components.container_proxy then
                    inst.sg.statemem.ransack_target.components.container_proxy:Close(inst)
                else
                    inst.sg.statemem.ransack_target.components.container:Close(inst)
                end
                inst.sg.statemem.ransack_target:RemoveTag("pogged")
            end
            inst.keepransacking = nil
            inst:ClearBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.keepransacking = true
                inst.sg:GoToState("ransack_throw", inst.sg.statemem.ransack_target)
            end),
        },
    },

    State{
        name = "ransack_throw",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst, ransack_target)
            inst.AnimState:PlayAnimation("rummage_throw")
            inst.sg.statemem.ransack_target = ransack_target
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) toss_items(inst, inst.sg.statemem.ransack_target) end),
            TimeEvent(9  * FRAMES, function(inst) if math.random() < 0.5 then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark", nil, 0.5) end end),
            TimeEvent(16 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/make_whoosh") end),
        },

        onexit = function(inst)
            if inst.sg.statemem.ransack_target and inst.sg.statemem.ransack_target:IsValid() then
                if not inst.keepransacking then
                    if inst.sg.statemem.ransack_target.components.container_proxy then
                        inst.sg.statemem.ransack_target.components.container_proxy:Close(inst)
                    else
                        inst.sg.statemem.ransack_target.components.container:Close(inst)
                    end
                end
                inst.sg.statemem.ransack_target:RemoveTag("pogged")
            end
            inst.keepransacking = nil
            inst:ClearBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.keepransacking = true
                inst.sg:GoToState("ransack")
            end),
        },
    },

    State{
        name = "beg",
        tags = {"canrotate", "preoccupied"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_beg")
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/beg") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "belly",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_belly")

            -- why this number?
            inst.bellysoundtask = inst:DoTaskInTime(math.random() * (81 / 30), function() inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/belly") end)
        end,

        onexit = function(inst)
            inst.bellysoundtask:Cancel()
            inst.bellysoundtask = nil
        end,

        timeline =
        {
            TimeEvent(1  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/belly") end),
            TimeEvent(45 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/belly") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "bark_at_friend",
        tags = {"canrotate", "preoccupied", "busy"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("emote_stretch")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) bark_at_friends(inst) end),
            TimeEvent(8  * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "eat",
        tags = {"busy", "preoccupied"},

        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/eat") end),
        },

        events =
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
            inst.sg:SetTimeout(1 + math.random())
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },

}

CommonStates.AddSimpleState(states,"refuse", "emote_stretch", {"busy"})
CommonStates.AddCombatStates(states, {
    attacktimeline =
    {
        TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/bark") end),
        TimeEvent(16 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.components.combat.target) end),
    },

    deathtimeline =
    {
        TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/death") end),
    },
}, {attack = "attack"})
CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/yawn") end)
    },

    sleeptimeline =
    {
        TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/sleep", nil, 0.25) end)
    },
})
CommonStates.AddFrozenStates(states)
CommonStates.AddWalkStates(states, {
    walktimeline = {
        TimeEvent(1  * FRAMES, function(inst) PlayFootstep(inst) end),
        TimeEvent(8  * FRAMES, function(inst) PlayFootstep(inst) end),
        TimeEvent(15 * FRAMES, function(inst) PlayFootstep(inst) end),
        TimeEvent(23 * FRAMES, function(inst) PlayFootstep(inst) end),
    }
})
CommonStates.AddRunStates(states, {
    runtimeline =
    {
        TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/pog/step") end)
    }
})

return StateGraph("pog", states, events, "idle", actionhandlers)
