local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/player_idles_wathgrithr.zip"),
    Asset("SOUND", "sound/wathgrithr.fsb"),
}

local prefabs =
{
    "wathgrithr_spirit",
    "wathgrithr_bloodlustbuff_other",
    "wathgrithr_bloodlustbuff_self",
}

local start_inv =
{
    default =
    {
        "spear_wathgrithr",
        "wathgrithrhat",
        "meat",
        "meat",
        "meat",
        "meat",
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WATHGRITHR
end

prefabs = FlattenTree({prefabs, start_inv}, true)

local small_scale = 0.5
local med_scale = 0.7
local large_scale = 1.1

local function spawnspirit(inst, x, y, z, scale)
    local fx = SpawnPrefab("wathgrithr_spirit")
    fx.Transform:SetPosition(x, y, z)
    fx.Transform:SetScale(scale, scale, scale)
end

local function IsValidVictim(victim)
    return victim ~= nil
        and victim.components.health ~= nil
        and victim.components.combat ~= nil
        and not ((victim:HasTag("prey") and not victim:HasTag("hostile"))
            or victim:HasAnyTag(NON_LIFEFORM_TARGET_TAGS) or victim:HasTag("companion"))
end

local function OnKilled(inst, data)
    local victim = data.victim

    if inst.components.health:IsDead() or not IsValidVictim(victim) then
        return
    end

    if not victim.components.health.nofadeout and (victim:HasTag("epic") or math.random() < 0.1) then
        local time = victim.components.health.destroytime or 2
        local x, y, z = victim.Transform:GetWorldPosition()
        local scale = (victim:HasTag("smallcreature") and small_scale)
            or (victim:HasTag("largecreature") and large_scale)
            or med_scale
        inst:DoTaskInTime(time, spawnspirit, x, y, z, scale)
    end
end

local BATTLEBORN_STORE_TIME = 3
local BATTLEBORN_DECAY_TIME = 5
local BATTLEBORN_TRIGGER_THRESHOLD = 1

local function Battleborn_OnAttack(inst, data)
    local victim = data.target

    if inst.components.health:IsDead() or not IsValidVictim(victim) then
        return
    end

    local total_health = victim.components.health:GetMaxWithPenalty()
    local damage = data.weapon ~= nil and data.weapon.components.weapon.damage or inst.components.combat.defaultdamage
    local percent = (damage <= 0 and 0)
        or (total_health <= 0 and math.huge)
        or damage / total_health
    --math and clamp does account for 0 and infinite cases
    local delta = math.clamp(victim.components.combat.defaultdamage * 0.25 * percent, 0.33, 2)

    --decay stored battleborn
    if inst.battleborn > 0 then
        local dt = GetTime() - inst.battleborn_time - BATTLEBORN_STORE_TIME
        if dt >= BATTLEBORN_DECAY_TIME then
            inst.battleborn = 0
        elseif dt > 0 then
            local k = dt / BATTLEBORN_DECAY_TIME
            inst.battleborn = Lerp(inst.battleborn, 0, k * k)
        end
    end

    --store new battleborn
    inst.battleborn = inst.battleborn + delta
    inst.battleborn_time = GetTime()

    --consume battleborn if enough has been stored
    if inst.battleborn > BATTLEBORN_TRIGGER_THRESHOLD then
        inst.components.health:DoDelta(inst.battleborn, false, "battleborn")
        inst.components.sanity:DoDelta(inst.battleborn)
        inst.battleborn = 0
    end
end

local function OnDeath(inst)
    inst.battleborn = 0
end

local function common_postinit(inst)
    inst:AddTag("valkyrie")
    inst:RemoveTag("usesvegetarianequipment") -- batnosehat

    inst.components.talker.mod_str_fn = Umlautify
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidleanim = "idle_wathgrithr"

    inst.talker_path_override = "dontstarve_DLC001/characters/"

    if inst.components.eater ~= nil then
        inst.components.eater:SetDiet({FOODGROUP.OMNI}, {FOODTYPE.MEAT, FOODTYPE.GOODIES})
    end

    inst.components.health:SetMaxHealth(TUNING.WATHGRITHR_HEALTH)
    inst.components.hunger:SetMax(TUNING.WATHGRITHR_HUNGER)
    inst.components.sanity:SetMax(TUNING.WATHGRITHR_SANITY)

    inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT
    inst.components.health:SetAbsorptionAmount(TUNING.WATHGRITHR_ABSORPTION)

    inst:ListenForEvent("killed", OnKilled)
    inst:ListenForEvent("onattackother", Battleborn_OnAttack)

    inst:ListenForEvent("death", OnDeath)

    inst.battleborn = 0
    inst.battleborn_time = 0
end

return MakePlayerCharacter("wathgrithr", prefabs, assets, common_postinit, master_postinit)
