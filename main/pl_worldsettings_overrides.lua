GLOBAL.setfenv(1, GLOBAL)

local worldsettings_overrides = require("worldsettings_overrides")
local applyoverrides_pre = worldsettings_overrides.Pre
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

--------------------------------------------------------------------------
--[[ WORLDSETTINGS PRE ]]
--------------------------------------------------------------------------

applyoverrides_pre.peagawk_setting = function(difficulty)
    local tuning_vars =
    {
        never = {
            PEAGAWK_ENABLED = false,
        },
        rare = {
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 15,
        },
        --[[
        default = {
            PEAGAWK_ENABLED = true,
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 10,
        },
        --]]
        often = {
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 5,
        },
        always = {
            PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 1,
        },
    }
    OverrideTuningVariables(tuning_vars[difficulty])
end

applyoverrides_pre.weevole_setting = function(difficulty)
    local tuning_vars =
    {
        never = {
            WEEVOLE_ENABLED = false,
        },
        rare = {
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 6,
        },
        --[[
        default = {
            WEEVOLE_ENABLED = true,
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 3,
        },
        --]]
        often = {
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 1.5,
        },
        always = {
            WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 0.75,
        },
    }
    OverrideTuningVariables(tuning_vars[difficulty])
end

applyoverrides_pre.glowfly_setting = function(difficulty)
    local tuning_vars =
    {
        never = {
            GLOWFLY_DEFAULT = 0,
            GLOWFLY_MAX = 0,
        },
        rare = {
            GLOWFLY_DELAY_DEFAULT = 15,
            GLOWFLY_DELAY_MIN = 5,

            GLOWFLY_BASEDELAY_DEFAULT = 15,
            GLOWFLY_BASEDELAY_MIN = 2,

            GLOWFLY_DEFAULT = 2,
            GLOWFLY_MAX = 8,
        },
        --[[
        default = {
            GLOWFLY_DELAY_DEFAULT = 5,
            GLOWFLY_DELAY_MIN = 2,

            GLOWFLY_BASEDELAY_DEFAULT = 5,
            GLOWFLY_BASEDELAY_MIN = 0,

            GLOWFLY_DEFAULT = 7,
            GLOWFLY_MAX = 14,
        },
        --]]
        often = {
            GLOWFLY_DELAY_DEFAULT = 4,
            GLOWFLY_DELAY_MIN = 1,

            GLOWFLY_BASEDELAY_DEFAULT = 4,
            GLOWFLY_BASEDELAY_MIN = 0,

            GLOWFLY_DEFAULT = 10,
            GLOWFLY_MAX = 16,
        },
        always = {
            GLOWFLY_DELAY_DEFAULT = 3,
            GLOWFLY_DELAY_MIN = 1,

            GLOWFLY_BASEDELAY_DEFAULT = 3,
            GLOWFLY_BASEDELAY_MIN = 0,

            GLOWFLY_DEFAULT = 14,
            GLOWFLY_MAX = 18,
        },
    }
    OverrideTuningVariables(tuning_vars[difficulty])
end

applyoverrides_pre.asparagus_regrowth = function(difficulty)
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

--------------------------------------------------------------------------
--[[ WORLDSETTINGS POST ]]
--------------------------------------------------------------------------

applyoverrides_post.temperate = function(difficulty)
    if difficulty == "random" then
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "temperate", length = GetRandomItem(SEASON_VERYHARSH_LENGTHS), random = true})
    else
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "temperate", length = SEASON_VERYHARSH_LENGTHS[difficulty]})
    end
end

applyoverrides_post.humid = function(difficulty)
    if difficulty == "random" then
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "humid", length = GetRandomItem(SEASON_VERYHARSH_LENGTHS), random = true})
    else
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "humid", length = SEASON_VERYHARSH_LENGTHS[difficulty]})
    end
end

applyoverrides_post.lush = function(difficulty)
    if difficulty == "random" then
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "lush", length = GetRandomItem(SEASON_VERYHARSH_LENGTHS), random = true})
    else
        TheWorld:PushEvent("ms_setseasonlength_plateau", {season = "lush", length = SEASON_VERYHARSH_LENGTHS[difficulty]})
    end
end

applyoverrides_post.fog = function(difficulty)
    if difficulty == "never" then
        TheWorld:PushEvent("ms_setfogmode", "never")
    elseif difficulty == "default" then
        TheWorld:PushEvent("ms_setfogmode", "dynamic")
    end
end

applyoverrides_post.glowflycycle = function(difficulty)
    if difficulty == "never" then
        TheWorld:PushEvent("ms_setglowflycycle", false)
    elseif difficulty == "default" then
        TheWorld:PushEvent("ms_setglowflycycle", true)
    end
end
