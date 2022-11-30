GLOBAL.setfenv(1, GLOBAL)

local HomeSeeker = require("components/homeseeker")

function HomeSeeker:ForceGoHome()
	if self:HasHome() then
		if self.home.components.spawner then
			self.home.components.spawner:GoHome(self.inst)
		elseif self.home.components.childspawner then
			self.home.components.childspawner:GoHome(self.inst)
		end
	end
end
