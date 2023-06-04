local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local AmphibiousCreature = require("components/amphibiouscreature")

function AmphibiousCreature:SetBuilds(land, ocean)
	self.land_build = land
	self.ocean_build = ocean
end

local _OnEnterOcean = AmphibiousCreature.OnEnterOcean
function AmphibiousCreature:OnEnterOcean(...)
	if not self.in_water then
		if self.ocean_build then
			self.inst.AnimState:SetBuild(self.ocean_build)
		end
	end
	return _OnEnterOcean(self, ...)
end

local _OnExitOcean = AmphibiousCreature.OnExitOcean
function AmphibiousCreature:OnExitOcean(...)
	if self.in_water then
		if self.land_build then
			self.inst.AnimState:SetBuild(self.land_build)
		end
	end
	return _OnExitOcean(self, ...)
end

IAENV.AddComponentPostInit("amphibiouscreature", function(cmp)
	cmp.land_build = nil
	cmp.ocean_build = nil
end)
