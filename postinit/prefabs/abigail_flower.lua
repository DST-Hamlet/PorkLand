-- local AddPrefabPostInit = AddPrefabPostInit
local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

-- AddPrefabPostInit("abigail_flower", function(inst)

-- end)

AddSimPostInit(function()
    local constructor = Prefabs["abigail_flower"].fn
    local updatespells, i = ToolUtil.GetUpvalue(constructor, "updatespells")
    if updatespells then
        debug.setupvalue(constructor, i, function(inst, owner, ...)
            local should_reopen = owner.HUD and owner.HUD.controls.spellcontrols:IsOpen()
            updatespells(inst, owner, ...)
            if should_reopen then
                owner.HUD.controls.spellcontrols:Open(inst.components.spellbook.items)
            end
        end)
    end
end)
