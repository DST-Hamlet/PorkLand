local assets =
{
    Asset("ANIM", "anim/tuna.zip"),
}

local prefabs =
{
    "fish_med_cooked",
}

local function OnUseFn(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/can_open")
    local steak = SpawnPrefab("fish_med_cooked")
    inst.components.inventoryitem.owner.components.inventory:GiveItem(steak)

    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("tuna")
    inst.AnimState:SetBuild("tuna")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "tuna"

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 1

    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(OnUseFn)

    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("tunacan", fn, assets, prefabs)
