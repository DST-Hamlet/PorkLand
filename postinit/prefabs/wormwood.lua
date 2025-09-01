local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("wormwood", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("hayfever")
    inst.components.hayfever.imune = true
end)

AddPrefabRegisterPostInit("wormwood", function(wormwood)
    local wormwood_constructor = wormwood.fn
    local _WatchWorldPlants, aaa, i = ToolUtil.GetUpvalue(wormwood_constructor, "WatchWorldPlants")
    if not _WatchWorldPlants then
        return
    end
    debug.setupvalue(aaa, i, function(inst, ...)
        _WatchWorldPlants(inst, ...)
        local _onplantkilled = inst._onplantkilled
        if _onplantkilled then
            inst:RemoveEventCallback("plantkilled", inst._onplantkilled, TheWorld)
            inst._onplantkilled = function(src, data, ...)
                if data and data.workaction and data.workaction == ACTIONS.HACK then
                    return
                end
                return _onplantkilled(src, data, ...)
            end
            inst:ListenForEvent("plantkilled", inst._onplantkilled, TheWorld)
        end
    end)
end)