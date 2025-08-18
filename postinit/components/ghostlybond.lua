GLOBAL.setfenv(1, GLOBAL)

local GhostlyBond = require("components/ghostlybond")

function GhostlyBond:FreezeMovements(should_freeze)
	if self.ghost and self.summoned and self.ghost.FreezeMovements then
		return self.ghost:FreezeMovements(should_freeze)
	end
	return false
end

local _Summon = GhostlyBond.Summon
function GhostlyBond:Summon(...)
	if self.ghost and self.ghost.components.health and self.ghost.components.health.currenthealth <= 100 then
		return false
	end
	return _Summon(self, ...)
end
