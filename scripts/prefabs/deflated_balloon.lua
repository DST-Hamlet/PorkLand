--Should be empty during winter.

local assets =
{
    Asset("ANIM", "anim/balloon_wreckage.zip"),
    Asset("ANIM", "anim/trinkets_giftshop.zip"), 
}

SetSharedLootTable('deflated_balloon_basket',
{
    {'boards',                1.00},
    {'trinket_giftshop_4',    1.00},
})

SetSharedLootTable( 'deflated_balloon',
{
    {'rope',                1.00},
    {'rope',                1.00},    
    {'cutgrass',            1.00},
    {'cutgrass',            1.00},
})


local function onhammered(inst, worker)
    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end    
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function basketfn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("balloon_wreckage.tex")

    MakeObstaclePhysics(inst, 1.0, 1)

    inst.AnimState:SetBank("balloon_wreckage")
    inst.AnimState:SetBuild("balloon_wreckage")
    inst.AnimState:PlayAnimation("basket", true)

    inst:AddTag("structure")

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
    inst:AddComponent("inspectable")
	--inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('deflated_balloon_basket')

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onhammered)

    return inst
end

local function balloonfn()
    local inst = CreateEntity()
    
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.0, 1)

    inst.AnimState:SetBank("balloon_wreckage")
    inst.AnimState:SetBuild("balloon_wreckage")
    inst.AnimState:PlayAnimation("balloon", true)

    inst:AddTag("structure")

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
    inst:AddComponent("inspectable")
    --inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('deflated_balloon')

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onhammered)

    return inst
end

local function trinketfn(Sim)
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
	inst:AddTag("trinket")
	
    inst.AnimState:SetBank("trinkets_giftshop")
    inst.AnimState:SetBuild("trinkets_giftshop")
    inst.AnimState:PlayAnimation(4)
    
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    return inst
end

return Prefab("deflated_balloon_basket", basketfn, assets),
       Prefab("deflated_balloon", balloonfn, assets),
       Prefab("trinket_giftshop_4", trinketfn, assets)
