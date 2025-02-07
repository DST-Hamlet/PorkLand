local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function on_is_vampire_bat_wing(inst)
    if inst._is_vampire_bat_wing:value() then
        inst:SetPrefabNameOverride("vampire_bat_wing")
    end
end

AddPrefabPostInit("batwing", function(inst)
    inst._is_vampire_bat_wing = net_bool(inst.GUID, "batwing._is_vampire_bat_wing", "on_is_vampire_bat_wing")
    inst:ListenForEvent("on_is_vampire_bat_wing", on_is_vampire_bat_wing)

    if inst.is_vampire_bat_wing then
        inst._is_vampire_bat_wing:set(true)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    local on_save = inst.OnSave or function() end
    inst.OnSave = function(inst, data, ...)
        if inst._is_vampire_bat_wing:value() then
            data.is_vampire_bat_wing = true
        end
        return on_save(inst, data, ...)
    end

    local on_load = inst.OnLoad or function() end
    inst.OnLoad = function(inst, data, ...)
        if data and data.is_vampire_bat_wing then
            inst._is_vampire_bat_wing:set(true)
        end
        return on_load(inst, data, ...)
    end
end)
