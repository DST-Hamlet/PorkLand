local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("kramped", function(self, inst)
    local OnPlayerJoined = inst:GetEventCallbacks("ms_playerjoined", TheWorld, "scripts/components/kramped.lua")
    local OnNaughtyAction = ToolUtil.GetUpvalue(OnPlayerJoined, "OnKilledOther.OnNaughtyAction")
    local _activeplayers = ToolUtil.GetUpvalue(self.OnUpdate, "_activeplayers")
    self.OnNaughtyAction = function(_self, how_naughty, player)
        OnNaughtyAction(how_naughty, _activeplayers[player])
    end
end)
