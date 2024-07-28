local assets =
{
    Asset("ANIM", "anim/pheromone_stone.zip"),
}

local function OnPutInInventory(inst, owner)
    owner:AddTag("antlingual")
end

local function OnDropped(inst, owner)
    if not owner.components.inventory then
        return
    end

    local target = owner.components.inventory:FindItem(function(item)
        return item:HasTag("ant_translator")
    end)

    if not target then
        owner:RemoveTag("antlingual")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst, "pherostone_water", "pherostone")

    inst.AnimState:SetBank("pheromone_stone")
    inst.AnimState:SetBuild("pheromone_stone")
    inst.AnimState:PlayAnimation("pherostone")

    inst.MiniMapEntity:SetIcon("pheromone_stone.tex")

    inst:AddTag("ant_translator")
    inst:AddTag("irreplaceable")

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("pheromonestone", fn, assets)
