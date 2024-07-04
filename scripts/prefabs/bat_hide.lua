local assets =
{
    Asset("ANIM", "anim/bat_leather.zip"),
}

local function fn()
    local new_inst = SpawnPrefab("pigskin")

    new_inst.AnimState:SetBank("bat_leather")
    new_inst.AnimState:SetBuild("bat_leather")

    new_inst.name = STRINGS.NAMES.BAT_HIDE

    if not TheWorld.ismastersim then
        return new_inst
    end

    new_inst.components.inventoryitem:ChangeImageName("bat_leather")

    return new_inst
end

return Prefab("bat_hide", fn, assets)
