local assets=
{
	Asset("ANIM", "anim/gold_dust.zip"),
}

local function shine(inst)
    inst.task = nil
	if inst.onwater then
		inst.AnimState:PlayAnimation("sparkle_water")
		inst.AnimState:PushAnimation("idle_water")
	else
		inst.AnimState:PlayAnimation("sparkle")
		inst.AnimState:PushAnimation("idle")
    end
	inst.task = inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
end


local function OnWaterChange(inst, onwater)
	inst.onwater = onwater
end

local function OnEntityWake(inst)
	inst.components.tiletracker:Start()
end

local function OnEntitySleep(inst)
	inst.components.tiletracker:Stop()
end

local function fn(Sim)

	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddPhysics()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "idle")
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

	inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )

    inst.AnimState:SetBank("gold_dust")
    inst.AnimState:SetBuild("gold_dust")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "GOLDDUST"
    inst.components.edible.hungervalue = 1
    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("bait")
    inst:AddTag("molebait")
    inst:AddTag("scarerbait")

	inst:AddComponent("tiletracker")
	inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)
	inst.onwater = false
	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

    shine(inst)    return inst
end

return Prefab( "common/inventory/gold_dust", fn, assets)
