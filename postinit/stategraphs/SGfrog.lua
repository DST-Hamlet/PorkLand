local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

AddStategraphPostInit("frog", function(sg)
    local _fall_onenter = sg.states["fall"].onenter
    if _fall_onenter then
        sg.states["fall"].onenter = function(inst)
            inst.components.locomotor:Stop()
            _fall_onenter(inst)
        end
    end
end)