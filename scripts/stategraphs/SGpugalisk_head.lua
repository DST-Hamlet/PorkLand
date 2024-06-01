require("stategraphs/commonstates")

local PugaliskUtil = require ("prefabs/pugalisk_util")

local actionhandlers =
{

}

local SHAKE_DIST = 40

local function dogroundpound(inst)
    inst.components.groundpounder:GroundPound()
    ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.03, 2, inst, SHAKE_DIST)
end

local function spawngaze(inst)
    local beam = SpawnPrefab("gaze_beam")
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local angle = inst.Transform:GetRotation() * DEGREES
    local radius = 4
    local offset = Vector3(math.cos(angle), 0, math.sin(-angle)) * radius
    local newpt = pt + offset

    beam.Transform:SetPosition(newpt.x, newpt.y, newpt.z)
    beam.host = inst
    beam.Transform:SetRotation(inst.Transform:GetRotation())
end

local function endgaze(inst)
    if inst.gazetask then
        inst.gazetask:Cancel()
        inst.gazetask = nil
    end
end

local function dogaze(inst)
    if inst.gazetask then
        endgaze(inst)
    end
    inst.gazetask = inst:DoPeriodicTask(0.4, spawngaze)
end

local events =
{
    EventHandler("tail_should_exit", function(inst)
        inst:AddTag("should_exit")
        inst.sg:GoToState("tail_exit")
    end),

    EventHandler("stopgaze", function(inst)
        if inst.sg:HasStateTag("gazing") then
            inst.sg:GoToState("gaze_pst")
        end
    end),

    EventHandler("dogaze", function(inst)
        inst.sg:GoToState("gaze")
    end),

    EventHandler("attacked", function(inst, data)
        if inst.sg:HasStateTag("idle") and not inst:HasTag("tail") and data.vulnerable_segment then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("attack", data.target)
        end
    end),

    EventHandler("death", function(inst)
        if inst:HasTag("tail") then
            inst.sg:GoToState("tail_exit")
        else
            if inst.sg:HasStateTag("underground") then
                inst.sg:GoToState("death_underground")
            else
                inst.sg:GoToState("death")
            end
        end
    end),

    EventHandler("backup", function(inst)
        if not inst.sg:HasStateTag("backup") and not inst.components.health:IsDead() then
            inst.sg:GoToState("backup")
        end
    end),

    EventHandler("premove", function(inst)
        if not inst.sg:HasStateTag("backup") and not inst.components.health:IsDead() and  not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("startmove")
        end
    end),

    EventHandler("emerge", function(inst)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("emerge")
        end
    end),
}

local states =
{
    State{
        name = "death_underground",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death_underground")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if not inst:HasTag("tail") then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local corpse = SpawnPrefab("pugalisk_corpse")
                    corpse.Transform:SetPosition(x, y, z)
                    inst:Remove()
                end
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            if inst:HasTag("tail") then
                inst.AnimState:PlayAnimation("tail_idle_pst")
                inst.AnimState:PushAnimation("dirt_collapse_slow", false)
            else
                inst.AnimState:PlayAnimation("death")
            end
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot()
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/death") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if not inst:HasTag("tail") then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local corpse = SpawnPrefab("pugalisk_corpse")
                    corpse.Transform:SetPosition(x, y, z)
                    inst:Remove()
                end
            end),
        },
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            if inst:HasTag("tail") then
                if start_anim then
                    inst.AnimState:PlayAnimation(start_anim)
                    inst.AnimState:PushAnimation("tail_idle_loop", true)
                else
                    inst.AnimState:PlayAnimation("tail_idle_loop", true)
                end
            else
                if start_anim then
                    inst.AnimState:PlayAnimation(start_anim)
                    inst.AnimState:PushAnimation("head_idle_loop", true)
                else
                    inst.AnimState:PlayAnimation("head_idle_loop", true)
                end
            end
        end,

        onupdate = function(inst)
            if not inst:HasTag("tail") then
                if inst.wantstogaze then
                    inst.sg:GoToState("gaze")
                elseif inst.wantstotaunt then
                    inst.sg:GoToState("tongue")
                end

                if inst.wantstopremove then
                    inst.wantstopremove = nil
                    inst:PushEvent("premove")
                end
            end

            if inst:HasTag("tail") and inst:HasTag("should_exit") then
                inst.sg:GoToState("tail_exit")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"canrotate"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/hit") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "tongue",
        tags = {"canrotate", "busy"},

        onenter = function(inst, start_anim)
            if inst:HasTag("tail") then
                return
            end

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.wantstotaunt = nil
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/taunt") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "emerge_taunt",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emerge_taunt")
            inst.wantstotaunt = nil
        end,

        timeline =
        {
            TimeEvent(1 * FRAMES, function(inst)
                inst.components.groundpounder.numRings = 3
                dogroundpound(inst)
                inst.components.groundpounder.numRings = 2
                inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/volcano/volcano_erupt")
            end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/taunt") end),
            TimeEvent(15 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/attack") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "dirt_collapse",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("dirt_collapse", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "tail_exit",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("tail_idle_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("dirt_collapse")
            end),
        },
    },

    State{
        name = "tail_ready",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("tail_idle_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "gaze",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("gaze_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("gaze_loop")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/gaze_start")
            end),
        },
    },

    State{
        name = "gaze_loop",
        tags = {"busy","canrotate", "gazing"},

        onenter = function(inst, start_anim)
            dogaze(inst)
            inst.AnimState:PlayAnimation("gaze_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/gaze_LP", "gazor")
        end,

        timeline =
        {
            TimeEvent(45 * FRAMES, function(inst) dogaze(inst) end),
        },

        onupdate = function(inst)
            local target = PugaliskUtil.FindCurrentTarget(inst)
            if not inst.wantstogaze then
                inst.sg:GoToState("gaze_pst")
            else
                if target then
                    local pt = Vector3(target.Transform:GetWorldPosition())
                    local angle = inst:GetAngleToPoint(pt)
                    inst.Transform:SetRotation(angle)
                end
            end
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("gazor")
            endgaze(inst)
        end,

        events =
        {
        },
    },

    State{
        name = "gaze_pst",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.AnimState:PlayAnimation("gaze_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "emerge",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.emerged = true
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("head_idle_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "underground",
        tags = {"underground", "invisible"},

        onenter = function(inst, start_anim)
            inst:Hide()
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("head_idle_pre")
        end,

        onexit = function(inst)
            inst:Show()
            inst.Physics:SetActive(true)
            inst.movecommited = nil
        end,
    },

    State{
        name = "startmove",
        tags = {"busy", "backup"},

        onenter = function(inst, start_anim)
            inst:PushEvent("startmove")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("head_idle_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local pos = Vector3(inst.Transform:GetWorldPosition())
                inst.components.multibody:SpawnBody(inst.angle,0.3,pos)
                inst.sg:GoToState("underground")
            end),
        },
    },

    State{
        name = "backup",
        tags = {"busy","backup"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("head_idle_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local hole = SpawnPrefab("pugalisk_body")
                hole:AddTag("exithole")
                hole.Physics:SetActive(false)
                hole.Transform:SetPosition(inst.Transform:GetWorldPosition())
                hole.AnimState:PlayAnimation("dirt_collapse", false)
                hole:ListenForEvent("animover", function(inst, data)
                       hole:Remove()
                    end)
                inst:DoTaskInTime(0.75, function()
                    PugaliskUtil.RecoverFromBadAngle(inst)
                    inst.movecommited = false
                    dogroundpound(inst)
                    inst.sg:GoToState("emerge")
                end)
                inst.movecommited = true
                inst.sg:GoToState("underground")
            end),
        },
    },

    State{
        name = "hole",
        tags = {"busy"},

        onenter = function(inst, start_anim)
            inst.AnimState:SetBank("giant_snake")
            inst.AnimState:SetBuild("python_test")

            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("dirt_static")
        end,
    },

    State{
        name = "attack",
        tags = {"attack", "canrotate", "busy",},

        onenter = function(inst, target)
            inst.components.combat:StartAttack()
            if inst:HasTag("tail") then
                inst.AnimState:PlayAnimation("tail_smack")
            else
                inst.AnimState:PlayAnimation("atk")
            end
            inst.sg.statemem.target = target
        end,

        timeline =
        {
            TimeEvent(3  * FRAMES, function(inst) if not inst:HasTag("tail") then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/attack") end end),
            TimeEvent(6  * FRAMES, function(inst) if not inst:HasTag("tail") then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/attack_pre") end end),
            TimeEvent(7  * FRAMES, function(inst) if inst:HasTag("tail") then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/tail_attack") end end),
            TimeEvent(17 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(18 * FRAMES, function(inst) if not inst:HasTag("tail") then inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/pugalisk/bite") end end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

-- CommonStates.AddSleepStates(states,
-- {
--     starttimeline = {
--         TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("fallAsleep") end ),
--     },
--     sleeptimeline =
--     {
--         TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("sleeping") end ),
--     },
--     waketimeline = {
--         TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("wakeUp") end ),
--     },
-- })
CommonStates.AddFrozenStates(states)

return StateGraph("pugalisk_head", states, events, "idle", actionhandlers)
