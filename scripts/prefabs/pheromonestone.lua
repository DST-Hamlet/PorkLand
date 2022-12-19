local assets =
{
	Asset("ANIM", "anim/pheromone_stone.zip"),
	Asset("ANIM", "anim/torso_amulets.zip"),
}

local function onPutInInventory(inst, owner)
    owner:AddTag("antlingual")
end

local function OnRemoved(inst, owner)
    local target = nil
    if owner.components.inventory then
        target = owner.components.inventory:FindItem(function(item) return item:HasTag("ant_translator") end)
        if not target then
            owner:RemoveTag("antlingual")
        end
    end
end

local function fn(inst)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    -- MakeInventoryFloatable(inst, "pherostone_water", "pherostone")

    inst.AnimState:SetBank("pheromone_stone")
    inst.AnimState:SetBuild("pheromone_stone")
    inst.AnimState:PlayAnimation("pherostone")

    inst:AddTag("irreplaceable")
    inst:AddTag("ant_translator")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"
    inst.components.inventoryitem:SetOnPutInInventoryFn(onPutInInventory)
    inst.components.inventoryitem:SetOnRemovedFn(OnRemoved)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("pheromonestone", fn, assets)
