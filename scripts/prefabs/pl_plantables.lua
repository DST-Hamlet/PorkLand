require "prefabutil"

local function make_plantable(data)
    local bank = data.bank or data.name
    local assets =
    {
        Asset("ANIM", "anim/"..bank..".zip"),
        Asset("INV_IMAGE", "dug_"..data.name)
    }

    if data.build ~= nil then
        table.insert(assets, Asset("ANIM", "anim/"..data.build..".zip"))
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
        --inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst:AddTag("deployedplant")

        inst.AnimState:SetBank(data.bank or data.name)
        inst.AnimState:SetBuild(data.build or data.name)
        inst.AnimState:PlayAnimation("dropped")

        if data.floater ~= nil then
            MakeInventoryFloatable(inst, data.floater[1], data.floater[2], data.floater[3])
        else
            MakeInventoryFloatable(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = data.inspectoverride or ("dug_"..data.name)
        inst:AddComponent("inventoryitem")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

        MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
        MakeSmallPropagator(inst)

        MakeHauntableLaunchAndIgnite(inst)

        inst:AddComponent("deployable")
        --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
        inst.components.deployable.ondeploy = ondeploy
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        if data.mediumspacing then
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)
        end

		if data.halloweenmoonmutable_settings ~= nil then
			inst:AddComponent("halloweenmoonmutable")
			inst.components.halloweenmoonmutable:SetPrefabMutated(data.halloweenmoonmutable_settings.prefab)
		end

        ---------------------
        return inst
    end

    return Prefab("dug_"..data.name, fn, assets)
end

local plantables =
{
    {
        name="nettle",
    },

}

local prefabs = {}
for i, v in ipairs(plantables) do
    table.insert(prefabs, make_plantable(v))
    table.insert(prefabs, MakePlacer("dug_"..v.name.."_placer", v.bank or v.name, v.build or v.name, v.anim or "idle"))
end

return unpack(prefabs)
