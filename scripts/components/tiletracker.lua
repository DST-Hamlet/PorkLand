local TileTracker = Class(function(self, inst)
	self.inst = inst
	self.tile = nil
	self.tileinfo = nil
	self.ontilechangefn = nil
	self.onwater = nil
	self.ongas = nil
	self.onwaterchangefn = nil
	self.ongaschangefn = nil
end)

-- function TileTracker:OnEntitySleep()
-- end

-- function TileTracker:OnEntityWake()
-- end

function TileTracker:Start()
	self.inst:StartUpdatingComponent(self)
end

function TileTracker:Stop()
	self.inst:StopUpdatingComponent(self)
end

local function IsWater(tile)
	return tile == GROUND.OCEAN_MEDIUM or
		tile == GROUND.OCEAN_DEEP or
		tile == GROUND.OCEAN_SHALLOW or
		tile == GROUND.OCEAN_SHORE or
		tile == GROUND.OCEAN_CORAL or
		tile == GROUND.OCEAN_CORAL_SHORE or
		tile == GROUND.OCEAN_SHIPGRAVEYARD or
		tile == GROUND.MANGROVE or
		tile == GROUND.MANGROVE_SHORE or
		tile == GROUND.LILYPOND
end

local function IsGas(tile)
	return tile == GROUND.GASJUNGLE
end

function TileTracker:OnUpdate(dt)

	local tile, tileinfo = self.inst:GetCurrentTileType()


	if tile and tile ~= self.tile then
		self.tile = tile
		if self.ontilechangefn then
			self.ontilechangefn(self.inst, tile, tileinfo)
		end

		if self.onwaterchangefn or self.inst:HasTag("amphibious") then
			-- local onwater = GetWorld().Map:IsWater(tile)
			local onwater = IsWater(tile)

			if onwater ~= self.onwater then
				if self.onwaterchangefn then
					self.onwaterchangefn(self.inst, onwater)
				end
				if self.inst:HasTag("amphibious") then
					if onwater then
						self.inst:AddTag("aquatic")
					else
						self.inst:RemoveTag("aquatic")
					end
				end
			end
			self.onwater = onwater
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
end

function TileTracker:SetOnTileChangeFn(fn)
	self.ontilechangefn = fn
end

function TileTracker:SetOnWaterChangeFn(fn)
	self.onwaterchangefn = fn
end

function TileTracker:SetOnGasChangeFn(fn)
	self.ongaschangefn = fn
end

function TileTracker:GetDebugString()
    local str = "TILE TRACKER"

	return str
end

return TileTracker