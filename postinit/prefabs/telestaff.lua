local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("telestaff", function(inst)
    print("AddPrefabPostInit telestaff")
    local teleport_func = inst.components.spellcaster.spell
    local _teleport_start, i = ToolUtil.GetUpvalue(teleport_func, "teleport_start")
    if not _teleport_start then
        return
        print("not _teleport_start")
    end

    local function teleport_start(teleportee, staff, caster, loctarget, target_in_ocean, no_teleport, ...)
        print("teleport_start")
        if teleportee:GetCurrentInteriorID() then
            print("in interior")
            staff.components.finiteuses:Use(1)
            return
        end

        return _teleport_start(teleportee, staff, caster, loctarget, target_in_ocean, no_teleport, ...)
    end

    debug.setupvalue(teleport_func, i, teleport_start)
end)
