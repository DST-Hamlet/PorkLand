local assets =
{
    Asset("ANIM", "anim/nectar_pod.zip"),
}

local prefabs =
{
    "spoiled_food",
}

-- NOTE(ziwbi): Honestly just put these in antchest instead,
-- for the perish rate, there's already Preserver:SetPerishRateMultiplier method for that

-- local function TransformToHoney(inst, antchest)
--     antchest.components.container:RemoveItem(inst)
--     local numNectarPods = 1

--     if inst.components.stackable and inst.components.stackable:IsStack() and inst.components.stackable:StackSize() > 1 then
--         numNectarPods = inst.components.stackable:StackSize() + 1
--     end

--     inst:Remove()

--     for index = 1, numNectarPods, 1 do
--         local honey = SpawnPrefab("honey")
--         local position = Vector3(antchest.Transform:GetWorldPosition())
--         honey.Transform:SetPosition(position.x, position.y, position.z)
--         antchest.components.container:GiveItem(honey, nil, inst:GetPosition())
--     end
-- end

-- local function OnPutInInventory(inst, owner)
--     if owner.prefab == "antchest" then
--         inst:DoTaskInTime(TUNING.TOTAL_DAY_TIME * 0.1, function() TransformToHoney(inst, owner) end)
--         inst.components.perishable:StopPerishing()
--     end
-- end

-- local function OnRemoved(inst, owner)
--     if owner.prefab == "antchest" then
--         inst:CancelAllPendingTasks()
--         inst.components.perishable:StartPerishing()
--     end
-- end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("nectar_pod")
    inst.AnimState:SetBank("nectar_pod")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst:AddTag("nectar")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    -- inst.components.inventoryitem:SetOnRemovedFn(OnRemoved)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("nectar_pod", fn, assets, prefabs)
