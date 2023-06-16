local AddPrefabPostInitAny = AddPrefabPostInitAny
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInitAny(function(inst)
    if not TheWorld or TheWorld.net ~= inst then
        return
    end

	inst:AddComponent("economy")
	inst:AddComponent("periodicpoopmanager")
    inst:AddComponent("aporkalypse")
end)
