local function getstatus(inst)
    if inst.components.sinkable and inst.components.sinkable:InSunkening() then
        return "SUNKEN"
    end
end

local assets = {
    Asset("ANIM", "anim/relics.zip"),
}

local function BubbleTask(inst)
    -- hacky, need to force a floatable anim change
    if inst.components.sinkable:InSunkening() then
        inst.components.floater:UpdateAnimations(inst.relicnum.."_bubble", inst.relicnum)
    else
        inst.components.floater:UpdateAnimations(inst.relicnum.."_water", inst.relicnum)
    end

    if inst.components.floater:IsFloating() then
        inst.AnimState:PushAnimation(inst.relicnum.."_water")
    else
        inst.AnimState:PushAnimation(inst.relicnum)
    end

    if inst.entity:IsAwake() then
        inst.task = inst:DoTaskInTime(4+math.random()*10, BubbleTask)
    end
end

local function OnEntityWake(inst)
    if inst.task == nil then
        inst.task = inst:DoTaskInTime(4+math.random()*10, BubbleTask)
    end
end

local function OnRemoveEntity(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function OnNoLongerLanded(inst)
    inst:RemoveTag("fishable")
    inst.name = inst.oldname
    inst.components.inventoryitem.canbefishedup = false
    inst.components.inventoryitem.canbepickedup = true
end

local function OnHitWater(inst)
    inst:AddTag("fishable")
	inst.oldname = inst.name
	inst.name = STRINGS.NAMES.SUNKEN_RELIC
    inst.components.inventoryitem.canbefishedup = true
    inst.components.inventoryitem.canbepickedup = false
end

local function OnRetrieved(inst, worker)
    if worker.components.inventory then
        worker.components.inventory:GiveItem(inst)
    end
end

local function MakeRelic(num)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("molebait")
        inst:AddTag("cattoy")
        inst:AddTag("relic")

        inst.AnimState:SetBank("relic")
        inst.AnimState:SetBuild("relics")
        inst.AnimState:PlayAnimation(tostring(num))

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)
        inst.components.floater:UpdateAnimations(tostring(num).."_water", tostring(num))

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("tradable")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("inventoryitem")

        inst:AddComponent("sinkable")
        inst.components.sinkable.swapbuild = "relics"
        inst.components.sinkable.swapsymbol = "fish0" .. num
        inst.components.sinkable:SetOnNoLongerLandedfn(OnNoLongerLanded)
        inst.components.sinkable:SetOnHitWaterfn(OnHitWater)

        inst:ListenForEvent("fishingcollect", function(inst, worker) OnRetrieved(inst, worker) end)

        inst.OnEntityWake = OnEntityWake
        inst.OnRemoveEntity = OnRemoveEntity
        inst.relicnum = num

        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("relic_" .. tostring(num), fn , assets)
end

local ret = {}
for k=1, 5 do
    table.insert(ret, MakeRelic(k))
end

return unpack(ret)
