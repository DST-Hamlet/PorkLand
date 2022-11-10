-- local seg_time = 30 
-- local total_day_time = seg_time*16
-- local day_segs = 10
-- local dusk_segs = 4
-- local night_segs = 2

-- local day_time = seg_time * day_segs
-- local dusk_time = seg_time * dusk_segs
-- local night_time = seg_time * night_segs
local wilson_attack = 34
-- local wilson_health = 150
-- local calories_per_day = 75
-- local wilson_attack_period = .5

-- local perish_warp = 1--/200

local tuning = {
    PEAGAWK_DAMAGE = 20,
    PEAGAWK_HEALTH = 50,
    PEAGAWK_ATTACK_PERIOD = 3,
    PEAGAWK_RUN_SPEED = 8,
    PEAGAWK_WALK_SPEED = 3,
    PEAGAWK_FEATHER_REGROW_TIME = TUNING.TOTAL_DAY_TIME,
    PEAGAWK_PICKTIMER = 180,
    PEAGAWK_PRISM_STOP_TIMER = 45,
    PEAGAWK_TAIL_FEATHERS_MAX = 7,
    PEAGAWK_REGEN_TIME = TUNING.TOTAL_DAY_TIME * 10,
    PEAGAWK_RELEASE_TIME = 5,
    PEAGAWK_MAX = 1,
    PEAGAWK_ENABLED = true,


    SHEARS_DAMAGE = wilson_attack * .5,
    SHEARS_USES = 20,
}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("waring, override" .. key .. "in TUNING")
    end

    TUNING[key] = value
end
