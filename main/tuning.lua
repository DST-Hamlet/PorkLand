GLOBAL.setfenv(1, GLOBAL)

local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME

local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH

local tuning = {
    MAPWRAPPER_WARN_RANGE = 14,

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
    RABID_BEETLE_ATTACK_RANGE = 2,
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

    -- standard poison vars
    VENOM_GLAND_DAMAGE = 75,
    VENOM_GLAND_MIN_HEALTH = 5,

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
    PIKO_ENABLED = true,

    CAFFEINE_FOOD_BONUS_SPEED = 11/6, -- player base speed plus this, 6 is normal walk speed
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

    PAN_DAMAGE = wilson_attack*.8,
    PAN_USES = 30,

    PANGOLDEN_HEALTH = 500,
    PANGOLDEN_BALL_DEFENCE = 0.75,
    PANGOLDEN_WALK_SPEED = 2.5,
    PANGOLDEN_RUN_SPEED = 8,

    DUNGBEETLE_RUN_SPEED = 6,
    DUNGBEETLE_WALK_SPEED = 3.5,
    DUNGBEETLE_HEALTH = 60,

    DUNGBEETLE_MAXCHILDREN = 1,
    DUNGBEETLE_REGEN_TIME = seg_time * 4,
    DUNGBEETLE_RELEASE_TIME = seg_time,
    DUNGBEETLE_ENABLED = true,

    GRABBING_VINE_HEALTH = 100,
    GRABBING_VINE_DAMAGE = 10,
    GRABBING_VINE_ATTACK_RANGE = 3,
    GRABBING_VINE_HIT_RANGE = 4,
    GRABBING_VINE_ATTACK_PERIOD = 1,
    GRABBING_VINE_TARGET_DIST = 3,

    GRABBING_VINE_SPAWN_MIN = 6,
    GRABBING_VINE_SPAWN_MAX = 9,
    HANGING_VINE_SPAWN_MIN = 8,
    HANGING_VINE_SPAWN_MAX = 16,
    HANGING_VINE_ENABLED = true,

    VINE_REGEN_TIME_MIN = total_day_time * 2,
    VINE_REGEN_TIME_MAX = total_day_time * 3,

    SNAKE_SPEED = 3,
    SNAKE_TARGET_DIST = 8,
    SNAKE_KEEP_TARGET_DIST= 15,
    SNAKE_HEALTH = 100,
    SNAKE_DAMAGE = 10,
    SNAKE_ATTACK_PERIOD = 3,
    SNAKE_POISON_CHANCE = 0.25,
    SNAKE_POISON_START_DAY = 3, -- the day that poison snakes have a chance to show up
    SNAKEDEN_REGEN_TIME = 3 * seg_time,
    SNAKEDEN_RELEASE_TIME = 5,
    SNAKE_JUNGLETREE_CHANCE = 0.5, -- chance of a normal snake
    SNAKE_JUNGLETREE_POISON_CHANCE = 0.25, -- chance of a poison snake
    SNAKE_JUNGLETREE_AMOUNT_TALL = 2, -- num of times to try and spawn a snake from a tall tree
    SNAKE_JUNGLETREE_AMOUNT_MED = 1, -- num of times to try and spawn a snake from a normal tree
    SNAKE_JUNGLETREE_AMOUNT_SMALL = 1, -- num of times to try and spawn a snake from a small tree
    SNAKEDEN_MAX_SNAKES = 3,
    SNAKEDEN_CHECK_DIST = 20,
    SNAKEDEN_TRAP_DIST = 2,

    HIPPO_DAMAGE = 50,
    HIPPO_HEALTH = 500,
    HIPPO_ATTACK_PERIOD = 2,
    HIPPO_WALK_SPEED = 5,
    HIPPO_RUN_SPEED = 6,
    HIPPO_TARGET_DIST = 12,
    HIPPO_MATING_SEASON_BABYDELAY = total_day_time * 3,
    HIPPO_MATING_SEASON_BABYDELAY_VARIANCE = total_day_time * 1,
    HIPPO_ENABLED = true,

    BILL_TUMBLE_SPEED = 8,
    BILL_RUN_SPEED = 5,
    BILL_DAMAGE = wilson_attack * 0.5,
    BILL_HEALTH = 250,
    BILL_ATTACK_PERIOD = 3,
    BILL_TARGET_DIST = 50,
    BILL_AGGRO_DIST = 15,
    BILL_EAT_DELAY = 3.5,
    BILL_SPAWN_CHANCE = 0.2,

    LOTUS_REGROW_TIME = total_day_time * 5,

    MOSQUITO_LILYPAD_MAX_SPAWN = 1,
    MOSQUITO_LILYPAD_REGEN_TIME = day_time / 2,
    MOSQUITO_LILYPAD_RELEASE_TIME = 20,
    MOSQUITO_LILYPAD_ENABLED = true,

    FROG_POISON_LILYPAD_MAX_SPAWN = 1,
    FROG_POISON_LILYPAD_REGEN_TIME = day_time / 2,
    FROG_POISON_LILYPAD_RELEASE_TIME = 20,
    FROG_POISON_LILYPAD_ENABLED = true,

    WAVE_HIT_MOISTURE = 15,
    WAVE_HIT_DAMAGE = 5,
    ROGUEWAVE_HIT_MOISTURE = 25,
    ROGUEWAVE_HIT_DAMAGE = 10,
    ROGUEWAVE_SPEED_MULTIPLIER = 3,
    WAVE_BOOST_ANGLE_THRESHOLD = 90,
    WAVEBOOST = 5,

    BOAT_HITFX_THRESHOLD = .08,  -- percent of health you need to lose to show the fx

    BOAT_TORCH_LIGHTTIME = night_time * 1.75,

    BOAT_REPAIR_KIT_HEALING = 100,
    BOAT_REPAIR_KIT_USES = 3,

    BOAT_LOGRAFT_HEALTH = 150,
    BOAT_LOGRAFT_PERISHTIME = total_day_time * 2,
    BOAT_LOGRAFT_LEAKING_HEALTH = 40,
    BOAT_LOGRAFT_SPEED = -2,

    BOAT_RAFT_HEALTH = 150,
    BOAT_RAFT_PERISHTIME = total_day_time * 2,
    BOAT_RAFT_LEAKING_HEALTH = 40,
    BOAT_RAFT_SPEED = -1,

    BOAT_ROW_HEALTH = 250,
    BOAT_ROW_PERISHTIME = total_day_time * 3,
    BOAT_ROW_LEAKING_HEALTH = 40,
    BOAT_ROW_SPEED = 0,

    BOAT_CARGO_HEALTH = 300,
    BOAT_CARGO_PERISHTIME = total_day_time * 3,
    BOAT_CARGO_LEAKING_HEALTH = 40,
    BOAT_CARGO_SPEED = -1,

    BOAT_CORK_HEALTH = 80,
    BOAT_CORK_PERISHTIME = total_day_time * 3,
    BOAT_CORK_LEAKING_HEALTH = 30,
    BOAT_CORK_SPEED = -2,

    SAIL_SNAKESKIN_SPEED_MULT = 0.25,
    SAIL_SNAKESKIN_ACCEL_MULT = 0.25,
    SAIL_SNAKESKIN_PERISH_TIME = total_day_time * 4,

    MANDRAKEMAN_SPAWN_TIME = total_day_time,
    MANDRAKEMAN_ENABLED = true,

    MANDRAKEMAN_DAMAGE = 40,
    MANDRAKEMAN_HEALTH = 200,
    MANDRAKEMAN_ATTACK_PERIOD = 2,
    MANDRAKEMAN_RUN_SPEED = 6,
    MANDRAKEMAN_WALK_SPEED = 3,
    MANDRAKEMAN_PANIC_THRESH = .333,
    MANDRAKEMAN_HEALTH_REGEN_PERIOD = 5,
    MANDRAKEMAN_HEALTH_REGEN_AMOUNT = (200/120) * 5,
    MANDRAKEMAN_SEE_MANDRAKE_DIST = 8,

    FLYTRAP_CHILD_HEALTH = 250,
    FLYTRAP_CHILD_DAMAGE = 15,
    FLYTRAP_CHILD_SPEED = 4,

    FLYTRAP_TEEN_HEALTH = 300,
    FLYTRAP_TEEN_DAMAGE = 20,
    FLYTRAP_TEEN_SPEED = 3.5,

    FLYTRAP_HEALTH = 350,
    FLYTRAP_DAMAGE = 25,
    FLYTRAP_SPEED = 3,
    FLYTRAP_ATTACK_PERIOD = 3,

    ADULT_FLYTRAP_HEALTH = 400,
    ADULT_FLYTRAP_DAMAGE = 30,
    ADULT_FLYTRAP_ATTACK_PERIOD = 5,
    ADULT_FLYTRAP_ATTACK_DIST = 4,

    WALKING_STICK_DAMAGE = wilson_attack * 0.6,
    WALKING_STICK_SPEED_MULT = 1.3,
    WALKING_STICK_PERISHTIME = total_day_time * 3,

    PUGALISK_HEALTH = 3000,
    PUGALISK_ATTACK_PERIOD = 3,
    PUGALISK_MELEE_RANGE = 6,
    PUGALISK_DAMAGE = 200,
    PUGALISK_TARGET_DIST = 40,
    PUGALISK_TAIL_TARGET_DIST = 6,
    PUGALISK_ENABLED = true,

    PUGALISK_RUINS_PILLAR_WORK = 3,

    WIND_PUSH_MULTIPLIER = 0.4,

    WIND_GUSTSPEED_PEAK_MIN = 0.9,
    WIND_GUSTSPEED_PEAK_MAX = 1.0,
    WIND_GUSTRAMPUP_TIME = 0.5,
    WIND_GUSTRAMPDOWN_TIME = 32.0/30.0, -- Hacky, exact time of windshirl anim
    WIND_GUSTLENGTH_MIN = 7, -- measured in seconds
    WIND_GUSTLENGTH_MAX = 10,
    WIND_GUSTDELAY_MIN = 15, -- time between gusts
    WIND_GUSTDELAY_MAX = 16,
    WIND_GUSTDELAY_MIN_LUSH = 15,
    WIND_GUSTDELAY_MAX_LUSH = 720,

    HURRICANE_PERCENT_WIND_START = 0.01,
    HURRICANE_PERCENT_WIND_END = 0.8,

    GRASS_WINDBLOWN_SPEED = 0.2,
    GRASS_WINDBLOWN_FALL_CHANCE = 0.01,
    SAPLING_WINDBLOWN_SPEED = 0.2,
    SAPLING_WINDBLOWN_FALL_CHANCE = 0.1,
    REEDS_WINDBLOWN_SPEED = 0.2,
    REEDS_WINDBLOWN_FALL_CHANCE = 0.1,
    BERRYBUSH_WINDBLOWN_SPEED = 0.2,
    BERRYBUSH_WINDBLOWN_FALL_CHANCE = 0.01,
    FLOWER_WINDBLOWN_SPEED = 0.2,
    FLOWER_WINDBLOWN_FALL_CHANCE = 0.1,
    PIGHOUSE_WINDBLOWN_SPEED = 0.2,
    PIGHOUSE_WINDBLOWN_FALL_CHANCE = 0.1,
    WALLHAY_WINDBLOWN_SPEED = 0.2,
    WALLHAY_WINDBLOWN_DAMAGE_CHANCE = 0.9,
    WALLHAY_WINDBLOWN_DAMAGE = wilson_attack,
    WALLWOOD_WINDBLOWN_SPEED = 0.2,
    WALLWOOD_WINDBLOWN_DAMAGE_CHANCE = 0.9,
    WALLWOOD_WINDBLOWN_DAMAGE = 0.5*wilson_attack,

    EVERGREEN_WINDBLOWN_SPEED = 0.2,
    EVERGREEN_WINDBLOWN_FALL_CHANCE = 0.01,
    DECIDUOUS_WINDBLOWN_SPEED = 0.2,
    DECIDUOUS_WINDBLOWN_FALL_CHANCE = 0.01,

    FIREPIT_WIND_RATE = 10,
}


--修改原版数值，不知道是否应该放这里
--用于去除小地图陆地边缘的海洋渐变
--待做：让这些值只在猪镇世界生效
TUNING.OCEAN_MINIMAP_SHADER.EDGE_COLOR0 = { 0, 0, 0 }
TUNING.OCEAN_MINIMAP_SHADER.EDGE_PARAMS0 =
{
    THRESHOLD = 0,
    HALF_THRESHOLD_RANGE = 0,
}

TUNING.OCEAN_MINIMAP_SHADER.EDGE_COLOR1 = { 0, 0, 0 }
TUNING.OCEAN_MINIMAP_SHADER.EDGE_PARAMS1 =
{
    THRESHOLD = 0,
    HALF_THRESHOLD_RANGE = 0,
}

TUNING.OCEAN_MINIMAP_SHADER.EDGE_SHADOW_COLOR = { 0, 0, 0 }
TUNING.OCEAN_MINIMAP_SHADER.EDGE_SHADOW_PARAMS =
{
    THRESHOLD = 0,
    HALF_THRESHOLD_RANGE = 0,
    UV_OFFSET_X = 0,
    UV_OFFSET_Y = 0,
}

TUNING.OCEAN_MINIMAP_SHADER.EDGE_FADE_PARAMS =
{
    THRESHOLD = 0,
    HALF_THRESHOLD_RANGE = 0,
    MASK_INSET = 0,
}

TUNING.OCEAN_MINIMAP_SHADER.EDGE_NOISE_PARAMS =
{
    UV_SCALE = 0,
}

TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT = 0.4

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
