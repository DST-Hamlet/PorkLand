local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("spoiled_food", function(inst)
    local _watchrainstate = nil
    local _food_OnIsRaining = nil
    for i, v in ipairs(inst.event_listening["ondropped"][inst]) do
        _food_OnIsRaining = ToolUtil.GetUpvalue(v, "food_OnIsRaining")
        _watchrainstate = v
        if _food_OnIsRaining then
            break
        end
    end

    if _food_OnIsRaining ~= nil then
        local function food_OnIsRaining(inst, israining)
            if inst:GetIsInInterior() then
                inst.components.disappears:StopDisappear()
                return
            end
            return _food_OnIsRaining(inst, israining)
        end
        ToolUtil.SetUpvalue(_watchrainstate, food_OnIsRaining, "food_OnIsRaining")
        print("set up value food_OnIsRaining")
    end
end)
