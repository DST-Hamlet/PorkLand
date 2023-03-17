GLOBAL.setfenv(1, GLOBAL)

local ColourCube = require("components/colourcube")

local PL_SEASON_COLOURCUBES = {
    [SEASONS.TEMPERATE] = {
        day = resolvefilepath("images/colour_cubes/pork_temperate_day_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_temperate_dusk_cc.tex"),
        night = resolvefilepath("images/colour_cubes/pork_temperate_night_cc.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_temperate_fullmoon_cc.tex"),
   },
    [SEASONS.HUMID] = {
        day = resolvefilepath("images/colour_cubes/pork_cold_day_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_cold_dusk_cc.tex"),
        night = resolvefilepath("images/colour_cubes/pork_cold_dusk_cc.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_cold_fullmoon_cc.tex"),
     },
    [SEASONS.LUSH] = {
        day = resolvefilepath("images/colour_cubes/pork_lush_day_test.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_lush_dusk_test.tex"),
        night = resolvefilepath("images/colour_cubes/pork_lush_dusk_test.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_warm_fullmoon_cc.tex"),
    },
    [SEASONS.APORKALYPSE] = {
        day = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
        night = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
        full_moon = resolvefilepath("images/colour_cubes/pork_cold_bloodmoon_cc.tex"),
    },
}

function ColourCube:AddPlSeasonColourCube()
    local OnSeasonTick = self.inst:GetEventCallbacks("seasontick", nil, "scripts/components/colourcube.lua")

    local SEASON_COLOURCUBES = nil

    if OnSeasonTick then
        SEASON_COLOURCUBES = Pl_Util.GetUpvalue(OnSeasonTick, "SEASON_COLOURCUBES", 10)  -- OnSeasonTick->UpdateAmbientCCTable->SEASON_COLOURCUBES
    end

    if not SEASON_COLOURCUBES then  -- try again
        local OnPlayerActivated = self.inst:GetEventCallbacks("playeractivated", nil, "scripts/components/colourcube.lua")
        if OnPlayerActivated then
            SEASON_COLOURCUBES = Pl_Util.GetUpvalue(OnPlayerActivated, "SEASON_COLOURCUBES", 10)  -- OnPlayerActivated->OnOverrideCCTable->UpdateAmbientCCTable->SEASON_COLOURCUBES
        end
    end

    if SEASON_COLOURCUBES then
        for season, data in pairs(PL_SEASON_COLOURCUBES) do
            SEASON_COLOURCUBES[season] = data
        end
    end
end
