local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function CLIENT_Webber_HostileTest(inst, target)
	if target.HostileToPlayerTest ~= nil then
		return target:HostileToPlayerTest(inst)
	end
    return (target:HasTag("hostile") or (inst:HasTag("playermonster") and (target:HasTag("pig") or target:HasTag("catcoon"))))
        and (not target:HasTag("spiderden"))
        and (not target:HasTag("spider") or target:HasTag("spiderqueen"))
end

local function client_postinit(inst)
    inst.HostileTest = CLIENT_Webber_HostileTest
end

AddPrefabPostInit("webber", client_postinit)
