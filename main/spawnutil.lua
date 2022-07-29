GLOBAL.setfenv(1, GLOBAL)

local WATER_TILES = { [WORLD_TILES.LILYPOND] = true }

local IA_WATER_TILES = {
	"RIVER",
	"OCEAN_SHALLOW",
	"OCEAN_MEDIUM",
	"OCEAN_DEEP",
	"OCEAN_CORAL",
	"OCEAN_SHIPGRAVEYARD",
	"MANGROVE",
}

for _, tile in ipairs(IA_WATER_TILES) do
    if WORLD_TILES[tile] then
        WATER_TILES[WORLD_TILES[tile]] = true
    end
end

function Ham_IsWaterTile(tile)
	return WATER_TILES[tile]
end

function IsLandTile(tile)
	return tile ~= WORLD_TILES.IMPASSABLE
end

local function CheckTile(tile, check)
	if type(check) == "function" then
		return check(tile)
	elseif type(check) == "table" then
		return table.contains(check, tile)
	end

	return check == tile
end

function IsSurroundedByTile(x, y, radius, tile)
	for i = -radius, radius, 1 do
		if not CheckTile(WorldSim:GetTile(x - radius, y + i), tile) or not CheckTile(WorldSim:GetTile(x + radius, y + i), tile) then
			return false
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if not CheckTile(WorldSim:GetTile(x + i, y - radius), tile) or not CheckTile(WorldSim:GetTile(x + i, y + radius), tile) then
			return false
		end
	end
	return true
end

function IsCloseToTIle(x, y, radius, tile)
	for i = -radius, radius, 1 do
		if CheckTile(WorldSim:GetTile(x - radius, y + i), tile) or CheckTile(WorldSim:GetTile(x + radius, y + i), tile) then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if CheckTile(WorldSim:GetTile(x + i, y - radius), tile) or CheckTile(WorldSim:GetTile(x + i, y + radius), tile) then
			return true
		end
	end
	return false
end

function WithinTile(x, y, radius, tile)  -- Simply check the four direction
	local direction = 0
	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x + i, y), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x - i, y), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x, y + i), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x, y - i), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x + i, y + i), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x - i, y + i), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x + i, y - i), tile) then
			direction = direction + 1
			break
		end
	end

	for i = 1, radius do
		if CheckTile(WorldSim:GetTile(x - i, y - i), tile) then
			direction = direction + 1
			break
		end
	end

	return direction == 8
end
