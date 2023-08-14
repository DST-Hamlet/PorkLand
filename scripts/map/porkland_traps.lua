IA_AllTraps = {}

local function AddTraps(area, name)
    if not IA_AllTraps[area] then
        IA_AllTraps[area] = {}
    end

    table.insert(IA_AllTraps[area], name)
    AddLayoutToSanbox("map/traps", area, name)
end

AddTraps("Shipwrecked_Any", "Airstrike")
AddTraps(WORLD_TILES.JUNGLE, "PoisonVines")
AddTraps(WORLD_TILES.TIDALMARSH, "AirPollution")
AddTraps(WORLD_TILES.OCEAN_DEEP, "FeedingFrenzy")
