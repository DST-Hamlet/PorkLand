local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("spoiled_food", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local food_OnDropped = inst:GetEventCallbacks("ondropped", inst, "scripts/prefabs/spoiledfood.lua")
    if not food_OnDropped then
        return
    end
    local food_OnIsRaining, i = ToolUtil.GetUpvalue(food_OnDropped, "food_OnIsRaining")
    if not food_OnIsRaining then
        return
    end
    debug.setupvalue(food_OnDropped, i, function(inst, israining)
        if inst:GetIsInInterior() then
            inst.components.disappears:StopDisappear()
            return
        end
        return food_OnIsRaining(inst, israining)
    end)
end)
