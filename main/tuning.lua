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

    APORKALYPSE_FIESTA_TIME = 5 * total_day_time,
    APORKALYPSE_NEAR_TIME = 7 * total_day_time,
    APORKALYPSE_PERIOD_LENGTH = 60 * total_day_time,

    PERISH_APORKALYPSE_MULT = 1.5,
    PERISH_NORMAL_MULT = 1,

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

    FLIPPABLE_ROCK_REPOPULATE_TIME = total_day_time * 8,
    FLIPPABLE_ROCK_REPOPULATE_VARIANCE = total_day_time * 2,

    CLAWPALMTREE_GROW_TIME = {
        {base = 8 * day_time, random = 0.5 * day_time},  -- tall to short
        {base = 12 * day_time, random = 5 * day_time},   -- short to normal
        {base = 12 * day_time, random = 5 * day_time},   -- normal to tall
    },

    TREE_CREAK_RANGE = 16,

    JUNGLETREE_CHOPS_SHORT = 5,
    JUNGLETREE_CHOPS_NORMAL = 10,
    JUNGLETREE_CHOPS_TALL = 15,
    JUNGLETREE_WINDBLOWN_SPEED = 0.2,
    JUNGLETREE_WINDBLOWN_FALL_CHANCE = 0.01,
    JUNGLETREESEED_GROWTIME = {base = 4.5 * day_time, random = 0.75 * day_time},
    JUNGLETREE_GROW_TIME ={
        {base = 4.5 * day_time, random = 0.5 * day_time}, -- tall to short
        {base = 8 * day_time, random = 5 * day_time}, -- short to normal
        {base = 8 * day_time, random = 5 * day_time}, -- normal to tall
    },

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
    SNAKE_JUNGLETREE_AMOUNT_NORMAL = 1, -- num of times to try and spawn a snake from a normal tree
    SNAKE_JUNGLETREE_AMOUNT_SHORT = 1, -- num of times to try and spawn a snake from a small tree
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

    PIGHOUSE_CITY_RESPAWNTIME = total_day_time*3,
    GUARDTOWER_CITY_RESPAWNTIME = total_day_time*3,

    CITY_PIG_GUARD_TARGET_DIST = 20,
    CITY_PIG_GUARD_KEEP_TARGET_DIST = 32,

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

    TRAWLNET_MAX_ITEMS = 9,
    TRAWLNET_ITEM_DISTANCE = 100, --How far you have to travel to get another item
    TRAWLING_SPEED_MULT = 0.25, --This is actually speed reduction (speed = 1 - speed_mult)
    TRAWL_SINK_TIME = seg_time * 3,

    SUNKENPREFAB_REMOVE_TIME = total_day_time * 2,

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
    ADULT_FLYTRAP_ATTACK_PERIOD = 1,
    ADULT_FLYTRAP_ATTACK_DIST = 4,

    WALKING_STICK_DAMAGE = wilson_attack * 0.6,
    WALKING_STICK_SPEED_MULT = 1.3,
    WALKING_STICK_PERISHTIME = total_day_time * 3,

    PUGALISK_RESPAWN = total_day_time * 15,
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
    SAND_WINDBLOWN_SPEED = 0.2,
    SAND_WINDBLOWN_FALL_CHANCE = 0.1,

    EVERGREEN_WINDBLOWN_SPEED = 0.2,
    EVERGREEN_WINDBLOWN_FALL_CHANCE = 0.01,
    DECIDUOUS_WINDBLOWN_SPEED = 0.2,
    DECIDUOUS_WINDBLOWN_FALL_CHANCE = 0.01,

    FIREPIT_WIND_RATE = 10,

    BALLPEIN_HAMMER_DAMAGE = wilson_attack*0.3,
    BALLPEIN_HAMMER_USES = 10,

    VAMPIREBAT_HEALTH = 130,
    VAMPIREBAT_DAMAGE = 25,
    VAMPIREBAT_ATTACK_PERIOD = 1.8,
    VAMPIREBAT_WALK_SPEED = 7.2, -- 8 * 0.9?

    SCORPION_HEALTH = 200,
    SCORPION_DAMAGE = 20,
    SCORPION_ATTACK_PERIOD = 3,
    SSCORPION_WAKE_RADIUS = 4,
    SCORPION_FLAMMABILITY = 0.33,
    SCORPION_SUMMON_WARRIORS_RADIUS = 12,
    SCORPION_EAT_DELAY = 1.5,
    SCORPION_ATTACK_RANGE = 3,
    SCORPION_STING_RANGE = 2,
    SCORPION_WALK_SPEED = 3,
    SCORPION_RUN_SPEED = 5,

    RUINS_ENTRANCE_VINES_HACKS = 4,
    RUINS_DOOR_VINES_HACKS = 2,
    ROCKS_MINE_GIANT = 10,
    PIG_RUINS_DART_DAMAGE = wilson_attack,
    SPEAR_TRAP_HEALTH = 100,
    SPEAR_TRAP_DAMNAGE = wilson_attack,

    HONEY_LANTERN_MINE = 6,

    ROOM_FINDENTITIES_RADIUS = 30, -- NOTE: this value is determined by TUNING.ROOM_LARGE_WIDTH and TUNING.ROOM_LARGE_DEPTH

    PL_MANUAL_LIGHT_OFFSET = {
        -- {[K: prefab]: {height, z_off}}
        DEFAULT = {2, .5},
    },

    -- temp use, read only
    -- TODO: may change to mod config or keep as constant
    -- see interiorspawner.lua
    INTERIOR_DESTRUCTION_BEHAVIOR = {
        DEFAULT = "REMOVE",
        PLAYER = "TELEPORT_TO_EXTERIOR",
        CREATURE = "KILL",
        EPIC_CREATURE = "TELEPORT_TO_EXTERIOR",
        ITEMS = "REMOVE", -- except for irreplaceable
        STRUCTURE = "DESTROY",
    },

    -- temp use
    -- TODO: remove in prod
    DECO_RUINS_BEAM_WORK = 6,

    MAGNIFYING_GLASS_DAMAGE = wilson_attack * 0.125,
    MAGNIFYING_GLASS_USES = 10,
    MAGNIFYING_GLASS_LIGHT = 0.5,

    ROBOT_TARGET_DIST = 15,
    ROBOT_RIBS_DAMAGE = wilson_attack,
    ROBOT_RIBS_HEALTH = 1000,
    ROBOT_LEG_DAMAGE = wilson_attack * 2,
    ROBOT_LOCOMOTE_SPEED = {
        RIBS = 2,
        CLAW = 3,
        LEG = 4,
        HEAD = 4,
    },
    ROBOT_DISCHARGE_TIME = 90,

    LASER_DAMAGE = 20,

    ANCIENT_HULK_DAMAGE = 200,
    ANCIENT_HULK_HEALTH = 3000,
    ANCIENT_HULK_MINE_DAMAGE = 100,
    ANCIENT_HULK_MELEE_RANGE = 5.5,
    ANCIENT_HULK_ATTACK_RANGE = 5.5,
    ANCIENT_HULK_BARRIER_CD = 10,
    ANCIENT_HULK_SPIN_CD = 10,
    ANCIENT_HULK_TELEPORT_CD = 5,

    IRON_LORD_DAMAGE = wilson_attack * 2,
    IRON_LORD_TIME = 3 * 60,

    INFUSED_IRON_PERISHTIME = total_day_time * 2,

    SNEAK_SIGHTDISTANCE = 8,

    POG_ATTACK_RANGE = 3,
    POG_MELEE_RANGE = 2.5,
    POG_WALK_SPEED = 2,
    POG_RUN_SPEED = 4.5,
    POG_DAMAGE = 25,
    POG_HEALTH = 150,
    POG_ATTACK_PERIOD = 2,

    MIN_POGNAP_INTERVAL = 30,
    MAX_POGNAP_INTERVAL = 120,
    MIN_POGNAP_LENGTH = 20,
    MAX_POGNAP_LENGTH = 40,

    POG_LOYALTY_MAXTIME = total_day_time,
    POG_LOYALTY_PER_ITEM = total_day_time * 0.1,
    POG_EAT_DELAY = 0.5,

    ANCIENT_HERALD_HEALTH = 2000,
    ANCIENT_HERALD_DAMAGE = 50,
    ANCIENT_HERALD_SUMMON_COOLDOWN = 15,

    ARMORVORTEX = wilson_health*3,
    ARMORVORTEX_ABSORPTION = 1,
    ARMORVORTEX_DMG_AS_SANITY = 0.20,
    ARMORVORTEX_REFUEL_PERCENT = 0.10,
    ARMOTVORTEX_SHADOW_LEVEL = 3,

    VOLCANO_FIRERAIN_WARNING = 2,
    VOLCANO_FIRERAIN_RADIUS = 20,
    VOLCANO_FIRERAIN_DAMAGE = 300,
    VOLCANO_FIRERAIN_LAVA_CHANCE = 0.5,
    VOLCANO_DRAGOONEGG_CHANCE = 0.25,

    LAVAPOOL_FUEL_MAX = (night_time+dusk_time),
    LAVAPOOL_FUEL_START = (night_time+dusk_time)*.75,

    SPIDER_MONKEY_SPEED_AGITATED = 5.5,  --4
    SPIDER_MONKEY_SPEED = 5.5, --2
    SPIDER_MONKEY_HEALTH = 550,

    SPIDER_MONKEY_DAMAGE = 60,
    SPIDER_MONKEY_ATTACK_PERIOD = 2,
    SPIDER_MONKEY_ATTACK_RANGE = 4,
    SPIDER_MONKEY_HIT_RANGE = 3,
    SPIDER_MONKEY_MELEE_RANGE = 4,

    SPIDER_MONKEY_MATING_SEASON_BABYDELAY = total_day_time * 1.5,
    SPIDER_MONKEY_MATING_SEASON_BABYDELAY_VARIANCE = total_day_time * 0.5,

    BRAMBLE_THORN_DAMAGE = 3,
    BRAMBLE_THORN_HEALTH = 40,
    BRAMBLE_CORE_HEALTH = 200,

    BUGREPELLENT_USES = 20,
    CORK_BAT_USES = 20,
    CORK_BAT_DAMAGE = wilson_attack * 1.5,

    BLUNDERBUSS_ATTACK_RANGE = 9,
    BLUNDERBUSS_HIT_RANGE = 11,

    ARMOR_WEEVOLE_DURABILITY = wilson_health*6,
    ARMOR_WEEVOLE_ABSORPTION = .65,

    CANDLEHAT_LIGHTTIME = night_time*2,

    ANTMASKHAT_PERISHTIME = total_day_time*10,
    ANTSUIT_PERISHTIME = total_day_time*10,
    BATHAT_PERISHTIME = total_day_time*2,
    ARMOR_SNAKESKIN_PERISHTIME = total_day_time*8, --was 10
    SNAKESKINHAT_PERISHTIME = total_day_time*8, --was 10
    BANDITHAT_PERISHTIME = total_day_time*1,
    THUNDERHAT_PERISHTIME = total_day_time*4,
    THUNDERHAT_USAGE_PER_LIGHTINING_STRIKE = 0.05, -- Percent
    ARMOR_KNIGHT = wilson_health*8,
    ARMOR_KNIGHT_ABSORPTION = .85,
    PITHHAT_PERISHTIME = total_day_time*8,
    GASMASK_PERISHTIME = total_day_time*3,

    PIG_BANDIT_DAMAGE = 33,
    PIG_BANDIT_HEALTH = 250,
    PIG_BANDIT_ATTACK_PERIOD = 3,
    PIG_BANDIT_LOYALTY_MAXTIME = 2.5*total_day_time,
    PIG_BANDIT_LOYALTY_PER_HUNGER = total_day_time/25,
    PIG_BANDIT_MIN_POOP_PERIOD = seg_time * .5,
    PIG_BANDIT_RUN_SPEED = 7,
    PIG_BANDIT_WALK_SPEED = 3,
    PIG_BANDIT_ENABLED = true,
    PIG_BANDIT_RESPAWN_TIME = 10,
    PIG_BANDIT_DEATH_RESPAWN_TIME = 30 * 16 * 1.5, -- 9 minutes

    NETTLE_REGROW_TIME = total_day_time * 3,
    NETTLE_MOISTURE_WET_THRESHOLD = 20,
    NETTLE_MOISTURE_DRY_THRESHOLD = 10,
    SPRINKLER_MAX_FUEL_TIME = total_day_time,
    MOISTURE_SPRINKLER_PERCENT_INCREASE_PER_SPRAY = 0.5,

    GNATMOUND_REGEN_TIME = seg_time * 4,
    GNATMOUND_RELEASE_TIME = seg_time,
    GNATMOUND_MAX_WORK = 6,
    GNATMOUND_MAX_CHILDREN = 1,

    GNAT_WALK_SPEED = 2,
    GNAT_RUN_SPEED = 7,

    THUNDERBIRDNEST_RELEASE_TIME = 1,
    THUNDERBIRDNEST_REGEN_TIME = total_day_time * 5,
    THUNDERBIRDNEST_MAXCHILDREN = 1,
    THUNDERBIRDNEST_REGROW_TIME = total_day_time * 3,

    THUNDERBIRD_ENABLED = true,
    THUNDERBIRD_RUN_SPEED = 5.5,
    THUNDERBIRD_WALK_SPEED = 2,
    THUNDERBIRD_HEALTH = 50,

    -- Note: in DS the following two values are 1.5 and 2.0 by default but they get overriden manually in the porkland prefab -Half
    RAINFOREST_CANOPY_ROTATION_SPEED = 5,           -- 5 seconds per rotation
    RAINFOREST_CANOPY_TRANSLATION_SPEED = 5,        -- 5 seconds per translation
    RAINFOREST_CANOPY_MAX_ROTATION = 20,            -- max 20 degrees from base rotation
    RAINFOREST_CANOPY_MAX_TRANSLATION = 1,          -- max 1 world unit from base position
    RAINFOREST_CANOPY_SCALE = 6,                    -- scale for the texture
    RAINFOREST_CANOPY_MIN_STRENGTH = 0.2,           -- blend min strength - modulated with avg ambient
    RAINFOREST_CANOPY_MAX_STRENGTH = 0.7,           -- blend max strength - modulated with avg ambient

    ROBIN_HATCH_TIME = total_day_time * 3,

    PIGGHOST_REGEN_TIME = total_day_time / 2,
    PIGGHOST_RELEASE_TIME = 0,
    PIGGHOST_MAXCHILDREN = 3,

    OX_FLUTE_USES = 5,

    SANITY_PLAYERHOUSE_GAIN = 100 / (day_time * 32),

    ROC_SPEED = 20,
    ROC_SPEED_LAND = 6,
    ROC_SHADOWRANGE = 8,
    ROC_ENABLED = true,

    ROC_HEAD_SPEED = 10,
    ROC_TAIL_SPEED = 8,

    CUTLASS_DAMAGE = wilson_attack * 2,
    CUTLASS_USES = 150,

    GIANT_GRUB_WALK_SPEED = 2,
    GIANT_GRUB_DAMAGE = 44,
    GIANT_GRUB_HEALTH = 600,
    GIANT_GRUB_ATTACK_PERIOD = 3,
    GIANT_GRUB_ATTACK_RANGE = 3,
    GIANT_GRUB_TARGET_DIST = 25,

    ANTMAN_DAMAGE = wilson_attack * 2/3,
    ANTMAN_HEALTH = 250,
    ANTMAN_ATTACK_PERIOD = 3,
    ANTMAN_TARGET_DIST = 16,
    ANTMAN_LOYALTY_MAXTIME = 2.5 * total_day_time,
    ANTMAN_LOYALTY_PER_HUNGER = total_day_time / 25,
    ANTMAN_MIN_POOP_PERIOD = seg_time * 0.5,

    ANTMAN_RUN_SPEED = 5,
    ANTMAN_WALK_SPEED = 3,

    ANTMAN_MIN = 3,
    ANTMAN_MAX = 4,
    ANTMAN_REGEN_TIME = seg_time * 4,
    ANTMAN_RELEASE_TIME = seg_time,

    ANTMAN_ATTACK_ON_SIGHT_DIST = 4,

    ANTMAN_WARRIOR_DAMAGE = wilson_attack * 1.25,
    ANTMAN_WARRIOR_HEALTH = 300,
    ANTMAN_WARRIOR_ATTACK_PERIOD = 3,
    ANTMAN_WARRIOR_TARGET_DIST = 16,

    ANTMAN_WARRIOR_RUN_SPEED = 7,
    ANTMAN_WARRIOR_WALK_SPEED = 3.5,

    ANTMAN_WARRIOR_REGEN_TIME = seg_time,
    ANTMAN_WARRIOR_RELEASE_TIME = seg_time,

    ANTMAN_WARRIOR_ATTACK_ON_SIGHT_DIST = 8,

    ANTQUEEN_HEALTH = 3500,

    GIANT_GRUB_RESPAWN_TIME = total_day_time,
    GIANT_GRUB_ENABLED = true,

    CHARACTER_MAX_STUN_LOCKS = 5,
    BOSS_HITREACT_COOLDOWN = 1,
    BOSS_MAX_STUN_LOCKS = 1,

    COCONADE_FUSE = 5,
    COCONADE_DAMAGE = 250,
    COCONADE_EXPLOSIONRANGE = 6,
    COCONADE_BUILDINGDAMAGE = 10,

    BIRDWHISLE_USES = 5,

    FENCE_FURNITURE_ROTATION = 180,

    SANITY_HOUSE = 0,
    SANITY_PLAYERHOUSE = 100/(seg_time*32),

    ENTITY_WAKE_DIST = 64,
    ENTITY_SLEEP_DIST = 64 * 1.2,

    ANIMSHADE_MIN_STRENGTH = 0.1429,           -- blend min strength - modulated with avg ambient
    ANIMSHADE_MAX_STRENGTH = 0.5,           -- blend max strength - modulated with avg ambient

    WHEELER_HEALTH = 100,
    WHEELER_HUNGER = 150,
    WHEELER_SANITY = 200,
    WHEELER_DODGE_COOLDOWN = 1.5,
    DODGE_TIMEOUT = 0.25,

    TRUSTY_SHOOTER_DAMAGE_HIGH = 60,
    TRUSTY_SHOOTER_DAMAGE_MEDIUM = 45,
    TRUSTY_SHOOTER_DAMAGE_LOW = wilson_attack,

    TRUSTY_SHOOTER_ATTACK_RANGE_HIGH = 11,
    TRUSTY_SHOOTER_ATTACK_RANGE_MEDIUM = 9,
    TRUSTY_SHOOTER_ATTACK_RANGE_LOW = 7,

    TRUSTY_SHOOTER_HIT_RANGE_HIGH = 13,
    TRUSTY_SHOOTER_HIT_RANGE_MEDIUM = 11,
    TRUSTY_SHOOTER_HIT_RANGE_LOW = 9,

    TRUSTY_SHOOTER_TIERS =
    {
        AMMO_HIGH = {
            "gears",
            "purplegem",
            "bluegem",
            "redgem",
            "orangegem",
            "yellowgem",
            "greengem",
            "oinc10",
            "oinc100",
            "nightmarefuel",
            "gunpowder",
            "relic_1",
            "relic_2",
            "relic_3",
            "relic_4",
            "relic_5",
        },

        AMMO_LOW =
        {
            "feather_crow",
            "feather_robin",
            "feather_robin_winter",
            "feather_thunder",
            "ash",
            "beardhair",
            "beefalowool",
            "butterflywings",
            "clippings",
            "cutgrass",
            "cutreeds",
            "foliage",
            "palmleaf",
            "papyrus",
            "petals",
            "petals_evil",
            "pigskin",
            "silk",
            "seaweed",
        },
    },
}


--修改原版数值，不知道是否应该放这里

--使得黑暗范围更符合视觉效果
TUNING.DARK_CUTOFF = 0.02

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

TUNING.ROOM_TINY_WIDTH   = 15
TUNING.ROOM_TINY_DEPTH   = 10
TUNING.ROOM_SMALL_WIDTH  = 18
TUNING.ROOM_SMALL_DEPTH  = 12
TUNING.ROOM_MEDIUM_WIDTH = 24
TUNING.ROOM_MEDIUM_DEPTH = 16
TUNING.ROOM_LARGE_WIDTH  = 26
TUNING.ROOM_LARGE_DEPTH  = 18

local TechTree = require("techtree")

TUNING.PROTOTYPER_TREES.HOGUSPORKUSATOR = TechTree.Create({
    MAGIC = 2,
})
TUNING.PROTOTYPER_TREES.CITY = TechTree.Create({
    CITY = 2,
})

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end

TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WHEELER = {
    "trusty_shooter",
    -- TODO: Find a way to make this thing lesser laggy and then enable it
    -- "wheeler_tracker",
}
