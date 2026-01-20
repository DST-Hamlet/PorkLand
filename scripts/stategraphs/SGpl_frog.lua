require("stategraphs/commonstates")


local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.GOHOME, "action"),
}

local events=
{
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end

        if not inst.components.locomotor:WantsToMoveForward() then
            if not inst.sg:HasStateTag("idle") then
                inst.sg:GoToState("idle")
            end
        else
            local x, y, z = inst.Transform:GetWorldPosition()
            if not TheWorld.Map:IsPassableAtPoint(x, y, z) then
                if not inst.sg:HasStateTag("swimming") then
                    inst.sg:GoToState("swim")
                end
            else
                if not inst.sg:HasStateTag("hopping") then
                    if inst.components.locomotor:WantsToRun() then
                        inst.sg:GoToState("aggressivehop")
                    else
                        inst.sg:GoToState("hop")
                    end
                end
            end
        end
    end),
    EventHandler("trapped", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("trapped")
        end
    end),

    EventHandler("switch_to_water", function(inst)
        inst.components.locomotor.walkspeed = 3

        local noanim = inst:GetTimeAlive() < 1
        inst.sg:GoToState("submerge", noanim)
    end),
    EventHandler("switch_to_land", function(inst)
        inst.components.locomotor.walkspeed = 4

        local noanim = inst:GetTimeAlive() < 1
        inst.sg:GoToState("emerge", noanim)
    end),
}

local FROG_TAGS = {"frog"}
local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()

            local anim = inst.islunar and math.random() <= 0.7 and "idle2" or "idle"

            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation(anim, true)

            elseif inst.AnimState:IsCurrentAnimation("idle") or inst.AnimState:IsCurrentAnimation("idle2") then
                inst.AnimState:PushAnimation(anim, true)
            else
                inst.AnimState:PlayAnimation(anim, true)
            end

            inst.sg:SetTimeout(1*math.random()+.5)
        end,

        ontimeout= function(inst)
            if inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("hop")
            else
                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 10, FROG_TAGS)

                local volume = math.max(0.5, 1 - (#ents - 1) * 0.1)
                inst.SoundEmitter:PlaySound(inst.sounds.grunt, nil, volume)

                inst.sg:GoToState("idle")
            end
        end,
    },

    State{

        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
            inst:PerformBufferedAction()
        end,
        events=
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "aggressivehop",
        tags = {"moving", "canrotate", "hopping", "running"},

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.locomotor:RunForward()
            end ),
            TimeEvent(20*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.walk)
                inst.Physics:Stop()
            end ),
        },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("jump_pre")
            inst.AnimState:PushAnimation("jump")
            inst.AnimState:PushAnimation("jump_pst", false)
        end,

        events=
        {
            EventHandler("animqueueover", function (inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hop",
        tags = {"moving", "canrotate", "hopping"},

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.locomotor:WalkForward()
            end ),
            TimeEvent(20*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.walk)
                inst.Physics:Stop()
            end ),
        },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("jump_pre")
            inst.AnimState:PushAnimation("jump")
            inst.AnimState:PushAnimation("jump_pst", false)
        end,

        events=
        {
            EventHandler("animqueueover", function (inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "swim",
        tags = {"moving", "canrotate", "swimming"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("swim_pre")
            if inst.components.burnable:IsBurning() then
                inst.components.burnable:Extinguish()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("swim_loop") end),
        },
    },

    State{
        name = "swim_loop",
        tags = {"moving", "canrotate", "swimming"},


        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("swim",true)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("swim_loop") end ),
        },
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,

        timeline =
        {
            TimeEvent(18 * FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/water/small_submerge")
                end
            end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack_spit) end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack_voice) end),
            TimeEvent(25 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(38 * FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) then
                    inst.SoundEmitter:PlaySound("dontstarve_DLC003/movement/water/small_splash")
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "fall",
        tags = {"busy", "falling"},

        onenter = function(inst)
            inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0, -20 + math.random() * 10,0)
            inst.AnimState:PlayAnimation("fall_idle", true)
        end,

        onupdate = function(inst)
            local pt = Point(inst.Transform:GetWorldPosition())
            if pt.y < 2 then
                inst.Physics:SetMotorVel(0,0,0)
                inst.DynamicShadow:Enable(true)
            end

            if pt.y <= .1 then
                pt.y = 0

                inst.Physics:Stop()
                inst.Physics:SetDamping(5)
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
                inst.SoundEmitter:PlaySound(inst.sounds.splat)
                if TheWorld.Map:ReverseIsVisualWaterAtPoint(pt.x,pt.y,pt.z) then
                    inst.sg:GoToState("idle", "jumpin_pst")
                    inst.DynamicShadow:Enable(false)
                else
                    inst.sg:GoToState("idle", "jump_pst")
                    inst.DynamicShadow:Enable(true)
                end
            end
        end,

        onexit = function(inst)
            local pt = inst:GetPosition()
            pt.y = 0
            inst.Physics:SetMotorVel(0,0,0)
            inst.Transform:SetPosition(pt:Get())

            -- The Y position prevents them from targeting the player on spawn by the herald.
            if inst:HasTag("aporkalypse_cleanup") and inst.components.combat then
                local target_radius = 20
                inst.components.combat:SuggestTarget(FindClosestPlayerInRange(pt.x, pt.y, pt.z, target_radius, true))
            end
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.die)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,
    },

    State{
        name = "trapped",
        tags = { "busy", "trapped"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.sg:SetTimeout(1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "emerge",
        tags = {"canrotate", "busy"},

        onenter = function(inst, noanim)
            if noanim then
                inst.sg:GoToState("idle")
                return
            end

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("frog_water")
            inst.AnimState:PlayAnimation("jumpout_pre")
        end,

        onexit = function(inst)
            inst.components.amphibiouscreature:RefreshBankFn()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("emerge_finish")
            end),
        },
    },

    State{
        name = "emerge_finish",
        tags = {"canrotate", "busy"},

        onenter = function(inst)
            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end
            inst.AnimState:SetBank("frog_water")
            inst.AnimState:PlayAnimation("jumpout")
        end,

        onexit = function(inst)
            inst.components.amphibiouscreature:RefreshBankFn()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "submerge",
        tags = {"canrotate", "busy"},

        onenter = function(inst, noanim)
            if noanim then
                inst.AnimState:SetBank("frog_water")
                inst.sg:GoToState("idle")
                return
            end

            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end

            inst.AnimState:SetBank("frog_water")
            inst.AnimState:PlayAnimation("jumpin_pre")
        end,

        onexit = function(inst)
            inst.components.amphibiouscreature:RefreshBankFn()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("submerge_finish")
            end),
        },
    },

    State{
        name = "submerge_finish",
        tags = {"canrotate", "busy"},

        onenter = function(inst)
            local should_move = inst.components.locomotor:WantsToMoveForward()
            local should_run = inst.components.locomotor:WantsToRun()
            if should_move then
                inst.components.locomotor:WalkForward()
            elseif should_run then
                inst.components.locomotor:RunForward()
            end

            inst.AnimState:PlayAnimation("jumpin")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "eat",
        tags = {"canrotate", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat_loop", false)
            inst.AnimState:PushAnimation("eat_pst", false)
        end,

        timeline=
        {
            TimeEvent(17 * FRAMES, function(inst) inst:PerformBufferedAction() end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.grunt) end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddSleepStates(states,
{
    waketimeline = {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.wake) end ),
    },
})
CommonStates.AddFrozenStates(states)

return StateGraph("pl_frog", states, events, "idle", actionhandlers)
