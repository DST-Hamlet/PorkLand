local MakePlayerCharacter = require("prefabs/player_common")
local easing = require("easing")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/willow.fsb"),
    Asset("ANIM", "anim/player_idles_willow.zip"),
}

local prefabs =
{
}

local start_inv =
{
    default =
    {
        "lighter",
        "bernie_inactive",
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WILLOW
end

prefabs = FlattenTree({prefabs, start_inv}, true)

for k, v in pairs(start_inv) do
    for i1, v1 in ipairs(v) do
        if not table.contains(prefabs, v1) then
            table.insert(prefabs, v1)
        end
    end
end

local function customidleanimfn(inst)
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return item ~= nil and item.prefab == "bernie_inactive" and "idle_willow" or nil
end

local FIRE_TAGS = { "fire" }
local function sanityfn(inst)--, dt)
    local sanity_cap = TUNING.SANITYAURA_LARGE
    local sanity_per_ent = TUNING.SANITYAURA_TINY
    local delta = inst.components.temperature:IsFreezing() and -sanity_cap or 0
    local x, y, z = inst.Transform:GetWorldPosition()
    local max_rad = 10
    local ents = TheSim:FindEntities(x, y, z, max_rad, FIRE_TAGS)
    for i, v in ipairs(ents) do
        if v.components.burnable ~= nil and v.components.burnable:IsBurning() then
            local stack_size = v.components.stackable ~= nil and v.components.stackable.stacksize or 1
            local rad = v.components.burnable:GetLargestLightRadius() or 1
            local sz = stack_size * sanity_per_ent * math.min(max_rad, rad) / max_rad
            local distsq = inst:GetDistanceSqToInst(v) - 9
            -- shift the value so that a distance of 3 is the minimum
            delta = delta + sz / math.max(1, distsq)
            if delta > sanity_cap then
                delta = sanity_cap
                break
            end
        end
    end
    return delta
end

local function common_postinit(inst)
    inst:AddTag("pyromaniac")
    inst:AddTag("expertchef")
    inst:AddTag("bernieowner") -- this tag allows bernie to transform into BERNIE!
    inst:AddTag("heatresistant") --less overheat damage for widget
    inst:AddTag("fireimmune") -- 无法点燃
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidleanim = customidleanimfn

    inst.components.health.fire_damage_scale = TUNING.WILLOW_FIRE_DAMAGE

    inst.components.sanity.custom_rate_fn = sanityfn
    inst.components.sanity.rate_modifier = TUNING.WILLOW_SANITY_MODIFIER

    inst.components.temperature:SetFreezingHurtRate(TUNING.WILSON_HEALTH / TUNING.WILLOW_FREEZING_KILL_TIME)
    inst.components.temperature:SetOverheatHurtRate(TUNING.WILSON_HEALTH / TUNING.WILLOW_OVERHEAT_KILL_TIME)
end

return MakePlayerCharacter("willow", prefabs, assets, common_postinit, master_postinit)
