GLOBAL.setfenv(1, GLOBAL)

local GhostlyBond = require("components/ghostlybond")

function GhostlyBond:FreezeMovements(should_freeze)
	if self.ghost and self.summoned and self.ghost.FreezeMovements then
		return self.ghost:FreezeMovements(should_freeze)
	end
	return false
end

local _Summon = GhostlyBond.Summon
function GhostlyBond:Summon(summoningitem, ...)
	if self.cansummonfn and not self.cansummonfn(self.inst) then
		return false
	end
	local ret = _Summon(self, summoningitem, ...)
	if ret and self.inst.player_classified then
		self.inst.player_classified._spellcommand_item:set_local(nil)
		self.inst.player_classified._spellcommand_item:set(summoningitem)
	end
	return ret
end


local _RecallComplete = GhostlyBond.RecallComplete
function GhostlyBond:RecallComplete(...)
	if self.prerecallcompletefn ~= nil then
		self.prerecallcompletefn(self.inst, self.ghost)
	end
	return _RecallComplete(self, ...)
end

local _OnUpdate = GhostlyBond.OnUpdate
function GhostlyBond:OnUpdate(...)
	if self.overrideupdatefn then
		return self.overrideupdatefn(self.inst, ...)
	end
	return _OnUpdate(self, ...)
end