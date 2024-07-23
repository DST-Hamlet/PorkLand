local assets = {
    Asset("ANIM", "anim/clawling.zip"),
}

local prefabs = {}

local function Plant(point)
    local sapling = SpawnPrefab("clawpalmtree_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(point:Get())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
end

local function OnDeploy(inst, point)
    inst = inst.components.stackable:Get()
    inst:Remove()

    Plant(point)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("clawling")
    inst.AnimState:SetBuild("clawling")
    inst.AnimState:PlayAnimation("idle_planted")
    inst.AnimState:SetScale(0.7, 0.7, 0.7)

    inst:AddTag("plant")
    inst:AddTag("cattoy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("clawpalmtree_sapling")

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = OnDeploy

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)
    MakeHauntableLaunch(inst)

    return inst
end

return
    Prefab("clawpalmtree_sapling_item", fn, assets, prefabs),
    MakePlacer("clawpalmtree_sapling_item_placer", "clawling", "clawling", "idle_planted")
