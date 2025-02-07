local assets =
{
    Asset("ANIM", "anim/feather_peagawk.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.AnimState:SetBank("feather_peagawk")
    inst.AnimState:SetBuild("feather_peagawk")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetFrame(math.random(1, 39)) -- so they don't blink at the same time

    inst.pickupsound = "cloth"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    return inst
end

return Prefab("peagawkfeather", fn, assets)
