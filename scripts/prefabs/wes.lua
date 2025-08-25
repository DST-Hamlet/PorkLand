local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/player_idles_wes.zip"),
    Asset("ANIM", "anim/player_mount_wes.zip"),
    Asset("ANIM", "anim/player_mime.zip"),
    Asset("ANIM", "anim/player_mime2.zip"),
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

    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * 0.75)
    inst.components.hunger:SetMax(TUNING.WILSON_HUNGER * 0.75)
    inst.components.sanity:SetMax(TUNING.WILSON_SANITY * 0.75)

    inst.components.combat.damagemultiplier = TUNING.WES_DAMAGE_MULT
    inst:AddComponent("efficientuser")
    inst.components.efficientuser:AddMultiplier(ACTIONS.ATTACK, 0.75, "wes")
end

return MakePlayerCharacter("wes", prefabs, assets, common_postinit, master_postinit, prefabs)
