GLOBAL.setfenv(1, GLOBAL)

local worldsettings_overrides = require("worldsettings_overrides")
local applyoverrides_post = worldsettings_overrides.Post

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
