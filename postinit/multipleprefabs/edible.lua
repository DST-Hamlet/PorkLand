local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local plantables = {
    "berrybush",
    "berrybush2",
    "berrybush_juicy",
    "sapling",
    "sapling_moon",
    "grass",
    "marsh_bush",
    "rock_avocado_bush",
    "bananabush",
    "monkeytail",
}

local function add_edible_wood_type(inst)
    if not TheWorld.ismastersim then
        return
    end

    if not inst.components.edible then
        inst:AddComponent("edible")
    end
    inst.components.edible.foodtype = FOODTYPE.WOOD
end

for _, plantable in ipairs(plantables) do
    AddPrefabPostInit("dug_" .. plantable, add_edible_wood_type)
end
