local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local pl_buildfile = "meat_rack_food_pl"

local meatrack_items = {
    venus_stalk = "venus_stalk",
    walkingstick = "walkingstick",
    froglegs_poison = "froglegs_poison"
}

PLENV.AddPrefabPostInit("meatrack", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local old_onstartdrying = inst.components.dryer.onstartdrying
    function inst.components.dryer.onstartdrying(inst, ingredient, buildfile)
    	if meatrack_items[ingredient] then
            ingredient = meatrack_items[ingredient]
            buildfile = pl_buildfile
        end
        old_onstartdrying(inst, ingredient, buildfile)
    end

    local old_ondonedrying = inst.components.dryer.ondonedrying
    function inst.components.dryer.ondonedrying(inst, product, buildfile)
        if meatrack_items[product] then
            product = meatrack_items[product]
            buildfile = pl_buildfile
        end
        old_ondonedrying(inst, product, buildfile)
    end
end)
