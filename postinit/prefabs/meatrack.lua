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

    local _OnStartDrying = inst.components.dryer.onstartdrying
    local function OnStartDrying(inst, ingredient, buildfile)
        if meatrack_items[ingredient] then
            ingredient = meatrack_items[ingredient]
            buildfile = pl_buildfile
        end
        _OnStartDrying(inst, ingredient, buildfile)
    end

    inst.components.dryer:SetStartDryingFn(OnStartDrying)

    local _ondonedrying = inst.components.dryer.ondonedrying
    local function OnDoneDrying(inst, product, buildfile)
        if meatrack_items[product] then
            product = meatrack_items[product]
            buildfile = pl_buildfile
        end
        _ondonedrying(inst, product, buildfile)
    end

    inst.components.dryer:SetDoneDryingFn(OnDoneDrying)

    local _StartDrying = inst.components.dryer.StartDrying
    local function StartDrying(self, dryable, ...)
        if inst:GetIsInInterior() then
            inst.components.dryer.protectedfromrain = true
        else
            inst.components.dryer.protectedfromrain = nil
        end
        return _StartDrying(self, dryable, ...)
    end

    inst.components.dryer.StartDrying = StartDrying
end)
