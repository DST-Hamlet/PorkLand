local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function FreezeMovements(inst, should_freeze)
    inst._playerlink:AddOrRemoveTag("has_movements_frozen_follower", should_freeze)
    inst:AddOrRemoveTag("movements_frozen", should_freeze)
end

AddPrefabPostInit("abigail", function(inst)
    inst.FreezeMovements = FreezeMovements
end)
