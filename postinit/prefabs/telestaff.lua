GLOBAL.setfenv(1, GLOBAL)

AddPrefabRegisterPostInit(function(telestaff)
    local telestaff_constructor = telestaff.fn
    local teleport_start, teleport_func, i = ToolUtil.GetUpvalue(telestaff_constructor, "teleport_func.teleport_start")
    if not teleport_start then
        return
    end
    debug.setupvalue(teleport_func, i, function(teleportee, staff, caster, loctarget, target_in_ocean, no_teleport, ...)
        -- print("teleport_start")
        if teleportee:GetCurrentInteriorID() then
            -- print("in interior")
            staff.components.finiteuses:Use(1)
            return
        end
        return teleport_start(teleportee, staff, caster, loctarget, target_in_ocean, no_teleport, ...)
    end)
end)
