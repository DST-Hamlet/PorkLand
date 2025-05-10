local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/player_idles_wes.zip"),
    Asset("ANIM", "anim/player_mount_wes.zip"),
    Asset("ANIM", "anim/player_mime.zip"),
}

local start_inv =
{
    default =
    {
        "balloons_empty",
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WES
end

local prefabs = FlattenTree(start_inv, true)

for k, v in pairs(start_inv) do
    for i1, v1 in ipairs(v) do
        if not table.contains(prefabs, v1) then
            table.insert(prefabs, v1)
        end
    end
end

local function common_postinit(inst)
    inst:AddTag("mime")
    inst:AddTag("balloonomancer")

    inst.AnimState:AddOverrideBuild("player_idles_wes")
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidlestate = "wes_funnyidle"

    inst.customidlestate = "wes_funnyidle"

    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * 0.75)
    inst.components.hunger:SetMax(TUNING.WILSON_HUNGER * 0.75)
    inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE * 1.25)
    inst.components.sanity:SetMax(TUNING.WILSON_SANITY * 0.75)
    inst.components.combat.damagemultiplier = TUNING.WES_DAMAGE_MULT

    if inst.components.houndedtarget == nil then
		inst:AddComponent("houndedtarget")
	end
	inst.components.houndedtarget.target_weight_mult:SetModifier(inst, TUNING.WES_HOUND_TARGET_MULT, "misfortune")
	inst.components.houndedtarget.hound_thief = true

    inst.components.playerlightningtarget:SetHitChance(TUNING.WES_LIGHTNING_TARGET_CHANCE)
end

return MakePlayerCharacter("wes", prefabs, assets, common_postinit, master_postinit, prefabs)
