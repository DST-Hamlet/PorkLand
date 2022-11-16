GLOBAL.setfenv(1, GLOBAL)

local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME

local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH

local tuning = {
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
    WEEVOLEDEN_REGEN_TIME = TUNING.SPIDERDEN_REGEN_TIME,
    WEEVOLEDEN_RELEASE_TIME = TUNING.SPIDERDEN_RELEASE_TIME,
    WEEVOLEDEN_MAX_WEEVOLES = 3,

    ASPARAGUS_REGROWTH_TIME = day_time * 20,
    ASPARAGUS_REGROWTH_TIME_MULT = 1,

    CLAWPALMTREE_GROW_TIME = {
        {base = 8 * day_time, random = 0.5 * day_time},   -- tall to short
        {base = 12 * day_time, random = 5 * day_time},   -- short to normal
        {base = 12 * day_time, random = 5 * day_time},   -- normal to tall
    },

    TREE_CREAK_RANGE = 16,

    JUNGLETREE_CHOPS_SMALL = 5,
    JUNGLETREE_CHOPS_NORMAL = 10,
    JUNGLETREE_CHOPS_TALL = 15,
    JUNGLETREE_WINDBLOWN_SPEED = 0.2,
    JUNGLETREE_WINDBLOWN_FALL_CHANCE = 0.01,
}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
