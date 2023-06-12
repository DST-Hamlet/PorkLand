local assets=
{
	Asset("ANIM", "anim/ballpein_hammer.zip"),
	Asset("ANIM", "anim/swap_ballpein_hammer.zip"),
}

local function onfinished(inst)
    inst:Remove()
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_ballpein_hammer", "swap_ballpein_hammer")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    anim:SetBank("ballpein_hammer")
    anim:SetBuild("ballpein_hammer")
    anim:PlayAnimation("idle")
            
	inst.entity:SetPristine()
	
    inst:AddComponent("dislodger")

	if not TheWorld.ismastersim then
		return inst
	end
	
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LITTLE_HAMMER_DAMAGE)
    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DISLODGE, 1)
    -------
    inst:AddComponent("finiteuses")

    local uses = TUNING.LITTLE_HAMMER_USES
	
	-- DS - Screw it. Warbucks isn't implemented, and this is weird.
    local player = ThePlayer
    if player and player:HasTag("treasure_hunter") then
		uses = uses * 2
    end

    inst.components.finiteuses:SetMaxUses(uses)
    inst.components.finiteuses:SetUses(uses)
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetConsumption(ACTIONS.DISLODGE, 1)
    -------

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )

    
    return inst
end

return Prefab( "ballpein_hammer", fn, assets)	   

