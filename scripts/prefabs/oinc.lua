local assets=
{
	Asset("ANIM", "anim/pig_coin.zip"),
}

local prefabs =
{

}

local function shine(inst)
    inst.task = nil
    -- hacky, need to force a floatable anim change
    inst.components.floater:UpdateAnimations("idle_water", "idle")
    inst.components.floater:UpdateAnimations("sparkle_water", "sparkle")

    if inst.components.floater:IsFloating() then
        inst.AnimState:PushAnimation("idle_water")
    else
        inst.AnimState:PushAnimation("idle")
    end

    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
    end
end

local function onwake(inst)
    inst.task = inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
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

    inst.AnimState:SetBank("coin")
    inst.AnimState:SetBuild("pig_coin")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst:AddTag("oinc")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 1

    inst:AddComponent("currency")

    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    -- inst:AddComponent("appeasement")
    -- inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_TINY

    inst:AddComponent("waterproofer")
    inst.components.waterproofer.effectiveness = 0
    inst:AddComponent("inventoryitem")

    inst:AddComponent("bait")
    inst.oincvalue = 1

    inst:AddComponent("tradable")

    inst.OnEntityWake = onwake

    return inst
end

return Prefab("oinc", fn, assets, prefabs)
