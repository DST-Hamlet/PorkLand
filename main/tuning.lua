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
    --- Added from the dung mod
    DUNG_BEETLE_RUN_SPEED = 6,
    DUNG_BEETLE_WALK_SPEED = 3.5 	,
    DUNG_BEETLE_HEALTH = 60			,

    POG_ATTACK_RANGE = 3,
    POG_MELEE_RANGE = 2.5,
    POG_TARGET_DIST = 25,
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
    POG_LOYALTY_PER_ITEM = total_day_time * .1,
    POG_EAT_DELAY = 0.5,
    POG_SEE_FOOD = 30,
    
    PALMTREEGUARD_MELEE = 5,
    
    PALMTREEGUARD_HEALTH = 750,
    PALMTREEGUARD_DAMAGE = 150,
    PALMTREEGUARD_ATTACK_PERIOD = 3,
    PALMTREEGUARD_FLAMMABILITY = .333,
    
    PALMTREEGUARD_MIN_DAY = 3,
    PALMTREEGUARD_PERCENT_CHANCE = 1/75,
    PALMTREEGUARD_MAXSPAWNDIST = 30,
    
    PALMTREEGUARD_PINECONE_CHILL_CHANCE_CLOSE = .33,
    PALMTREEGUARD_PINECONE_CHILL_CHANCE_FAR = .15,
    PALMTREEGUARD_PINECONE_CHILL_CLOSE_RADIUS = 5,
    PALMTREEGUARD_PINECONE_CHILL_RADIUS = 16,
    PALMTREEGUARD_REAWAKEN_RADIUS = 20,
    
    PALMTREEGUARD_BURN_TIME = 10,
    PALMTREEGUARD_BURN_DAMAGE_PERCENT = 1/8,
    HAMLET_ADDONS_MOD = {enabled = true},
    HIPPO_DAMAGE = 50,
    HIPPO_HEALTH = 500,
    HIPPO_ATTACK_PERIOD = 2,
    HIPPO_WALK_SPEED = 5,
    HIPPO_RUN_SPEED = 6,
    HIPPO_TARGET_DIST = 12,
    ZEB_MATING_SEASON_BABYDELAY = total_day_time*1.5,  --used for hippo
	ZEB_MATING_SEASON_BABYDELAY_VARIANCE = 0.5*total_day_time,	 --used for hippo
    --lilly ponds
    POND_FROGS = 4,
	POND_REGEN_TIME = day_time/2,
	POND_SPAWN_TIME = day_time/4,
    MOSQUITO_MAX_SPAWN = 1,
	MOSQUITO_REGEN_TIME = day_time/2,
	FROG_POISON_MAX_SPAWN = 1,
	FROG_POISON_REGEN_TIME = day_time/2,
    LOTUS_REGROW_TIME = total_day_time*5,
    BILL_SPAWN_CHANCE = 0.2,
    BILL_TUMBLE_SPEED = 8,
	BILL_RUN_SPEED = 5,
	BILL_DAMAGE = wilson_attack * 0.5,
	BILL_HEALTH = 250,
	BILL_ATTACK_PERIOD = 3,
	BILL_TARGET_DIST = 50,
	BILL_AGGRO_DIST = 15,
	BILL_EAT_DELAY = 3.5,
	BILL_SPAWN_CHANCE = 0.2,

}

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
