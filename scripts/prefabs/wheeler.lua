local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("ANIM", "anim/wheeler.zip"),
    Asset("ANIM", "anim/ghost_wheeler_build.zip"),
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/player_actions_roll.zip"),
}

local prefabs =
{

}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WHEELER
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local function AllowDodge(inst)
    return (GetTime() - inst.last_dodge_time > TUNING.WHEELER_DODGE_COOLDOWN)
        and not inst.replica.sailor:IsSailing() and not inst.replica.rider:IsRiding()
end

local function AllowDodge_Client(inst)
    return AllowDodge(inst)
        or (inst._candodge:value() == true)
end

local function GetPointSpecialActions(inst, pos, useitem, right)
    if right and useitem == nil then
        if inst:AllowDodge() then
            return { ACTIONS.DODGE }
        end
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker then
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end

local function UpdateBonusSpeed(inst)
    local empty_slots = inst.components.inventory:GetNumSlots() - inst.components.inventory:NumItems()
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wheeler_inventory", 1.05 + (0.01 * empty_slots))
end

local common_postinit = function(inst)
    -- For our hack in Inventory._ctor to pickup our prefab name
    inst:SetPrefabName("wheeler")

    inst.MiniMapEntity:SetIcon("wheeler.tex")

    inst.Anim_Hide_Hook = function(animstate, layername, ...)
        if layername == "HAIR" then
            animstate:_Hide("HAIRFRONT")
        end
        return animstate:_Hide(layername, ...)
    end

    inst.Anim_Show_Hook = function(animstate, layername, ...)
        if layername == "HAIR" then
            animstate:_Show("HAIRFRONT")
        end
        return animstate:_Show(layername, ...)
    end

    inst:AddTag("trusty_shooter")
    inst:AddTag("tracker_user")
    inst:ListenForEvent("setowner", OnSetOwner)

    inst.last_dodge_time = GetTime()
    inst._candodge = net_bool(inst.GUID, "_candodge")
    inst._candodge:set(true)

    if TheWorld.ismastersim then
        inst.AllowDodge = AllowDodge
    else
        inst.AllowDodge = AllowDodge_Client
    end
end

local master_postinit = function(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

    inst.talker_path_override = "dontstarve_DLC003/characters/"
    inst.SoundEmitter:OverrideSound("dontstarve_DLC003/characters/wheeler/ghost_LP", "porkland_soundpackage/characters/wheeler/ghost_LP")
    inst.SoundEmitter:OverrideSound("dontstarve_DLC003/characters/wheeler/pose", "porkland_soundpackage/characters/wheeler/pose")
    inst.SoundEmitter:OverrideSound("dontstarve_DLC003/characters/wheeler/yawn", "porkland_soundpackage/characters/wheeler/yawn")
    inst.SoundEmitter:OverrideSound("dontstarve_DLC003/characters/wheeler/eye_rub_vo", "porkland_soundpackage/characters/wheeler/eye_rub_vo")
    inst.SoundEmitter:OverrideSound("dontstarve_DLC003/characters/wheeler/carol", "porkland_soundpackage/characters/wheeler/carol")
    inst.SoundEmitter:OverrideSound("dontstarve_DLC003/characters/wheeler/emote", "porkland_soundpackage/characters/wheeler/emote")

    inst.components.health:SetMaxHealth(TUNING.WHEELER_HEALTH)
    inst.components.sanity:SetMax(TUNING.WHEELER_SANITY)
    inst.components.hunger:SetMax(TUNING.WHEELER_HUNGER)
    -- See postinit/components/inventory and postinit/components/inventory_replica,
    -- this is hard coded there
    -- inst.components.inventory:SetNumSlots(12)

    inst:ListenForEvent("itemget", UpdateBonusSpeed)
    inst:ListenForEvent("itemlose", UpdateBonusSpeed)
    inst:DoTaskInTime(0, UpdateBonusSpeed)
end

return MakePlayerCharacter("wheeler", prefabs, assets, common_postinit, master_postinit, start_inv)
