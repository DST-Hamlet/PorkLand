local assets =
{
	Asset("ANIM", "anim/lotus.zip"),
	Asset("SOUND", "sound/common.fsb"),
}

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "idle")
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT) TODO Fix this
    
    
    anim:SetBank("lotus")
    anim:SetBuild("lotus")
    anim:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    

    --TODO fix WHy we need to do this hack
    inst.components.floater:SetVerticalOffset(0.1)

    -----------------
    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    ---------------------        
                
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_TINY or 0      
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible.foodstate = "RAW"

    ---------------------        
        
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    ---------------------        
        
    inst:AddComponent("cookable")
    inst.components.cookable.product = "lotus_flower_cooked"


    inst:AddComponent("bait")
    
    inst:AddComponent("inspectable")
    ----------------------
    
    inst:AddComponent("inventoryitem")
    inst:AddComponent("tradable")
    inst:AddTag("cattoy")
    inst:AddTag("billfood")
    
    return inst
end

local function fncooked(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "cooked_water", "cooked")
    -- MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT) TODO fix
    
    
    anim:SetBank("lotus")
    anim:SetBuild("lotus")
    anim:PlayAnimation("cooked")
    
    -----------------
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    ---------------------        
                
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_MED or 0      
    inst.components.edible.foodtype = "VEGGIE"
    inst.components.edible.foodstate = "COOKED"

    ---------------------        
        
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    ---------------------        
    
    inst:AddComponent("inspectable")
    ----------------------

    inst:AddComponent("bait")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    
    inst:AddComponent("inventoryitem")
    inst:AddComponent("tradable")
    inst:AddTag("cattoy")
    inst:AddTag("billfood")
    
    return inst
end

return Prefab( "common/inventory/lotus_flower", fn, assets), 
       Prefab( "common/inventory/lotus_flower_cooked", fncooked, assets) 
