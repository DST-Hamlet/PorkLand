require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),

    EventHandler("doattack", function(inst)
        if inst.components.health and not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("gore")
        end
    end),
    EventHandler("doleapattack", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("leap_attack_pre", data.target)
        end
    end),

    CommonHandlers.OnExitWater(),
    CommonHandlers.OnEnterWater(),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("charge")
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,

       timeline =
        {
            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/out") end),
            TimeEvent(26 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/in") end),
            TimeEvent(46 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/out") end),
            TimeEvent(57 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/in") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < 0.05 and inst:HasTag("huff_idle") then
                    inst.sg:GoToState("huff")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "gore",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,

        timeline =
        {
           TimeEvent(16 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
           TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/leap_attack") end),

        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "leap_attack_pre",
        tags = {"attack", "canrotate", "busy", "leapattack_pre"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_atk_pre")
            inst.sg.statemem.startpos = inst:GetPosition()
            inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack", {startpos = inst.sg.statemem.startpos, targetpos = inst.sg.statemem.targetpos}) end),
        },
    },

    State{
        name = "leap_attack",
        tags = {"attack", "busy", "leapattack"},

        onenter = function(inst, data)
            inst.sg.statemem.startpos = data.startpos
            inst.sg.statemem.targetpos = data.targetpos
            inst.sg.statemem.leap_time = 0
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("jump_atk_loop")
            inst:ForceFacePoint(inst.sg.statemem.targetpos)

            local time = inst.AnimState:GetCurrentAnimationLength()
            local dist = math.sqrt(distsq(inst.sg.statemem.startpos.x, inst.sg.statemem.startpos.z, inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z))
            local vel = dist/time
            inst.sg.statemem.vel = vel

            local newmass = inst.Physics:GetMass()
            local newrad = inst.Physics:GetRadius()
            ChangeToJunmpingPhysics(inst, newmass, newrad)

            inst.Physics:SetMotorVelOverride(vel,0,0)
        end,

        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()

            local newmass = inst.Physics:GetMass()
            local newrad = inst.Physics:GetRadius()
            ChangeToAmphibiousCharacterPhysics(inst, newmass, newrad)

            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.sg.statemem.startpos = nil
            inst.sg.statemem.targetpos = nil
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/leap_attack") end ),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack_pst") end),
        },
    },

    State{
        name = "leap_attack_pst",
        tags = {"busy"},

        onenter = function(inst, target)
            local x, y, z = inst.Transform:GetWorldPosition()
            if not TheWorld.Map:IsOceanTileAtPoint(x, y, z) then
                local entities_hit = {}
                inst.components.groundpounder:GroundPound(nil, entities_hit)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound", nil, 0.5)

                -- first ground pound has a delay of 0s, the rest is "inst.components.groundpounder.ringDelay"
                inst:DoTaskInTime(math.max(inst.components.groundpounder.numRings - 1, 0) * inst.components.groundpounder.ringDelay, function()
                    if not next(entities_hit) then
                        inst:PushEvent("onmissother")
                    end
                end)
            else
                TheWorld.components.worldwavemanager:SpawnWaveCircle(inst, 12, 360, 4, nil, nil, nil, true)

                local old_damageRings = inst.components.groundpounder.damageRings
                local old_numRings = inst.components.groundpounder.numRings
                local old_groundpoundfx = inst.components.groundpounder.groundpoundfx
                local old_groundpoundringfx = inst.components.groundpounder.groundpoundringfx

                inst.components.groundpounder.damageRings = 1
                inst.components.groundpounder.numRings = 1
                inst.components.groundpounder.groundpoundfx = "splash_water_drop"
                inst.components.groundpounder.groundpoundringfx = "bombsplash"

                inst.components.groundpounder:GroundPound()

                inst.components.groundpounder.damageRings = old_damageRings
                inst.components.groundpounder.numRings = old_numRings
                inst.components.groundpounder.groundpoundfx = old_groundpoundfx
                inst.components.groundpounder.groundpoundringfx = old_groundpoundringfx
            end

            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_atk_pst")
        end,

        onexit = function(inst)
            inst.components.combat.lastattacktime = GetTime()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "huff",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("charge")

            inst.AnimState:PlayAnimation("idle_huff")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/huff_in") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/huff_out") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < 0.1 then
                    inst.sg:GoToState("huff")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {

            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/taunt") end),
            TimeEvent(29 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/attack") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
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

            inst.AnimState:SetBank("hippo_water")
            inst.AnimState:PlayAnimation("emerge")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/water_emerge_med") end),
        },

        onexit = function(inst)
            inst.components.amphibiouscreature:RefreshBankFn()
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/walk")
        end,

        events =
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
                inst.AnimState:SetBank("hippo_water")
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

            inst.AnimState:SetBank("hippo_water")
            inst.AnimState:PlayAnimation("submerge")
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/seacreature_movement/water_submerge_med")
                TheWorld.components.worldwavemanager:SpawnWaveCircle(inst, 6, 360, 2, "wave_ripple", nil, nil, nil, true)
            end),
        },

        onexit = function(inst)
            inst.components.amphibiouscreature:RefreshBankFn()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

CommonStates.AddWalkStates(states, {
    starttimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end),
    },

    walktimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end),
        TimeEvent(6 * FRAMES, function(inst) inst.components.locomotor:WalkForward() end),
        TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/in") end),
        TimeEvent(18 * FRAMES, function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/walk")
            end
        end ),
        TimeEvent(19 * FRAMES, function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
                ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.05, 0.05, inst, 40)
            else
                TheWorld.components.worldwavemanager:SpawnWaveCircle(inst, 6, 360, 2, "wave_ripple", nil, nil, nil, true)
            end
            inst.Physics:Stop()
        end),
    },
}, nil, true)

CommonStates.AddRunStates(states,{
    starttimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end),
    },

    runtimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.Physics:Stop() end),
        TimeEvent(6 * FRAMES, function(inst) inst.components.locomotor:WalkForward() end),
        TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/in") end),
        TimeEvent(18 * FRAMES, function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/walk")
            end
        end ),
        TimeEvent(19 * FRAMES, function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
                ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.05, 0.05, inst, 40)
            else
                TheWorld.components.worldwavemanager:SpawnWaveCircle(inst, 6, 360, 2, "wave_ripple", nil, nil, nil, true)
            end
            inst.Physics:Stop()
        end),
    },
}, {startrun = "walk_pre", run = "walk_loop", stoprun = "walk_pst"}, true)

CommonStates.AddSleepStates(states, {
    sleeptimeline =
    {
        TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/huff_in") end),
    },
})

CommonStates.AddCombatStates(states, {
    attacktimeline =
    {
        TimeEvent(4 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/attack") end),
        TimeEvent(17 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
    },

    hittimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/hit") end),
    },

    deathtimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/death") end),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("hippopotamoose", states, events, "idle", actionhandlers)
