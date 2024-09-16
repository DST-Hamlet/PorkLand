local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("earmuffshat", function(inst)
    inst:AddTag("earmuff")
end)
