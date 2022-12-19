local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local meatrack_items = {
	venus_stalk = "venus_stalk",
    froglegs_poison = "froglegs_poison",
    walkingstick = "walkingstick",
}

local onstartdryingold
local function onstartdrying(inst, ingredient, buildfile)
	if meatrack_items[ingredient] then
		ingredient = meatrack_items[ingredient]
	end
    if meatrack_items[buildfile] then
		buildfile = meatrack_items[buildfile]
	end
	onstartdryingold(inst, ingredient, buildfile)
end

local ondonedryingold
local function ondonedrying(inst, product, buildfile)
	if meatrack_items[product] then
		product = meatrack_items[product]
	end
    if meatrack_items[buildfile] then
		buildfile = meatrack_items[buildfile]
	end
	ondonedryingold(inst, product, buildfile)
end

AddPrefabPostInit("meatrack", function(inst)
	if TheWorld.ismastersim then
		if not onstartdryingold then
			onstartdryingold = inst.components.dryer.onstartdrying
		end
		inst.components.dryer:SetStartDryingFn(onstartdrying)
		if not ondonedryingold then
			ondonedryingold = inst.components.dryer.ondonedrying
		end
		inst.components.dryer:SetDoneDryingFn(ondonedrying)
	end
end)
