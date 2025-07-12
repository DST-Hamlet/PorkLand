local assets =
{
    Asset("ANIM", "anim/turf_1.zip"),
    Asset("ANIM", "anim/turf_atc.zip"),
}

local prefabs =
{
    "gridplacer",
}

local function make_turf(tile, data)
    local function ondeploy(inst, pt, deployer)
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
        end
        local map = TheWorld.Map
        local x, y = map:GetTileCoordsAtPoint(pt:Get())
        map:SetTile(x, y, tile)
        inst.components.stackable:Get():Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.pickupsound = data.pickupsound or nil

        inst.AnimState:SetBank("turf")
        inst.AnimState:SetBuild(data.bank_build)
        inst.AnimState:PlayAnimation(data.anim)

        inst.tile = tile

        inst:AddTag("groundtile")
        inst:AddTag("molebait")

        MakeInventoryFloatable(inst, "med", nil, 0.65)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        inst:AddComponent("bait")

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.TURF)
        inst.components.deployable.ondeploy = ondeploy
        inst.components.deployable:SetUseGridPlacer(true)

        MakeMediumBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndIgnite(inst)

        return inst
    end

    return Prefab("turf_" .. data.name, fn, assets, prefabs)
end

local porkland_turfs = {
    [WORLD_TILES.PIGRUINS]   = {name = "pigruins",   anim = "pig_ruins", bank_build = "turf_1"},
    [WORLD_TILES.RAINFOREST] = {name = "rainforest", anim = "rainforest", bank_build = "turf_1"},
    [WORLD_TILES.LAWN]       = {name = "lawn",       anim = "checkeredlawn", bank_build = "turf_1"},
    [WORLD_TILES.SUBURB]     = {name = "moss",       anim = "mossy_blossom", bank_build = "turf_1"},
    [WORLD_TILES.FIELDS]     = {name = "fields",     anim = "farmland", bank_build = "turf_1"},
    [WORLD_TILES.FOUNDATION] = {name = "foundation", anim = "fanstone", bank_build = "turf_1"},
    [WORLD_TILES.COBBLEROAD] = {name = "cobbleroad", anim = "cobbleroad", bank_build = "turf_1"},
    [WORLD_TILES.PAINTED]    = {name = "painted",    anim = "bog", bank_build = "turf_1"},
    [WORLD_TILES.PLAINS]     = {name = "plains",     anim = "plains", bank_build = "turf_1"},
    [WORLD_TILES.DEEPRAINFOREST_NOCANOPY] = {name = "deeprainforest_nocanopy", anim = "deepjungle", bank_build = "turf_1"},
    [WORLD_TILES.SALTBEACH] = {name = "saltbeach", anim = "saltbeach", bank_build = "turf_atc"},
}

local ret = {}
for k, v in pairs(porkland_turfs) do
    table.insert(ret, make_turf(k, v))
end

return unpack(ret)