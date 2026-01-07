local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local _CLIENT_Webber_HostileTest = nil

local function CLIENT_Webber_HostileTest(inst, target, ...)
	if target.HostileToPlayerTest == nil 
        and (not inst:HasTag("playermonster") and (target:HasTag("pig") or target:HasTag("catcoon")))
        and not target:HasTag("hostile") then

		return false
	end
    return _CLIENT_Webber_HostileTest(inst, target, ...)
end

local function client_postinit(inst)
    if _CLIENT_Webber_HostileTest == nil then
        _CLIENT_Webber_HostileTest = inst.HostileTest
    end

    inst.HostileTest = CLIENT_Webber_HostileTest
end

AddPrefabPostInit("webber", client_postinit)
