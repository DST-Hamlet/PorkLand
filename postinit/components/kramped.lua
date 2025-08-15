local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("kramped", function(self, inst)
    local OnPlayerJoined = inst:GetEventCallbacks("ms_playerjoined", TheWorld, "scripts/components/kramped.lua")
    local OnKilledOther = ToolUtil.GetUpvalue(OnPlayerJoined, "OnKilledOther")
    local OnNaughtyAction, scope_fn, i = ToolUtil.GetUpvalue(OnKilledOther, "OnNaughtyAction")

    local New_OnNaughtyAction = function(how_naughty, playerdata, ...)
        if playerdata.player:GetIsInInterior() then
            if playerdata.threshold == nil then
                playerdata.threshold = TUNING.KRAMPUS_THRESHOLD + math.random(TUNING.KRAMPUS_THRESHOLD_VARIANCE)
            end

            playerdata.actions = playerdata.actions + (how_naughty or 1)
            playerdata.timetodecay = TUNING.KRAMPUS_NAUGHTINESS_DECAY_PERIOD

            if how_naughty > 0 then
                playerdata.player.kramped_interior_up = true
            end

            return
        else
            OnNaughtyAction(how_naughty, playerdata, ...)
        end
    end
    debug.setupvalue(scope_fn, i, New_OnNaughtyAction)

    local _activeplayers = ToolUtil.GetUpvalue(self.OnUpdate, "_activeplayers")

    self.OnNaughtyAction = function(self, how_naughty, player)
        if _activeplayers[player] then
            New_OnNaughtyAction(how_naughty, _activeplayers[player])
        end
    end
end)
