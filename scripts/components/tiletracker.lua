local TileTracker = Class(function(self, inst)
	self.inst = inst
	self.tile = nil
	self.tileinfo = nil
    self.ontilechangefn = nil
	self.ongas = nil
	self.ongaschangefn = nil

	if not self.inst:IsAsleep() then
		self.inst:StartUpdatingComponent(self)
	end

end)

function TileTracker:OnEntitySleep()
	self.inst:StopUpdatingComponent(self)
end

function TileTracker:OnEntityWake()
	self.inst:StartUpdatingComponent(self)
end

function TileTracker:OnUpdate(dt)
	local tile, tileinfo = self.inst:GetCurrentTileType()

    if tile ~= nil and tile ~= self.tile then
		self.tile = tile
        self.tileinfo = tileinfo
		if self.ontilechangefn then
			self.ontilechangefn(self.inst, tile, tileinfo)
		end
    end
	if self.ongaschangefn then
		local ongas = IsGas(tile)

		if ongas ~= self.ongas then
			if self.ongaschangefn then
				self.ongaschangefn(self.inst, ongas)
			end
		end
		self.ongas = ongas
	end
end

function TileTracker:ShouldTransition(x, z)
    local _map = TheWorld.map

	if self.tile ~= _map:GetTileAtPoint(x, 0, z) then
		return true
	end

	return false
end

function TileTracker:SetOnTileChangeFn(fn)
    self.ontilechangefn = fn
end
-- Note: water tracking functionality stripped from tiletracker as dst's amphibius creature component does the same thing but with better integration (note dst's amphibius creature component is a stripped down copy of ds's tiletracker)
function TileTracker:SetOnWaterChangeFn(fn)
    assert(false, "Use AmphibiousCreature for water tracking")
-- self.onwaterchangefn = fn
end

function TileTracker:GetDebugString()
	return "tile: " .. tostring(self.tile)
end

function TileTracker:SetOnGasChangeFn(fn)
	self.ongaschangefn = fn
end

return TileTracker
