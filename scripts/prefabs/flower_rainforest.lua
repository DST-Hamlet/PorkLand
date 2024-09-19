local assets = {
    Asset("ANIM", "anim/flowers_rainforest.zip"),
}

local prefabs = {
    "petals",
}

local names = {"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f14", "f15", "f16", "f17"}

local function OnPickedFn(inst, picker)
    if picker ~= nil then
        if picker.components.sanity ~= nil and not picker:HasTag("plantkin") then
            picker.components.sanity:DoDelta(TUNING.SANITY_TINY)
        end
    end

    local pos = inst:GetPosition()
    TheWorld:PushEvent("plantkilled", { doer = picker, pos = pos })  -- this event is pushed in other places too
end

local function OnSave(inst, data)
    data.anim = inst.animname
end

local function OnLoad(inst, data)
    if data ~= nil and data.anim then
        inst.animname = data.anim
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("flowers_rainforest")
    inst.AnimState:SetBuild("flowers_rainforest")
    inst.AnimState:SetRayTestOnBB(true)

    -- inst:AddTag("flower")
    inst:AddTag("cattoy")
    inst:AddTag("flower_rainforest")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.animname = names[math.random(#names)]
    inst.AnimState:PlayAnimation(inst.animname)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("petals", 10)
    inst.components.pickable.onpickedfn = OnPickedFn
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true
    inst.components.pickable.wildfirestarter = true

    MakeSmallBurnable(inst)
    -- inst.components.burnable:MakeDragonflyBait(1)  -- dst don't use
    MakeSmallPropagator(inst)
    -- AddToRegrowthManager(inst)
    MakeHauntableChangePrefab(inst, "flower_evil")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("flower_rainforest", fn, assets, prefabs)
