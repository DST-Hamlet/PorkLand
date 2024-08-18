require "prefabutil"

local function make_plantable(data)
    local bank = data.bank or data.name
    local assets =
    {
        Asset("ANIM", "anim/" .. bank .. ".zip"),
    }

    if data.build ~= nil then
        table.insert(assets, Asset("ANIM", "anim/" .. data.build .. ".zip"))
    end

    local function ondeploy(inst, pt, deployer)
        local tree = SpawnPrefab(data.name)
        if tree ~= nil then
            tree.Transform:SetPosition(pt:Get())
            inst.components.stackable:Get():Remove()
            if tree.components.pickable ~= nil then
                tree.components.pickable:OnTransplant()
            end
            if deployer ~= nil and deployer.SoundEmitter ~= nil then
                --V2C: WHY?!! because many of the plantables don't
                --     have SoundEmitter, and we don't want to add
                --     one just for this sound!
                deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
            end

            if TheWorld.components.lunarthrall_plantspawner and tree:HasTag("lunarplant_target") then
                TheWorld.components.lunarthrall_plantspawner:setHerdsOnPlantable(tree)
            end
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if data.floater ~= nil then
            MakeInventoryFloatable(inst, data.floater[1], data.floater[2], data.floater[3])
        else
            MakeInventoryFloatable(inst)
            inst.components.floater:UpdateAnimations("dropped_water", "dropped")
        end

        inst.AnimState:SetBank(data.bank or data.name)
        inst.AnimState:SetBuild(data.build or data.name)
        inst.AnimState:PlayAnimation("dropped")

        inst:AddTag("deployedplant")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = data.inspectoverride or ("dug_" .. data.name)
        inst:AddComponent("inventoryitem")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

        inst:AddComponent("deployable")
        inst.components.deployable.ondeploy = ondeploy
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        if data.mediumspacing then
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
        end

        MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndIgnite(inst)

        return inst
    end

    return Prefab("dug_" .. data.name, fn, assets)
end

local plantables =
{
    {
        name = "nettle",
        minspace = 2
    },
}

local prefabs = {}

for _, data in ipairs(plantables) do
    table.insert(prefabs, make_plantable(data))
    table.insert(prefabs, MakePlacer("dug_" .. data.name .. "_placer", data.bank or data.name, data.build or data.name, data.anim or "idle"))
end

return unpack(prefabs)
