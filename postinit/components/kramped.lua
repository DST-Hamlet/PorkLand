local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("kramped", function(self, inst)
    for _, listener in ipairs(inst.inst.event_listening["ms_playerjoined"][TheWorld]) do
        local OnNaughtyAction = ToolUtil.GetUpvalue(listener, "OnKilledOther.OnNaughtyAction")
        if OnNaughtyAction then
            local _activeplayers = ToolUtil.GetUpvalue(inst.OnUpdate, "_activeplayers")
            self.OnNaughtyAction = function(self, how_naughty, player)
                OnNaughtyAction(how_naughty, _activeplayers[player])
            end
            break
        end
    end
end)
