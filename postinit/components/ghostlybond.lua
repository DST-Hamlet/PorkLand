GLOBAL.setfenv(1, GLOBAL)

local GhostlyBond = require("components/ghostlybond")

function GhostlyBond:FreezeMovements(should_freeze)
	if self.ghost and self.summoned and self.changebehaviourfn then
		return self.ghost:FreezeMovements(should_freeze)
	end
	return false
end
