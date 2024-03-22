local assets =
{
	Asset("ANIM", "anim/waterdrop.zip"),
    Asset("ANIM", "anim/lifeplant.zip"),
}

local prefabs =
{
    "lifeplant"
}

local function OnRemove(inst)
    if inst.fountain and not inst.planted then
        inst.fountain:PushEvent("deactivate")
    end
end

local function OnDeploy(inst, pt, deployer)
    local plant = SpawnPrefab("lifeplant")
    plant.Transform:SetPosition(pt:Get())
    plant:PushEvent("planted", {fountain = inst.fountain, deployer = deployer})

    inst.planted = true
    inst:Remove()
end

local function OnSave(inst, data)
    if inst.fountain and inst.fountain:IsValid() then
        data.fountainID = inst.fountain.GUID
        return {inst.fountain and inst.fountain.GUID}
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.fountainID ~= nil then
        inst.fountain = newents[data.fountainID].entity
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)
    inst.components.floater:UpdateAnimations("idle_water", "idle")

    inst.AnimState:SetBank("waterdrop")
    inst.AnimState:SetBuild("waterdrop")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("waterdrop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")

    -- inst:AddComponent("poisonhealer")

    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible.healthvalue = TUNING.HEALING_SUPERHUGE * 3
    inst.components.edible.hungervalue = TUNING.CALORIES_SUPERHUGE * 3
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE * 3
    inst.components.edible:SetOnEatenFn(function(inst, eater)
        if eater and eater.components.poisonable then
            eater.components.poisonable:Cure()
        end
    end)

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = OnDeploy

    MakeHauntableLaunch(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)

    inst:ListenForEvent("onremove", OnRemove)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("waterdrop", fn, assets, prefabs),
       MakePlacer("waterdrop_placer", "lifeplant", "lifeplant", "idle_loop")

