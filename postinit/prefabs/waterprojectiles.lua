local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("snowball", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.wateryprotection.addcoldness = 0
end)
