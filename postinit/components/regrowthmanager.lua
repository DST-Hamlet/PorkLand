local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("regrowthmanager", function(self, inst)
    if not TheWorld.ismastersim then
        return
    end

    local _worldstate = TheWorld.state

    self:SetRegrowthForType("asparagus_planted", TUNING.ASPARAGUS_REGROWTH_TIME, "asparagus_planted", function()
        return not (_worldstate.islush) and (TUNING.ASPARAGUS_REGROWTH_TIME_MULT * 0.5) or TUNING.ASPARAGUS_REGROWTH_TIME_MULT
    end)
	self:SetRegrowthForType("aloe_planted", TUNING.ASPARAGUS_REGROWTH_TIME, "aloe_planted", function()
        return not (_worldstate.islush) and (TUNING.ALOE_REGROWTH_TIME_MULT * 0.5) or TUNING.ALOE_REGROWTH_TIME_MULT
    end)
	self:SetRegrowthForType("radish_planted", TUNING.ASPARAGUS_REGROWTH_TIME, "radish_planted", function()
        return not (_worldstate.islush) and (TUNING.RADISH_REGROWTH_TIME_MULT * 0.5) or TUNING.RADISH_REGROWTH_TIME_MULT
    end)

    self:SetRegrowthForType("flower_rainforest", TUNING.FLOWER_REGROWTH_TIME, "flower_rainforest", function()
        -- Flowers grow during the day, during not winter, while the ground is still wet after a rain.
        return ((_worldstate.israining or _worldstate.isnight or _worldstate.iswinter or _worldstate.wetness <= 1 or _worldstate.snowlevel > 0) and 0)
            or (_worldstate.isspring and 2 * TUNING.FLOWER_REGROWTH_TIME_MULT)  -- double speed in spring
            or TUNING.FLOWER_REGROWTH_TIME_MULT
    end)
	
	self:SetRegrowthForType("tubertree", TUNING.TUBERTREE_REGROWTH_TIME, "tubertree", function()
        return not (_worldstate.islush) and 0 or TUNING.TUBERTREE_REGROWTH_TIME_MULT
    end)
end)
