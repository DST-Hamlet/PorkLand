local assets =
{
    Asset("ANIM", "anim/spear_trap.zip"),
}

local SPEAR_STATUS =
{
    IDLE = 0,
    EXTENDED = 1,
}

local function displaynamefn(inst, viewer)
    if inst:HasTag("hostile") then
        return STRINGS.NAMES.PIG_RUINS_SPEAR_TRAP_TRIGGERED
    end
end

local function OnBurnt(inst)
    local debris = SpawnPrefab("pig_ruins_spear_trap_broken")
    debris.AnimState:PlayAnimation("burnt")
    debris.Transform:SetPosition(inst.Transform:GetWorldPosition())
    debris.isburnt = true
    inst:Remove()
end

local function OnKilled(inst)
    if inst.components.burnable:IsBurning() then
        OnBurnt(inst)
        return
    end
    local debris = SpawnPrefab("pig_ruins_spear_trap_broken")
    debris.AnimState:PlayAnimation("breaking")
    debris.AnimState:PushAnimation("broken", true)
    debris.Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/speartrap_break")
    inst:Remove()
end

local function OnHit(inst)
    inst:PushEvent("hit")
end

local function cycletrapup(inst)
    if not inst:HasTag("burnt") and not inst:HasTag("dead") then
        if inst.sg:HasStateTag("retracted") then
            inst:PushEvent("triggertrap")
        end
    end
    inst.components.timer:StartTimer("trap_down", inst.down_delay)
end

local function cycletrapdown(inst)
    if not inst:HasTag("burnt") and not inst:HasTag("dead") then
        if inst.sg:HasStateTag("extended") then
            inst:PushEvent("reset")
        end
    end
    inst.components.timer:StartTimer("trap_up", inst.up_delay)
end

local function OnTimerDone(inst, data)
    local name = data.name
    if name == "trap_up" then
        cycletrapup(inst)
    elseif name == "trap_down" then
        cycletrapdown(inst)
    end
end

local function ResumeTimers(inst)
    inst.components.timer:ResumeTimer("trap_up")
    inst.components.timer:ResumeTimer("trap_down")
end

local function PauseTimers(inst)
    inst.components.timer:PauseTimer("trap_up")
    inst.components.timer:PauseTimer("trap_down")
end

local function canbeattackedfn(inst)
    return not (inst:HasTag("burnt") or inst:HasTag("dead"))
end

local function OnSave(inst, data)
    if inst.targetstaus then
        data.targetstaus = inst.targetstaus
    end

    if inst:HasTag("up_3") then
        data.up_3 = true
    end
    if inst:HasTag("down_6") then
        data.down_6 = true
    end
    if inst:HasTag("delay_3") then
        data.delay_3 = true
    end
    if inst:HasTag("delay_6") then
        data.delay_6 = true
    end
    if inst:HasTag("delay_9") then
        data.delay_9 = true
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end
    if data.targetstaus and data.targetstaus == SPEAR_STATUS.EXTENDED then
        inst.sg:GoToState("extended")
        inst.targetstaus = data.targetstaus
    end
    if data.up_3 then
        inst:AddTag("up_3")
    end
    if data.down_6 then
        inst:AddTag("down_6")
    end
    if data.delay_3 then
        inst:AddTag("delay_3")
    end
    if data.delay_6 then
        inst:AddTag("delay_6")
    end
    if data.delay_9 then
        inst:AddTag("delay_9")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.AnimState:SetBank("spear_trap")
    inst.AnimState:SetBuild("spear_trap")
    inst.AnimState:PlayAnimation("idle_retract")

    inst.MiniMapEntity:SetIcon("")

    inst.Physics:SetActive(false)

    inst:AddTag("spear_trap")
    inst:AddTag("structure")
    inst:AddTag("mech")

    inst.displaynamefn = displaynamefn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst:AddComponent("hiddendanger")

    inst:AddComponent("inspectable")
    -- inst.components.inspectable.descriptionfn = descriptionfn

    MakeHauntable(inst)

    inst:AddComponent("shearable")
    inst.components.shearable:SetOnShearFn(OnKilled)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SPEAR_TRAP_HEALTH)
    inst.components.health.nofadeout = true

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst.components.combat:SetDefaultDamage(TUNING.SPEAR_TRAP_DAMNAGE)
    inst.components.combat.canbeattackedfn = canbeattackedfn

    MakeSmallBurnable(inst)
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 2 + math.random()*2

    inst:SetStateGraph("SGspear_trap")

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnEntitySleep = PauseTimers
    inst.OnEntityWake = ResumeTimers

    inst:ListenForEvent("death", OnKilled)
    inst:ListenForEvent("triggertrap", function(inst, data)
        inst.triggertask = inst:DoTaskInTime(math.random() * 0.25, function()
            inst:PushEvent("spring")
        end)
    end)
    inst:ListenForEvent("triggertrap", function(inst, data)
        inst.targetstaus = SPEAR_STATUS.EXTENDED
    end)
    inst:ListenForEvent("reset", function(inst, data)
        inst.targetstaus = SPEAR_STATUS.IDLE
    end)

    inst.up_delay = 1
    inst.down_delay = 3

    inst:DoTaskInTime(0, function()
        if inst:HasTag("up_3") then
            inst.up_delay = 3
        end
        if inst:HasTag("down_6") then
            inst.down_delay = 6
        end

        -- We resume the task from timer component after initial load instead of doing it here
        if inst:HasTag("timed") then
            local initialdelay = 3
            if inst:HasTag("delay_6") then
                initialdelay = 6
            elseif inst:HasTag("delay_9") then
                initialdelay = 9
            end
            inst.components.timer:StartTimer("trap_up", initialdelay)
            if inst:IsAsleep() then
                PauseTimers(inst)
            end
        end
    end)

    return inst
end

local function OnSave_Debris(inst, data)
    data.isburnt = inst.isburnt
end

local function OnLoad_Debris(inst, data)
    if not data then
        return
    end

    inst.isburnt = data.isburnt
    if inst.isburnt then
        inst.AnimState:PlayAnimation("burnt")
    end
end

local function debrisfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("spear_trap")
    inst.AnimState:SetBuild("spear_trap")
    inst.AnimState:PlayAnimation("broken")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    MakeHauntable(inst)

    inst.OnSave = OnSave_Debris
    inst.OnLoad = OnLoad_Debris

    return inst
end

return Prefab("pig_ruins_spear_trap", fn, assets),
       Prefab("pig_ruins_spear_trap_broken", debrisfn, assets)
