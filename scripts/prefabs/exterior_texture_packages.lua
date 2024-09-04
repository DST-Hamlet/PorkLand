local assets =
{
    Asset("ANIM", "anim/player_house_kits.zip"),
}

local function make_craft(name, build, bank)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddNetwork()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.AnimState:SetBuild("player_house_kits")
        inst.AnimState:SetBank("house_kit")
        inst.AnimState:PlayAnimation(name)

        MakeInventoryPhysics(inst)
        PorkLandMakeInventoryFloatable(inst, name .. "_water", name)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:ChangeImageName("player_house_" .. name)

        inst:AddComponent("renovator")
        inst.components.renovator.bank = bank
        inst.components.renovator.build = build
        inst.components.renovator.prefabname = "playerhouse_" .. name

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("player_house_" .. name .. "_craft", fn, assets)
end

return make_craft("cottage", "player_small_house1_cottage_build", "playerhouse_small"),
    make_craft("villa",      "player_large_house1_villa_build",   "playerhouse_large"),
    make_craft("manor",      "player_large_house1_manor_build",   "playerhouse_large"),
    make_craft("tudor",      "player_small_house1_tudor_build",   "playerhouse_small"),
    make_craft("gothic",     "player_small_house1_gothic_build",  "playerhouse_small"),
    make_craft("brick",      "player_small_house1_brick_build",   "playerhouse_small"),
    make_craft("turret",     "player_small_house1_turret_build",  "playerhouse_small")
