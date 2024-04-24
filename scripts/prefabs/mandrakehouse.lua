require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/elderdrake_house.zip"),
    Asset("MINIMAP_IMAGE", "elderdrake_house"),
}

local prefabs =
{
    "mandrakeman",
}

local function GetStatus(inst)
    if inst:HasTag("burnt") then -- missing quote!
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        return "FULL"
    end
end

local function OnVacate(inst, child)
    if not inst:HasTag("burnt") and child then
        if child.components.health then
            child.components.health:SetPercent(1)
        end
    end
end

local function OnHammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    if inst.components.spawner then
        inst.components.spawner:ReleaseChild()
    end

    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnBurntUp(inst, data)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
end

local function OnIgnite(inst, data)
    if inst.components.spawner and inst.components.spawner:IsOccupied() then
        inst.components.spawner:ReleaseChild()
    end
end

local function OnPhaseChange(inst, phase)
    if phase == "day" then
        return
    end

    if inst:HasTag("burnt") then
        return
    end

    if inst.components.spawner:IsOccupied() then
        if inst.doortask then
            inst.doortask:Cancel()
            inst.doortask = nil
        end
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, function() inst.components.spawner:ReleaseChild() end)
    end
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function OnPreLoad(inst, data)
    WorldSettings_Spawner_PreLoad(inst, data, TUNING.MANDRAKEMAN_SPAWN_TIME)
end

local function OnLoad(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("elderdrake_house")
    inst.AnimState:SetBuild("elderdrake_house")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180/255, 195/255, 50/255)

    inst.MiniMapEntity:SetIcon("elderdrake_house.tex")

    MakeObstaclePhysics(inst, 1)

    inst:AddTag("structure")
    inst:AddTag("elderdrake_house")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("spawner")
    WorldSettings_Spawner_SpawnDelay(inst, TUNING.MANDRAKEMAN_SPAWN_TIME, TUNING.MANDRAKEMAN_ENABLED)
    inst.components.spawner:Configure("mandrakeman", TUNING.MANDRAKEMAN_SPAWN_TIME)
    inst.components.spawner.onvacate = OnVacate

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    MakeHauntable(inst)

    inst:ListenForEvent("burntup", OnBurntUp)
    inst:ListenForEvent("onignite", OnIgnite)

    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad
    inst.OnLoad = OnLoad

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    return inst
end

return Prefab("mandrakehouse", fn, assets, prefabs)
