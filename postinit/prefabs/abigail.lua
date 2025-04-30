local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function FreezeMovements(inst, should_freeze)
    inst._playerlink:AddOrRemoveTag("has_freeze_movement_follower", should_freeze)
    if should_freeze then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "FreezeMovements", 0)
    else
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "FreezeMovements")
    end
end

AddPrefabPostInit("abigail", function(inst)
    inst.FreezeMovements = FreezeMovements
end)
