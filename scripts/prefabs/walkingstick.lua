local assets=
{
	Asset("ANIM", "anim/walking_stick.zip"),
	Asset("ANIM", "anim/swap_walking_stick.zip"),
}

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_walking_stick", "swap_object")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 

	if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
    end
    inst._owner = owner
    inst:ListenForEvent("locomote", inst._onlocomote, owner)
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
	
	if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
        inst._owner = nil
    end
	
    inst.components.fueled:StopConsuming()
end

local function onequiptomodel(inst, owner, from_ground)
    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()  
    inst.entity:AddNetwork() 
	
    MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst)
    
    inst.AnimState:SetBank("cane")
    inst.AnimState:SetBuild("walking_stick")
    inst.AnimState:PlayAnimation("idle")
    
    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.WALKING_STICK_DAMAGE)
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("equippable")
    
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)
    inst.components.equippable.walkspeedmult = TUNING.WALKING_STICK_SPEED_MULT

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = "USAGE"
    inst.components.fueled:InitializeFuelLevel(TUNING.WALKING_STICK_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)


	inst._onlocomote = function(owner)
        if owner.components.locomotor.wantstomoveforward then
            if not inst.components.fueled.consuming then
                inst.components.fueled:StartConsuming()
            end
        elseif inst.components.fueled.consuming then
            inst.components.fueled:StopConsuming()
        end
    end
	--if ThePlayer then
	--	ThePlayer:ListenForEvent("locomote", function() 
    --        local player = ThePlayer
    --        if player.sg and player.sg:HasStateTag("moving") and inst.equipped then
    --            inst.components.fueled:StartConsuming()
    --        else
    --            inst.components.fueled:StopConsuming()
    --        end
    --    end)
    --end
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end


return Prefab( "walkingstick", fn, assets) 

