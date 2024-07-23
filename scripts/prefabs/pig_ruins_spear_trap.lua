local assets =
{
    Asset("ANIM", "anim/spear_trap.zip"),
}

local prefabs =
{

}

local function OnKilled(inst)
    local debris = SpawnPrefab("pig_ruins_spear_trap_broken")
    debris.AnimState:PlayAnimation("breaking")
    debris.AnimState:PushAnimation("broken", true)
    debris.Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:PushEvent("dead")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/speartrap_break")
    inst:Remove()
end

local function OnBurnt(inst)
    local debris = SpawnPrefab("pig_ruins_spear_trap_broken")
    debris.AnimState:PlayAnimation("burnt")
    debris.Transform:SetPosition(inst.Transform:GetWorldPosition())
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
end

local function cycletrapdown(inst)
    if not inst:HasTag("burnt") and not inst:HasTag("dead") then
        if inst.sg:HasStateTag("extended") then
            inst:PushEvent("reset")
        end
    end
end

local function OnEntityWake(inst)
    inst.components.cycletimer:Resume()
end

local function OnEntitySleep(inst)
    inst.components.cycletimer:Pause()
end

local function canbeattackedfn(inst)
    local canbeattacked = true

    if inst:HasTag("burnt") or inst:HasTag("dead") then
        canbeattacked = false
    end

    return canbeattacked
end

local function OnSave(inst, data)
    if inst.extended then
        data.extended = true
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

    if data.extended then
        inst.sg:GoToState("extended")
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
    inst:AddTag("tree")
    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("cycletimer")
    inst.components.cycletimer.cyclefn1 = cycletrapup
    inst.components.cycletimer.cyclefn2 = cycletrapdown

    inst:AddComponent("hiddendanger")

    inst:AddComponent("inspectable")

    MakeHauntable(inst)

    inst:AddComponent("shearable")
    inst.components.shearable:SetOnShearFn(OnKilled)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SPEAR_TRAP_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst.components.combat:SetDefaultDamage(TUNING.SPEAR_TRAP_DAMNAGE)
    inst.components.combat.canbeattackedfn = canbeattackedfn

    MakeSmallBurnable(inst)
    inst.components.burnable.disabled = true

    MakeSmallPropagator(inst)
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst:SetStateGraph("SGspear_trap")

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst:ListenForEvent("death", OnKilled)
    inst:ListenForEvent("triggertrap", function(inst, data)
        inst.triggertask = inst:DoTaskInTime(math.random() * 0.25,function()
            inst:PushEvent("spring")
        end)
    end)

    inst:DoTaskInTime(0, function()
        if inst.components.cycletimer.setted == true then
            return
        end
        local time1 = 1
        if inst:HasTag("up_3") then
            time1 = 3
        end

        local time2 = 3
        if inst:HasTag("down_6") then
            time2 = 6
        end

        inst.components.cycletimer:SetUp(time1, time2, cycletrapup, cycletrapdown)

        if inst:HasTag("timed") then
            local initialdelay = 3
            if inst:HasTag("delay_6") then
                initialdelay = 6
            elseif inst:HasTag("delay_9") then
                initialdelay = 9
            end
            inst.components.cycletimer:Start(initialdelay)
        end
    end)

    return inst
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

    return inst
end

return Prefab("pig_ruins_spear_trap", fn, assets, prefabs),
       Prefab("pig_ruins_spear_trap_broken", debrisfn, assets, prefabs)
