local assets=
{
	Asset("ANIM", "anim/security_contract.zip"),
}

--[[ Each amulet has a seperate onequip and onunequip function so we can also
add and remove event listeners, or start/stop update functions here. ]]

---RED

local function onPutInInventory(inst, owner)    
    --owner:AddTag("antlingual")
end

local function OnDropped(inst, owner)     
    --[[
    local target = nil
    target = owner.components.inventory:FindItem(function(item) return item:HasTag("ant_translator") end)
    if not target then 
        owner:RemoveTag("antlingual")
    end
    ]]
end

local function makefn(inst)
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("security_contract")
    inst.AnimState:SetBuild("security_contract")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("securitycontract")
    
    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"

    inst.components.inventoryitem:SetOnPutInInventoryFn(onPutInInventory)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    
    MakeInventoryFloatable(inst, "idle_water", "idle")
    

    return inst
end

return Prefab( "securitycontract", makefn, assets)