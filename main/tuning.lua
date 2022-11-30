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

    LITTLE_HAMMER_DAMAGE = wilson_attack*0.3,
    LITTLE_HAMMER_USES = 10,

    WALKING_STICK_PERISHTIME = total_day_time*3,
    WALKING_STICK_SPEED_MULT = 1.3,
    WALKING_STICK_DAMAGE = wilson_attack*.6,

    HALBERD_DAMAGE = wilson_attack*1.3,
    HALBERD_USES = 100,

    CORK_BAT_DAMAGE = wilson_attack * 1.5,
    CORK_BAT_USES = 20,

    VINE_REGROW_TIME = total_day_time * 4,

    FLYTRAP_CHILD_HEALTH = 250,
    FLYTRAP_CHILD_DAMAGE = 15,
    FLYTRAP_CHILD_SPEED = 4,

    FLYTRAP_TARGET_DIST = 8,
    FLYTRAP_KEEP_TARGET_DIST= 15,
    FLYTRAP_ATTACK_PERIOD =3,
    FLYTRAP_TEEN_HEALTH = 300,
    FLYTRAP_TEEN_DAMAGE = 20,
    FLYTRAP_TEEN_SPEED = 3.5,
    FLYTRAP_HEALTH = 350,
    FLYTRAP_DAMAGE = 25,
    FLYTRAP_SPEED = 3,

    ADULT_FLYTRAP_HEALTH = 400,
    ADULT_FLYTRAP_DAMAGE = 30,
    ADULT_FLYTRAP_ATTACK_PERIOD = 5,
    ADULT_FLYTRAP_ATTACK_DIST = 4,
    ADULT_FLYTRAP_STOPATTACK_DIST = 6,

    HONEY_CHEST_MINE = 6,
    HONEY_CHEST_MINE_MED = 4,
    HONEY_CHEST_MINE_LOW = 2,

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
}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
