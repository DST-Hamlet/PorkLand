GLOBAL.setfenv(1, GLOBAL)

AddPrefabRegisterPostInit(function(spoiled_food)
    local spoiled_food_constructor = spoiled_food.fn
    local food_OnIsRaining, i, food_mastersim_init = ToolUtil.GetUpvalue(spoiled_food_constructor, "food_mastersim_init.food_OnIsRaining")
    if not food_OnIsRaining then
        return
    end
    debug.setupvalue(food_mastersim_init, i, function(inst, israining, ...)
        if inst:GetIsInInterior() then
            inst.components.disappears:StopDisappear()
            return
        end
        return food_OnIsRaining(inst, israining, ...)
    end)
end)
