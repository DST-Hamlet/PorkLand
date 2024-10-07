local assets =
{
    Asset("ANIM", "anim/waterdrop.zip"),
    Asset("ANIM", "anim/lifeplant.zip"),
}

local prefabs =
{
    "lifeplant"
}

local function OnEaten(inst, eater)
    if eater and eater.components.poisonable then
        eater.components.poisonable:Cure()
    end
end

local function OnDeploy(inst, pt, deployer)
    local plant = SpawnPrefab("lifeplant")
    plant.Transform:SetPosition(pt:Get())

    inst.planted = true
    inst:Remove()
end

local function OnRemove(inst)

end

local function OnSave(inst, data)

end

local function OnLoadPostPass(inst, newents, data)

end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    PorkLandMakeInventoryFloatable(inst)

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
    inst.components.edible:SetOnEatenFn(OnEaten)

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
