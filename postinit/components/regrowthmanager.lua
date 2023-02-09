local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("regrowthmanager", function(self, inst)
    if not TheWorld.ismastersim then
        return
    end

    local _worldstate = TheWorld.state

    self:SetRegrowthForType("asparagus_planted", TUNING.ASPARAGUS_REGROWTH_TIME, "asparagus_planted", function()
        return not (_worldstate.issummer) and (TUNING.ASPARAGUS_REGROWTH_TIME_MULT * 0.5) or TUNING.ASPARAGUS_REGROWTH_TIME_MULT
    end)
end)
