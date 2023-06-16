GLOBAL.setfenv(1, GLOBAL)

TOOLACTIONS.HACK = true
TOOLACTIONS.SHEAR = true
TOOLACTIONS.DISLODGE = true
TOOLACTIONS.BARK = true
TOOLACTIONS.RANSACK = true

SEASONS.TEMPERATE = "temperate"
SEASONS.HUMID = "humid"
SEASONS.LUSH = "lush"
SEASONS.APORKALYPSE = "aporkalypse"

VARIANT_INVATLAS = {}

FUELTYPE.CORK = "CORK"

FOODTYPE.GOLDDUST = "GOLDDUST"

CLIMATES = {
    "forest",
    "cave",
    "island",
    "volcano",
    "porkland",
}
CLIMATE_IDS = table.invert(CLIMATES)

FOG_STATE = {
    SETTING = 1,
    FOGGY = 2,
    LIFTING = 3,
    CLEAR = 4,
}

NUM_RELICS = 5

-- Luckily we dont need to change much due to oceanblending
IA_OCEAN_PREFABS = {
    ["splash_green_small"] = "splash_white_small",
    ["splash_green"] = "splash_white",
    ["splash_green_large"] = "splash_white_large",
    -- ["crab_king_waterspout"] = "splash_white_large",
    ["wave_med"] = "wave_rogue",
    ["wave_splash"] = "splash_water_wave",
}
DST_OCEAN_PREFABS = {
    ["splash_white_small"] = "splash_green_small",
    ["splash_white"] = "splash_green",
    ["splash_white_large"] = "splash_green_large",
    ["bombsplash"] = "splash_green_large",
    ["wave_ripple"] = "wave_med",
    ["wave_rogue"] = "wave_med",
    ["splash_water_wave"] = "wave_splash",
}

if rawget(_G, "GetNextAvaliableCollisionMask") then
    COLLISION.PERMEABLE_GROUND = GetNextAvaliableCollisionMask()
    COLLISION.GROUND = COLLISION.GROUND + COLLISION.PERMEABLE_GROUND
    COLLISION.WORLD = COLLISION.WORLD + COLLISION.PERMEABLE_GROUND
end