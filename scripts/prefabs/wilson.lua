local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/beard.zip"),
    Asset("ANIM", "anim/player_idles_wilson.zip"),
}

local prefabs =
{
    "beardhair",
}

local start_inv =
{
    default =
    {
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WILSON
end

prefabs = FlattenTree({prefabs, start_inv}, true)

local function common_postinit(inst)
    --bearded (from beard component) added to pristine state for optimization
    inst:AddTag("bearded")
end

local function OnResetBeard(inst)
    inst.AnimState:ClearOverrideSymbol("beard")
end

--tune the beard economy...
local BEARD_DAYS = {4, 8, 16}
local BEARD_BITS = {1, 3, 9}

local function OnGrowShortBeard(inst, skin_name)
    if skin_name == nil then
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
    else
        inst.AnimState:OverrideSkinSymbol("beard", skin_name, "beard_short")
    end
    inst.components.beard.bits = BEARD_BITS[1]
    inst.customidleanim = "idle_wilson"
end

local function OnGrowMediumBeard(inst, skin_name)
    if skin_name == nil then
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
    else
        inst.AnimState:OverrideSkinSymbol("beard", skin_name, "beard_medium")
    end
    inst.components.beard.bits = BEARD_BITS[2]
    inst.customidleanim = "idle_wilson_beard"
end

local function OnGrowLongBeard(inst, skin_name)
    if skin_name == nil then
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
    else
        inst.AnimState:OverrideSkinSymbol("beard", skin_name, "beard_long")
    end
    inst.components.beard.bits = BEARD_BITS[3]
    inst.customidleanim = "idle_wilson_beard"
end

local function OnShaved(inst)
    inst.customidleanim = "idle_wilson"
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv.default

    inst.customidleanim = "idle_wilson"

    inst:AddComponent("beard")
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard.prize = "beardhair"
    inst.components.beard.is_skinnable = true
    inst.components.beard:AddCallback(BEARD_DAYS[1], OnGrowShortBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[2], OnGrowMediumBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[3], OnGrowLongBeard)

    inst:ListenForEvent("shaved", OnShaved)
end

return MakePlayerCharacter("wilson", prefabs, assets, common_postinit, master_postinit)
