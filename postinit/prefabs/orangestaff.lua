local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("orangestaff", function(inst)
    inst:AddTag("allow_action_on_impassable")
end)
