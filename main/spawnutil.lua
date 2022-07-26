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

function IsWaterTile(ground)
	return WATER_TILES[ground]
end
