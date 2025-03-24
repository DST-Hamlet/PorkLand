local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/wickerbottom.fsb"),
    Asset("ANIM", "anim/player_knockedout_wickerbottom.zip"),
    Asset("ANIM", "anim/player_idles_wickerbottom.zip"),
}

local prefabs =
{
    "spellmasterybuff",
}

local start_inv =
{
    default =
    {
        "papyrus",
        "papyrus",
    },
}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WICKERBOTTOM
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
    return inst.AnimState:CompareSymbolBuilds("hand", "hand_wickerbottom") and "idle_wickerbottom" or nil
end

local function common_postinit(inst)
    inst:AddTag("insomniac")
    inst:AddTag("bookbuilder")
    --reader (from reader component) added to pristine state for optimization
    inst:AddTag("reader")
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidleanim = customidleanimfn

    inst:AddComponent("reader")

    if inst.components.eater ~= nil then
        inst.components.eater.stale_hunger = TUNING.WICKERBOTTOM_STALE_FOOD_HUNGER
        inst.components.eater.stale_health = TUNING.WICKERBOTTOM_STALE_FOOD_HEALTH
        inst.components.eater.spoiled_hunger = TUNING.WICKERBOTTOM_SPOILED_FOOD_HUNGER
        inst.components.eater.spoiled_health = TUNING.WICKERBOTTOM_SPOILED_FOOD_HEALTH
    end

    inst.components.sanity:SetMax(TUNING.WICKERBOTTOM_SANITY)

    inst.components.builder.science_bonus = 1
end

return MakePlayerCharacter("wickerbottom", prefabs, assets, common_postinit, master_postinit)
