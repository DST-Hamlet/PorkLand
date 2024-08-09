local assets =
{
	Asset("ANIM", "anim/thunderbird_nest.zip"),
}

local prefabs =
{
    "thunderbird",
    "iron",
}

local function OnPicked(inst, picker)
    inst.AnimState:PlayAnimation("nest")
end

local function OnMakeEmpty(inst)
    inst.AnimState:PlayAnimation("nest")
end

local function OnRegrow(inst)
    inst.AnimState:PlayAnimation("orenest")
end

local function OnSpawned(inst, child)
    if child.components.homeseeker then
        child.components.homeseeker:SetHome(inst)
    end
    inst.components.pickable:Resume()
end

local function OnChildKilledFn(inst)
    inst.components.pickable:Pause()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.entity:AddMiniMapEntity()
	inst.MiniMapEntity:SetIcon("thunderbirdnest.tex")

    inst.AnimState:SetBuild("thunderbird_nest")
    inst.AnimState:SetBank("thunderbird_nest")
    inst.AnimState:PlayAnimation("orenest", false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable:SetUp("iron", TUNING.THUNDERBIRDNEST_REGROW_TIME)
    inst.components.pickable:SetOnPickedFn(OnPicked)
    inst.components.pickable:SetOnRegenFn(OnRegrow)
    inst.components.pickable:SetMakeEmptyFn(OnMakeEmpty)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "thunderbird"
    inst.components.childspawner.spawnoffscreen = true
    inst.components.childspawner:SetRegenPeriod(TUNING.THUNDERBIRDNEST_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.THUNDERBIRDNEST_RELEASE_TIME)
    inst.components.childspawner:SetSpawnedFn(OnSpawned)
    inst.components.childspawner:SetMaxChildren(TUNING.THUNDERBIRDNEST_MAXCHILDREN)
    inst.components.childspawner:SetOnChildKilledFn(OnChildKilledFn)
    inst.components.childspawner:StartSpawning()

    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.THUNDERBIRDNEST_RELEASE_TIME, TUNING.THUNDERBIRD_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.THUNDERBIRDNEST_REGEN_TIME, TUNING.THUNDERBIRD_ENABLED)
    if not TUNING.THUNDERBIRD_ENABLED then
        inst.components.childspawner.childreninside = 0
    end

    MakeHauntable(inst)

    return inst
end

return Prefab("thunderbirdnest", fn, assets, prefabs)
