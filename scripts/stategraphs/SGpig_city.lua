require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "gohome"),
    ActionHandler(ACTIONS.WALKTO, "daily_gift"),
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.CHOP, "chop"),
    ActionHandler(ACTIONS.FIX, "chop"),
    ActionHandler(ACTIONS.POOP_TIP, "poop_tip"),
    ActionHandler(ACTIONS.PAY_TAX, "pay_tax"),
    ActionHandler(ACTIONS.DAILY_GIFT, "daily_gift"),
    ActionHandler(ACTIONS.SIT_AT_DESK, "desk_pre"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
    ActionHandler(ACTIONS.EQUIP, "pickup"),
    ActionHandler(ACTIONS.ADDFUEL, "pickup"),
    ActionHandler(ACTIONS.TAKEITEM, "pickup"),
    ActionHandler(ACTIONS.STOCK, "interact"),
    ActionHandler(ACTIONS.MANUALEXTINGUISH, "interact"),
    ActionHandler(ACTIONS.UNPIN, "pickup"),
}

local events=
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(nil, TUNING.CHARACTER_MAX_STUN_LOCKS),
    CommonHandlers.OnDeath(),

    EventHandler("behappy", function(inst, data)
        inst.sg:GoToState("happy")
    end),
    EventHandler("dance", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("dance")
        end
    end),
    EventHandler("onsurprised", function(inst, data)
        if inst.components.health ~= nil and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("hit")
        end
    end),
}

local states =
{
     State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            local anim = "idle_loop"

            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation(anim, true)
            else
                inst.AnimState:PlayAnimation(anim, true)
            end
        end,

       events =
        {
            EventHandler("animover", function(inst)
                if TheWorld.state.isfiesta and  math.random() < 0.5 then
                    if math.random() < 0.3 then
                        inst.sg:GoToState("throwcracker")
                    else
                        inst.sg:GoToState("dance")
                    end
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "dance",
        tags = {"canrotate", "busy"},

        onenter = function(inst, pushanim)
            if math.random() < 0.3 then
                inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_FIESTA"))
            end
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_happy")
        end,

       events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "throwcracker",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("interact")
            inst.Physics:Stop()
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst.throwcrackers(inst)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "alert",
        tags = {"idle", "alert"},

        onenter = function(inst)
            if inst.alerted then
                inst.sg:GoToState("idle")
                inst.sg:AddStateTag("alert")
            else
                inst.alerted = true
                inst:DoTaskInTime(120, function(inst) inst.alerted = nil end)

                inst.Physics:Stop()
                if not TheWorld.state.isnight then
                    --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/conversational_talk")
                    if (inst:HasTag("emote_nohat") or math.random() < 0.3) and not inst:HasTag("emote_nocurtsy") then
                        inst.AnimState:PlayAnimation("emote_bow")
                    else
                        inst.AnimState:PlayAnimation("emote_hat")
                    end
                end
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "happy",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_happy")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/death")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

    },

    State{
        name = "abandon",
        tags = {"busy"},

        onenter = function(inst, leader)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("abandon")
            inst:FacePoint(Vector3(leader.Transform:GetWorldPosition()))
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst)
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip then
                if equip.prefab == "torch" then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_firestaff",nil,.5)
                elseif equip.prefab == "halberd" then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/weapon/halberd")
                end
            end
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

    State{
        name = "interact",
        tags = {"interact", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("interact")
        end,

        timeline =
        {

            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "chop",
        tags = {"chopping"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/house_repair")
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "desk_pre",
        tags = {"desk"},

        onenter = function(inst)
            inst.separatedesk(inst, false)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_table_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.keepdesk = true inst.sg:GoToState("desk_idle") end),
        },

        onexit = function(inst)
            if inst.keepdesk then
                inst.keepdesk = nil
            else
               inst.separatedesk(inst, true)
            end
        end
    },

    State{
        name = "desk_idle",
        tags = {"desk"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_table_loop", true)
        end,

        onexit = function(inst)
            if inst.keepdesk then
                inst.keepdesk = nil
            else
               inst.separatedesk(inst, true)
            end
        end
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            if not inst:HasTag("guard") then
                if inst.female then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/scream_female", nil, 0.25)
                else
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/scream", nil, 0.25)
                end
            end

            if inst:HasTag("guard") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/iron_armor/hit")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/city_pig/guard_alert")
            end
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()

            inst.components.combat.laststartattacktime = 0

            if inst:HasTag("guard") then
                CommonHandlers.UpdateHitRecoveryDelay(inst)
            end
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function (inst) if inst:HasTag("guard") then inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/iron_armor/foley") end end),
            TimeEvent(13 * FRAMES, function (inst) if inst:HasTag("guard") then inst.sg:GoToState("idle") end end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "poop_tip",
        tags = {"busy"},

        onenter = function(inst)
            if inst.poop_tip then
                local line = inst.poop_tip:HasTag("pigroyalty")
                    and inst:GetSpeechType("CITY_PIG_TALK_ROYAL_POOPTIP")
                    or inst:GetSpeechType("CITY_PIG_TALK_POOPTIP")
                inst:SayLine(line)
            end
            inst.AnimState:PlayAnimation("interact")
            inst.Physics:Stop()
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover",
                function(inst)
                    inst.sg:GoToState("idle")
                    inst.poop_tip = nil
                    inst.tipping = false
                end
            ),
        },
    },

    State{
        name = "pay_tax",
        tags = {"busy"},

        onenter = function(inst)
            inst:SayLine(inst:GetSpeechType("CITY_PIG_TALK_PAYTAX"))
            inst.AnimState:PlayAnimation("interact")
            inst.Physics:Stop()
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover",
                function(inst)
                    inst.sg:GoToState("idle")
                end
            ),
        },
    },

    State{
        name = "daily_gift",
        tags = {"busy"},

        onenter = function(inst)
            local speech = TheWorld.state.isfiesta
                and inst:GetSpeechType("CITY_PIG_TALK_APORKALYPSE_REWARD")
                or inst:GetSpeechType("CITY_PIG_TALK_DAILYGIFT")
            inst:SayLine(speech)
            inst.AnimState:PlayAnimation("interact")
            inst.Physics:Stop()
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover",
                function(inst)
                    inst.sg:GoToState("idle")
                    inst:DoTaskInTime(4, function() inst.daily_gifting = false end)
                end ),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline = {
        TimeEvent(0 * FRAMES, function(inst)
                PlayFootstep(inst)
                if inst:HasTag("guard") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/iron_armor/foley")
                end
            end ),
        TimeEvent(12 * FRAMES, function(inst)
                PlayFootstep(inst)
                if inst:HasTag("guard") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/iron_armor/foley")
                end
            end),
    },
})
CommonStates.AddRunStates(states,
{
    runtimeline = {
        TimeEvent(0 * FRAMES, PlayFootstep),

        TimeEvent(3 * FRAMES, function(inst)
                -- PlayFootstep(inst)
                if inst:HasTag("guard") then
                   inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/iron_armor/foley")
                end
            end),

        TimeEvent(10 * FRAMES, PlayFootstep),

        TimeEvent(11 * FRAMES, function(inst)
            -- PlayFootstep(inst)
            if inst:HasTag("guard") then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/iron_armor/foley")
            end

            -- Prevents shopkeepers from getting stuck on pedestals while restocking items, which is quite common.
            if inst:HasTag("shopkeep") and inst.changestock then
                inst.components.locomotor:ResetPath()
            end
        end),
    },
})

CommonStates.AddSleepStates(states,
{
    sleeptimeline =
    {
        TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/pig/sleep") end),
    },
})

CommonStates.AddSimpleState(states,"refuse", "pig_reject", {"busy"})
CommonStates.AddFrozenStates(states)

CommonStates.AddSimpleActionState(states,"pickup", "pig_pickup", 10 * FRAMES, {"busy"})
CommonStates.AddSimpleActionState(states, "gohome", "pig_pickup", 4 * FRAMES, {"busy"})

return StateGraph("pig", states, events, "idle", actionhandlers)
