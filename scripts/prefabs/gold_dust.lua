local assets=
{
	Asset("ANIM", "anim/gold_dust.zip"),
}

local function shine(inst)
    if inst.shine_task then
        inst.shine_task:Cancel()
        inst.shine_task = nil
    end

	if inst.components.floater and inst.components.floater:IsFloating() then
		inst.AnimState:PlayAnimation("sparkle_water")
		inst.AnimState:PushAnimation("idle_water")
	else
		inst.AnimState:PlayAnimation("sparkle")
		inst.AnimState:PushAnimation("idle")
    end

	inst.shine_task = inst:DoTaskInTime(4 + math.random() * 5, inst.shine)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("gold_dust")
    inst.AnimState:SetBuild("gold_dust")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst:AddTag("molebait")
    inst:AddTag("scarerbait")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GOLDDUST
    inst.components.edible.hungervalue = 1

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("bait")

    inst.shine = shine

    inst:shine()

    return inst
end

return Prefab("gold_dust", fn, assets)
