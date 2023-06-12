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

    WINDBLOWN_SCALE_MIN =
    {
        LIGHT = 0.1,
        MEDIUM = 0.1,
        HEAVY = 0.01
    },
    WINDBLOWN_SCALE_MAX =
    {
        LIGHT = 1.0,
        MEDIUM = 0.25,
        HEAVY = 0.05
    },

    WINDPROOFNESS_SMALL = 0.2,
    WINDPROOFNESS_SMALLMED = 0.35,
    WINDPROOFNESS_MED = 0.5,
    WINDPROOFNESS_LARGE = 0.7,
    WINDPROOFNESS_HUGE = 0.9,
    WINDPROOFNESS_ABSOLUTE = 1,

    GNATMOUND_REGEN_TIME = seg_time * 4,
    GNATMOUND_RELEASE_TIME = seg_time,
    GNATMOUND_MAX_WORK	= 6,
    GNATMOUND_MAX_CHILDREN	= 1,

    GNAT_WALK_SPEED = 2,
    GNAT_RUN_SPEED = 7,

    THUNDERBIRD_RUN_SPEED = 5.5,
    THUNDERBIRD_WALK_SPEED = 2,

    PANGOLDEN_HEALTH = 500 * 2,--Changed in DST
    PANGOLDEN_DAMAGE = 34,
    PANGOLDEN_TARGET_DIST = 5,

    PANGOLDEN_CHASE_DIST = 30,
    PANGOLDEN_BALL_DEFENCE = 0.75,

    TUBERTREE_REGROWTH_TIME = total_day_time * 5,
    TUBERTREE_REGROWTH_TIME_MULT = 1,

    PALMTREEGUARD_REAWAKEN_RADIUS = 20,

    JUNGLETREE_CHOPS_SMALL = 5,
    JUNGLETREE_CHOPS_NORMAL = 10,
    JUNGLETREE_CHOPS_TALL = 15,
    JUNGLETREE_WINDBLOWN_SPEED = 0.2,
    JUNGLETREE_WINDBLOWN_FALL_CHANCE = 0.01,

       JUNGLETREESEED_GROWTIME = {base=4.5*day_time, random=0.75*day_time},

    JUNGLETREE_GROW_TIME =
    {
        {base=4.5*day_time, random=0.5*day_time},   --tall to short
        {base=8*day_time, random=5*day_time},   --short to normal
        {base=8*day_time, random=5*day_time},   --normal to tall
    },

    SNAKE_SPEED = 3,
    SNAKE_TARGET_DIST = 8,
    SNAKE_KEEP_TARGET_DIST= 15,
    SNAKE_HEALTH = 100,
    SNAKE_DAMAGE = 10,
    SNAKE_ATTACK_PERIOD = 3,
    SNAKE_POISON_CHANCE = 0.25,
    SNAKE_POISON_START_DAY = 3, -- the day that poison snakes have a chance to show up
    SNAKEDEN_REGEN_TIME = 3*seg_time,
    SNAKEDEN_RELEASE_TIME = 5,
    SNAKE_JUNGLETREE_CHANCE = 0.5, -- chance of a normal snake
    SNAKE_JUNGLETREE_POISON_CHANCE = 0.25, -- chance of a poison snake
    SNAKE_JUNGLETREE_AMOUNT_TALL = 2, -- num of times to try and spawn a snake from a tall tree
    SNAKE_JUNGLETREE_AMOUNT_MED = 1, -- num of times to try and spawn a snake from a normal tree
    SNAKE_JUNGLETREE_AMOUNT_SMALL = 1, -- num of times to try and spawn a snake from a small tree
    SNAKEDEN_MAX_SNAKES = 3,
    SNAKEDEN_CHECK_DIST = 20,
    SNAKEDEN_TRAP_DIST = 2,

    WRATH_SMALL = -8,
    WRATH_LARGE = -16,

    SCORPION_HEALTH = 200,
    SCORPION_DAMAGE = 20,
    SCORPION_ATTACK_PERIOD = 3,
    SCORPION_TARGET_DIST = 4,
    SCORPION_INVESTIGATETARGET_DIST = 6,
    SSCORPION_WAKE_RADIUS = 4,
    SCORPION_FLAMMABILITY = .33,
    SCORPION_SUMMON_WARRIORS_RADIUS = 12,
    SCORPION_EAT_DELAY = 1.5,
    SCORPION_ATTACK_RANGE = 3,
    SCORPION_STING_RANGE = 2,

    SCORPION_WALK_SPEED = 3,
    SCORPION_RUN_SPEED = 5,

    SPIDER_MONKEY_SPEED_AGITATED = 5.5,  --4
    SPIDER_MONKEY_SPEED = 5.5, --2
    SPIDER_MONKEY_HEALTH = 550 * 2,--Changed in DST

    SPIDER_MONKEY_DAMAGE = 60,
    SPIDER_MONKEY_ATTACK_PERIOD = 2,
    SPIDER_MONKEY_ATTACK_RANGE = 4,
    SPIDER_MONKEY_HIT_RANGE = 3,
    SPIDER_MONKEY_MELEE_RANGE = 4,
    SPIDER_MONKEY_TARGET_DIST = 8,
    SPIDER_MONKEY_WAKE_RADIUS = 6,

    SPIDER_MONKEY_DEFEND_DIST = 12,

    SPIDER_MONKEY_MATING_SEASON_BABYDELAY = total_day_time*1.5,
    SPIDER_MONKEY_MATING_SEASON_BABYDELAY_VARIANCE = 0.5*total_day_time,

    GRABBING_VINE_HEALTH = 100,
    GRABBING_VINE_DAMAGE = 10,
    GRABBING_VINE_ATTACK_PERIOD = 1,
    GRABBING_VINE_TARGET_DIST = 3,

    GRABBING_VINE_SPAWN_MIN = 6,
    GRABBING_VINE_SPAWN_MAX = 9,

    HANGING_VINE_SPAWN_MIN = 8,
    HANGING_VINE_SPAWN_MAX = 16,

    NETTLE_REGROW_TIME = total_day_time*3,
    NETTLE_MOISTURE_WET_THRESHOLD = 20,
    NETTLE_MOISTURE_DRY_THRESHOLD = 10,

    MOISTURE_SPRINKLER_PERCENT_INCREASE_PER_SPRAY = 0.5,
    SPRINKLER_MAX_FUEL_TIME = total_day_time,

    FLYTRAP_CHILD_HEALTH = 250,
    FLYTRAP_CHILD_DAMAGE = 15,
    FLYTRAP_CHILD_SPEED = 4,

    FLYTRAP_TEEN_HEALTH = 300,
    FLYTRAP_TEEN_DAMAGE = 20,
    FLYTRAP_TEEN_SPEED = 3.5,

    FLYTRAP_HEALTH = 350,
    FLYTRAP_DAMAGE = 25,
    FLYTRAP_SPEED = 3,

    FLYTRAP_TARGET_DIST = 8,
    FLYTRAP_KEEP_TARGET_DIST= 15,
    FLYTRAP_ATTACK_PERIOD = 3,

    ADULT_FLYTRAP_HEALTH = 400,
    ADULT_FLYTRAP_DAMAGE = 30,
    ADULT_FLYTRAP_ATTACK_PERIOD = 5,
    ADULT_FLYTRAP_ATTACK_DIST = 4,
    ADULT_FLYTRAP_STOPATTACK_DIST = 6,

    WALKING_STICK_DAMAGE = wilson_attack*.6,
    WALKING_STICK_SPEED_MULT = 1.3,
    WALKING_STICK_PERISHTIME = total_day_time*3,


}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
