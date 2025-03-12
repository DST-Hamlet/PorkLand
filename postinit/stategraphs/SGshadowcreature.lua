local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

AddStategraphPostInit("shadowcreature", function(sg)
    local _hit_animover = sg.states["hit"].events.animover.fn
    sg.states["hit"].events.animover.fn = function(inst, ...)
        local x0, y0, z0 = inst.Transform:GetWorldPosition()
        if TheWorld.Map:ReverseIsVisualWaterAtPoint(x0, y0, z0) then
            for k = 1, 4 --[[# of attempts]] do
                local x = x0 + math.random() * 20 - 10
                local z = z0 + math.random() * 20 - 10
                if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, 0, z) then
                    inst.Physics:Teleport(x, 0, z)
                    inst.sg:GoToState("appear")
                    return
                end
            end
        end

        _hit_animover(inst, ...)
    end
end)
