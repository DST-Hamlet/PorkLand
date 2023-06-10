local assets=
{
	Asset("ANIM", "anim/venom_gland.zip"),
}

local function OnCure(inst, target)
    if target.components.health then
        local damage = TUNING.VENOM_GLAND_DAMAGE
        local currenthealth = target.components.health.currenthealth
        damage = math.clamp(math.min(TUNING.VENOM_GLAND_DAMAGE, currenthealth - TUNING.VENOM_GLAND_MIN_HEALTH), 0, TUNING.VENOM_GLAND_DAMAGE)
        target.components.health:DoPoisonDamage(damage)
        target:PushEvent("poisondamage", {damage=damage})
    end
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("venom_gland")
    inst.AnimState:SetBuild("venom_gland")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    inst:AddComponent("stackable")

	MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddTag("cattoy")
    inst:AddTag("venomgland")
    inst:AddComponent("tradable")

    inst:AddComponent("poisonhealer")
    inst.components.poisonhealer.oncure = OnCure

    return inst
end

return Prefab( "common/inventory/venomgland", fn, assets)
