local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("forest_network", function(inst)
    if TheWorld.topology.overrides.isporkland == true then
        inst:AddComponent("worldplateautemperature")
    end
end)
