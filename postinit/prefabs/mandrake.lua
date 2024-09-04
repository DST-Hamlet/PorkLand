local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("mandrake", function(inst)
    inst:AddTag("mandrake")
end)
