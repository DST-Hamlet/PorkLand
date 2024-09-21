local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function on_is_bat_hide(inst)
    if inst._is_bat_hide:value() then
        inst.AnimState:SetBank("bat_leather")
        inst.AnimState:SetBuild("bat_leather")
        inst:SetPrefabNameOverride("bat_hide")

        if TheWorld.ismastersim then
            inst.components.inventoryitem:ChangeImageName("bat_leather")
        end
    end
end

AddPrefabPostInit("pigskin", function(inst)
    inst._is_bat_hide = net_bool(inst.GUID, "pigskin._is_bat_hide", "on_is_bat_hide")
    inst:ListenForEvent("on_is_bat_hide", on_is_bat_hide)

    if inst.is_bat_hide then
        inst._is_bat_hide:set(true)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    local on_save = inst.OnSave or function() end
    inst.OnSave = function(inst, data, ...)
        if inst._is_bat_hide:value() then
            data.is_bat_hide = true
        end
        return on_save(inst, data, ...)
    end

    local on_load = inst.OnLoad or function() end
    inst.OnLoad = function(inst, data, ...)
        if data and data.is_bat_hide then
            inst._is_bat_hide:set(true)
        end
        return on_load(inst, data, ...)
    end
end)
