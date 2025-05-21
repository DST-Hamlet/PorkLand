local assets=
{

}

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_krampus_sack")
    inst.AnimState:PlayAnimation("anim")

    MakeInventoryPhysics(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.keepondeath = true
    inst.components.inventoryitem.cangoincontainer = false

    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 3
    inst.components.inventory.ignorescangoincontainer = true

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BEARD
    inst.components.equippable:SetPreventUnequipping(true)

    return inst
end

return Prefab("woodie_beaver_bag", fn, assets)

