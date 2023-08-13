local assets =
{
    Asset("ANIM", "anim/alloy.zip"),
}

local function shine(inst)
    inst.task = nil
    if inst.components.floater:IsFloating() then
        inst.AnimState:PlayAnimation("sparkle_water")
        inst.AnimState:PushAnimation("idle_water")
    else
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:PushAnimation("idle")
    end
    inst.task = inst:DoTaskInTime(4 + math.random() * 5, shine)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )

    inst.AnimState:SetBank("alloy")
    inst.AnimState:SetBuild("alloy")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst:AddTag("scarerbait")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 2

    inst:AddComponent("stackable")

    inst:AddComponent("bait")

    shine(inst)

    MakeHauntableLaunch(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    return inst
end

return Prefab("alloy", fn, assets)
