local assets =
{
    Asset("ANIM", "anim/snake_bone.zip")
}

local MAX_LOOT = 10
local function OnWorkCallback(inst, worker, workleft, workdone)
	local num_loots = math.floor(math.clamp(workdone, 1, MAX_LOOT))
	num_loots = math.min(num_loots, inst.components.stackable:StackSize())

	if inst.components.stackable:StackSize() > num_loots then
		if num_loots == MAX_LOOT then
			LaunchAt(inst, inst, worker, TUNING.SPOILED_FISH_LOOT.LAUNCH_SPEED, TUNING.SPOILED_FISH_LOOT.LAUNCH_HEIGHT, nil, TUNING.SPOILED_FISH_LOOT.LAUNCH_ANGLE)
		end
	end

	for _ = 1, num_loots do
		inst.components.lootdropper:DropLoot()
	end

	local top_stack_item = inst.components.stackable:Get(num_loots)
    SpawnPrefab("collapse_small").Transform:SetPosition(top_stack_item.Transform:GetWorldPosition())
	top_stack_item:Remove()
end

local function OnStackSizeChanged(inst, data)
    if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(data.stacksize)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("snake_bone")
    inst.AnimState:SetBuild("snake_bone")
    inst.AnimState:PlayAnimation("idle", false)

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"boneshard", "boneshard"})

    inst:AddComponent("stackable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(inst.components.stackable.stacksize)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:ListenForEvent("stacksizechange", OnStackSizeChanged)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("snake_bone", fn, assets)
