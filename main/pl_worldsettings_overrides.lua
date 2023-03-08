GLOBAL.setfenv(1, GLOBAL)

local worldsettings_overrides = require("worldsettings_overrides")
local applyoverrides_post = worldsettings_overrides.Post

local function OverrideTuningVariables(tuning)
    if tuning ~= nil then
        for k, v in pairs(tuning) do
            if BRANCH == "dev" then
                assert(TUNING[k] ~= nil, string.format("%s does not exist in TUNING, either fix the spelling, or add the value to TUNING.", k))
            end
            ORIGINAL_TUNING[k] = TUNING[k]
            TUNING[k] = v
        end
    end
end

local SEASON_VERYHARSH_LENGTHS =
{
    noseason = 0,
    veryshortseason = TUNING.SEASON_LENGTH_VERYHARSH_VERYSHORT,
    shortseason = TUNING.SEASON_LENGTH_VERYHARSH_SHORT,
    default = TUNING.SEASON_VERYHARSH_DEFAULT,
    longseason = TUNING.SEASON_LENGTH_VERYHARSH_LONG,
    verylongseason = TUNING.SEASON_LENGTH_VERYHARSH_VERYLONG,
}

applyoverrides_post.temperate = function(difficulty)
    if difficulty == "random" then
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "autumn", length = GetRandomItem(SEASON_VERYHARSH_LENGTHS), random = true})
    else
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "autumn", length = SEASON_VERYHARSH_LENGTHS[difficulty]})
    end
end

applyoverrides_post.humid = function(difficulty)
    if difficulty == "random" then
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "winter", length = GetRandomItem(SEASON_VERYHARSH_LENGTHS), random = true})
    else
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "winter", length = SEASON_VERYHARSH_LENGTHS[difficulty]})
    end
end

applyoverrides_post.lush = function(difficulty)
    if difficulty == "random" then
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "summer", length = GetRandomItem(SEASON_VERYHARSH_LENGTHS), random = true})
    else
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "summer", length = SEASON_VERYHARSH_LENGTHS[difficulty]})
    end
end

applyoverrides_post.peagawk_setting = function(difficulty)
    local tuning_vars =
    {
        never = {
            PEAGAWK_ENABLED = false,
        },
        few = {
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 15,
        },
        --[[
        default = {
            PEAGAWK_ENABLED = true,
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 10,
        },
        --]]
        many = {
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 5,
        },
        always = {
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 1,
        },
    }
    OverrideTuningVariables(tuning_vars[difficulty])
end

applyoverrides_post.weevole_setting = function(difficulty)
    local tuning_vars =
    {
        never = {
            WEEVOLE_ENABLED = false,
        },
        few = {
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 6,
        },
        --[[
        default = {
            WEEVOLE_ENABLED = true,
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 3,
        },
        --]]
        many = {
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 1.5,
        },
        always = {
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 0.75,
        },
    }
    OverrideTuningVariables(tuning_vars[difficulty])
end

applyoverrides_post.asparagus_regrowth = function(difficulty)
    local tuning_vars =
    {
        never = {
            ASPARAGUS_REGROWTH_TIME_MULT = 0,
        },
        veryslow = {
            ASPARAGUS_REGROWTH_TIME_MULT = 0.25,
        },
        slow = {
            ASPARAGUS_REGROWTH_TIME_MULT = 0.5,
        },
        --[[
        default = {
            ASPARAGUS_REGROWTH_TIME_MULT = 1,
        },
        --]]
        fast = {
            ASPARAGUS_REGROWTH_TIME_MULT = 1.5,
        },
        veryfast = {
            ASPARAGUS_REGROWTH_TIME_MULT = 3,
        },
    }
    OverrideTuningVariables(tuning_vars[difficulty])
end
