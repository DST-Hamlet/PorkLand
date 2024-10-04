require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/burr.zip"),
}

local function custom_candeploy_fn(inst, pt, mouseover, deployer, rot)
    return TheWorld.Map:ReverseIsVisualGroundAtPoint(pt:Get()) and TheWorld.Map:CanDeployPlantAtPoint(pt, inst)
end

local function Plant(point)
    local sapling = SpawnPrefab("burr_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(point:Get())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
end

local function OnDeploy(inst, point)
    local newinst = inst.components.stackable:Get()
    newinst:Remove()

    Plant(point)
end

local function OnseasonChange(inst, season)
    if season ~= SEASONS.LUSH
        and not inst:IsInLimbo()
        and TheWorld.Map:ReverseIsVisualGroundAtPoint(inst:GetPosition()) then
        inst.components.deployable:Deploy(inst:GetPosition(), inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("burr")
    inst.AnimState:SetBuild("burr")
    inst.AnimState:PlayAnimation("idle")

    PorkLandMakeInventoryFloatable(inst)

    inst:AddTag("deployedplant")
    inst:AddTag("cattoy")

    inst._custom_candeploy_fn = custom_candeploy_fn

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

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.ondeploy = OnDeploy

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.LIGHT, TUNING.WINDBLOWN_SCALE_MAX.LIGHT)
    MakeHauntableLaunch(inst)

    inst:WatchWorldState("season", OnseasonChange)
    inst:DoTaskInTime(math.random(), function() OnseasonChange(inst, TheWorld.state.season) end)

    return inst
end

return Prefab("burr", fn, assets),
       MakePlacer("burr_placer", "burr", "burr", "idle_planted")
