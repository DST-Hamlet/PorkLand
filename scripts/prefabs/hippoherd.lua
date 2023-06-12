local assets =
{
	--Asset("ANIM", "anim/arrow_indicator.zip"),
}

local prefabs = 
{
    "hippopotamoose",
}

local function CanSpawn(inst)
    return inst.components.herd and not inst.components.herd:IsFull()
end

local function OnSpawned(inst, newent)
    if inst.components.herd then
        inst.components.herd:AddMember(newent)
    end
end

local function OnEmpty(inst)
    inst:Remove()
end
   
local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()

    inst:AddTag("herd")
    inst:AddTag("NOBLOCK")


    inst.entity:AddNetwork()
    
    --anim:SetBank("arrow_indicator")
    --anim:SetBuild("arrow_indicator")
    --anim:PlayAnimation("arrow_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    
    inst:AddComponent("herd")
    inst.components.herd:SetMemberTag("hippopotamoose")
    inst.components.herd:SetGatherRange(40)
    inst.components.herd:SetUpdateRange(20)
    inst.components.herd:SetOnEmptyFn(OnEmpty)
    
    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetRandomTimes(TUNING.ZEB_MATING_SEASON_BABYDELAY, TUNING.ZEB_MATING_SEASON_BABYDELAY_VARIANCE)
    inst.components.periodicspawner:SetPrefab("hippopotamoose")
    inst.components.periodicspawner:SetOnSpawnFn(OnSpawned)
    inst.components.periodicspawner:SetSpawnTestFn(CanSpawn)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetOnlySpawnOffscreen(true)
    inst.components.periodicspawner:Start()
    
    return inst
end

return Prefab( "forest/animals/hippoherd", fn, assets, prefabs) 
