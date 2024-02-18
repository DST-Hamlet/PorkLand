GLOBAL.setfenv(1, GLOBAL)

local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME

local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH

local tuning = {
    SEASON_LENGTH_VERYHARSH_VERYSHORT = 5,
    SEASON_LENGTH_VERYHARSH_SHORT = 7,
    SEASON_VERYHARSH_DEFAULT = 10,
    SEASON_LENGTH_VERYHARSH_LONG = 15,
    SEASON_LENGTH_VERYHARSH_VERYLONG = 20,

    TEMPERATE_LENGTH = 10,
    HUMID_LENGTH = 10,
    LUSH_LENGTH = 10,
    APORKALYPSE_LENGTH = 20,

    APORKALYPSE_NEAR_TIME = 7 * total_day_time,
    APORKALYPSE_PERIOD_LENGTH = 60 * total_day_time,

    MACHETE_DAMAGE = wilson_attack * .88,
    MACHETE_USES = 100,

    PEAGAWK_DAMAGE = 20,
    PEAGAWK_HEALTH = 50,
    PEAGAWK_ATTACK_PERIOD = 3,
    PEAGAWK_RUN_SPEED = 8,
    PEAGAWK_WALK_SPEED = 3,
    PEAGAWK_FEATHER_REGROW_TIME = total_day_time,
    PEAGAWK_PICKTIMER = 180,
    PEAGAWK_PRISM_STOP_TIMER = 45,
    PEAGAWK_TAIL_FEATHERS_MAX = 7,
    PEAGAWK_REGEN_TIME = total_day_time * 10,
    PEAGAWK_RELEASE_TIME = 5,
    PEAGAWK_MAX = 1,
    PEAGAWK_ENABLED = true,

    SHEARS_DAMAGE = wilson_attack * .5,
    SHEARS_USES = 20,

    VINE_REGROW_TIME = total_day_time * 4,

    WEEVOLE_ENABLED = true,
    WEEVOLE_WALK_SPEED = 5,
    WEEVOLE_HEALTH = 150,
    WEEVOLE_DAMAGE = 6,
    WEEVOLE_PERIOD_MIN = 4,
    WEEVOLE_PERIOD_MAX = 5,
    WEEVOLE_ATTACK_RANGE = 5,
    WEEVOLE_HIT_RANGE = 1.5,
    WEEVOLE_MELEE_RANGE = 1.5,
    WEEVOLE_RUN_AWAY_DIST = 3,
    WEEVOLE_STOP_RUN_AWAY_DIST = 5,
    WEEVOLE_TARGET_DIST = 6,
    WEEVOLE_SHARE_TARGET_RANGE = 30,
    WEEVOLE_SHARE_MAX_NUM = 10,
    WEEVOLEDEN_REGEN_TIME = TUNING.SEG_TIME * 3,
    WEEVOLEDEN_RELEASE_TIME = 5,
    WEEVOLEDEN_MAX_WEEVOLES = 3,

    GLOWFLY_COCOON_HEALTH = 300,

    GLOWFLY_WALK_SPEED = 6,
    GLOWFLY_RUN_SPEED = 8,

    GLOWFLY_DELAY_DEFAULT = 5,
    GLOWFLY_DELAY_MIN = 2,
    GLOWFLY_DELAY_MAX = 50,

    GLOWFLY_BASEDELAY_DEFAULT = 5,
    GLOWFLY_BASEDELAY_MIN = 0,
    GLOWFLY_BASEDELAY_MAX = 50,

    GLOWFLY_DEFAULT = 7,
    GLOWFLY_MAX = 14,
    GLOWFLY_MIN = 0,

    RABID_BEETLE_HEALTH = 60,
    RABID_BEETLE_DAMAGE =  10,
    RABID_BEETLE_ATTACK_PERIOD = 2,
    RABID_BEETLE_TARGET_DIST = 20,
    RABID_BEETLE_SPEED = 12,
    RABID_BEETLE_FOLLOWER_TARGET_DIST = 10,
    RABID_BEETLE_FOLLOWER_TARGET_KEEP = 20,

    ASPARAGUS_REGROWTH_TIME = day_time * 20,
    ASPARAGUS_REGROWTH_TIME_MULT = 1,

    CLAWPALMTREE_GROW_TIME = {
        {base = 8 * day_time, random = 0.5 * day_time},  -- tall to short
        {base = 12 * day_time, random = 5 * day_time},   -- short to normal
        {base = 12 * day_time, random = 5 * day_time},   -- normal to tall
    },

    TREE_CREAK_RANGE = 16,

    JUNGLETREE_CHOPS_SMALL = 5,
    JUNGLETREE_CHOPS_NORMAL = 10,
    JUNGLETREE_CHOPS_TALL = 15,
    JUNGLETREE_WINDBLOWN_SPEED = 0.2,
    JUNGLETREE_WINDBLOWN_FALL_CHANCE = 0.01,

    POISON_PERISH_PENALTY = 0.5,
    POISON_HUNGER_DRAIN_MOD = 0.80,
    POISON_DAMAGE_MOD = -0.25,
    POISON_ATTACK_PERIOD_MOD = 0.25,
    POISON_SPEED_MOD = 0.75,
    POISON_SANITY_SCALE = 0.05, -- sanity hit = poison hit * POISON_SANITY_SCALE  set to 0 to turn off

    POISON_IMMUNE_DURATION = total_day_time, -- the time you are immune to poison after taking antivenom
    POISON_DURATION = 120, -- the time in seconds that poison normally endures
    POISON_DAMAGE_PER_INTERVAL = 2, -- the amount of health damage poison causes per interval
    POISON_INTERVAL = 10, -- how frequently damage is applied

    POISON_DAMAGE_RAMP = {-- Elapsed time must be greater than the time value for the associated damage_scale/fxlevel value to be used
        -- (total damage after 3 days: 289.54)
        {time = 0.00 * total_day_time, damage_scale = 0.50, interval_scale = 1.0, fxlevel = 1}, -- 48.00 DMG
        {time = 1.00 * total_day_time, damage_scale = 0.75, interval_scale = 1.0, fxlevel = 1}, -- 54.00 DMG
        {time = 1.75 * total_day_time, damage_scale = 1.00, interval_scale = 1.0, fxlevel = 2}, -- 48.00 DMG
        {time = 2.25 * total_day_time, damage_scale = 1.25, interval_scale = 0.9, fxlevel = 2}, -- 60.00 DMG
        {time = 2.70 * total_day_time, damage_scale = 1.50, interval_scale = 0.7, fxlevel = 3}, -- 41.14 DMG
        {time = 2.90 * total_day_time, damage_scale = 2.00, interval_scale = 0.5, fxlevel = 4}, -- 38.40 DMG
    },

    FOG_MOISTURE_RATE_SCALE = 0.6,

    WINDBLOWN_DESTROY_DIST = 15,  -- distance from player wind blown prefabs can be destroyed, fall over, get picked, etc
    WINDBLOWN_SCALE_MIN = {
        LIGHT = 0.1,
        MEDIUM = 0.1,
        HEAVY = 0.01,
    },
    WINDBLOWN_SCALE_MAX = {
        LIGHT = 1.0,
        MEDIUM = 0.25,
        HEAVY = 0.05,
    },

    ARMORMETAL = wilson_health * 8,
    ARMORMETAL_ABSORPTION = .85,
    ARMORMETAL_SLOW = 0.9,  -- -0.10,

    HALBERD_DAMAGE = wilson_attack * 1.3,
    HALBERD_USES = 100,

    HYDRO_BONUS_COOL_RATE = 4,

    PIKO_HEALTH = 100,
    PIKO_RESPAWN_TIME = day_time * 4,
    PIKO_RUN_SPEED = 4,
    PIKO_DAMAGE = 2,
    PIKO_ATTACK_PERIOD = 2,
    PIKO_TARGET_DIST = 20,

    CAFFEINE_FOOD_BONUS_SPEED = 5, -- player base speed plus this, 6 is normal walk speed
    FOOD_SPEED_BRIEF = 0, -- eating coffeebeans gives you the bonus for this many seconds
    FOOD_SPEED_AVERAGE = 30, -- eating roasted coffee beans
    FOOD_SPEED_MED = 60, -- eating tropicalbouillabaisse (effects)
    FOOD_SPEED_LONG = total_day_time / 2, -- drinking coffee

    TEATREE_CHOPS_SHORT = 5,
    TEATREE_CHOPS_NORMAL = 10,
    TEATREE_CHOPS_TALL = 15,

    TEATREE_GROW_TIME =
    {
        {base = 1.5 * day_time, random = 0.5 * day_time},   --short
        {base = 5 * day_time,   random = 2 * day_time},   --normal
        {base = 5 * day_time,   random = 2 * day_time},   --tall
        {base = 1 * day_time,   random = 0.5 * day_time}   --old
    },
}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
