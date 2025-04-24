local MakePlayerCharacter = require("prefabs/player_common")
local easing = require("easing")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/woodie.fsb"),

    --Asset("ANIM", "anim/werebeaver_basic.zip"), --Moved to global.lua for use in Item Collection
    Asset("ANIM", "anim/werebeaver_groggy.zip"),
    Asset("ANIM", "anim/werebeaver_dance.zip"),
    Asset("ANIM", "anim/werebeaver_boat_jump.zip"),
    Asset("ANIM", "anim/werebeaver_boat_plank.zip"),
    Asset("ANIM", "anim/werebeaver_boat_sink.zip"),
	Asset("ANIM", "anim/werebeaver_abyss_fall.zip"),
    Asset("ANIM", "anim/player_revive_to_werebeaver.zip"),
    Asset("ANIM", "anim/player_amulet_resurrect_werebeaver.zip"),
    Asset("ANIM", "anim/player_rebirth_werebeaver.zip"),
    Asset("ANIM", "anim/player_woodie.zip"),
    Asset("ANIM", "anim/round_puff_fx.zip"),
    Asset("ANIM", "anim/player_idles_woodie.zip"),
    Asset("ANIM", "anim/player_actions_woodcarving.zip"),
    Asset("ANIM", "anim/player_mount_woodcarving.zip"),
    Asset("ATLAS", "images/woodie.xml"),
    Asset("IMAGE", "images/woodie.tex"),
    Asset("IMAGE", "images/colour_cubes/beaver_vision_cc.tex"),
    Asset("MINIMAP_IMAGE", "woodie_1"), --beaver
    Asset("SCRIPT", "scripts/prefabs/skilltree_woodie.lua"),
}

local prefabs =
{
    "shovel_dirt",
    "plant_dug_small_fx",
    "round_puff_fx_sm",
    "round_puff_fx_lg",
    "round_puff_fx_hi",
    --
    "werebeaver_transform_fx",
    "werebeaver_shock_fx",
    --
    "reticuleline2",
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WOODIE
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local BEAVERVISION_COLOURCUBES =
{
    day = "images/colour_cubes/beaver_vision_cc.tex",
    dusk = "images/colour_cubes/beaver_vision_cc.tex",
    night = "images/colour_cubes/beaver_vision_cc.tex",
    full_moon = "images/colour_cubes/beaver_vision_cc.tex",
}

local WEREMODE_NAMES =
{
    "beaver",
}

local WEREMODES = { NONE = 0 }
for i, v in ipairs(WEREMODE_NAMES) do
    WEREMODES[string.upper(v)] = i
end

local function IsWereMode(mode)
    return WEREMODE_NAMES[mode] ~= nil
end

--------------------------------------------------------------------------

local function GetWereStatus(inst)--, viewer)
    return inst:HasTag("playerghost")
        and (string.upper(WEREMODE_NAMES[inst.weremode:value()]).."GHOST")
        or string.upper(WEREMODE_NAMES[inst.weremode:value()])
end

--------------------------------------------------------------------------

local BEAVER_LMB_ACTIONS =
{
    "CHOP",
    "MINE",
    "DIG",
    "HACK",
}

local BEAVER_ACTION_TAGS = {}

for i, v in ipairs(BEAVER_LMB_ACTIONS) do
    table.insert(BEAVER_ACTION_TAGS, v.."_workable")
end

local BEAVER_TARGET_EXCLUDE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "catchable", "sign" }

local function CannotExamine(inst)
    return false
end

local function BeaverActionString(inst, action)
    return (action.action == ACTIONS.MOUNT_PLANK and STRINGS.ACTIONS.MOUNT_PLANK)
        or (action.action == ACTIONS.ABANDON_SHIP and STRINGS.ACTIONS.ABANDON_SHIP)
        or (action.action == ACTIONS.USE_WEREFORM_SKILL and STRINGS.ACTIONS.USE_WEREFORM_SKILL.BEAVER)
        or STRINGS.ACTIONS.GNAW
        ,
        (action.action == ACTIONS.ABANDON_SHIP)
        or (action.action == ACTIONS.USE_WEREFORM_SKILL)
        or nil
end

local function GetBeaverAction(inst, target)
    for i, v in ipairs(BEAVER_LMB_ACTIONS) do
        if target:HasTag(v.."_workable") then
            return not target:HasTag("sign") and ACTIONS[v] or nil
        end
    end

    if target:HasTag("walkingplank") and target:HasTag("interactable") then
        return (inst:HasTag("on_walkable_plank") and ACTIONS.ABANDON_SHIP) or
                (target:HasTag("plank_extended") and ACTIONS.MOUNT_PLANK) or
                ACTIONS.EXTEND_PLANK
    end
end

local function BeaverActionButton(inst, force_target)
    if not inst.components.playercontroller:IsDoingOrWorking() then
        if force_target == nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, inst.components.playercontroller.directwalking and 3 or 6, nil, BEAVER_TARGET_EXCLUDE_TAGS, BEAVER_ACTION_TAGS)
            for i, v in ipairs(ents) do
                if v ~= inst and v.entity:IsVisible() and CanEntitySeeTarget(inst, v) then
                    local action = GetBeaverAction(inst, v)
                    if action ~= nil then
                        return BufferedAction(inst, v, action)
                    end
                end
            end
        elseif inst:GetDistanceSqToInst(force_target) <= (inst.components.playercontroller.directwalking and 9 or 36) then
            local action = GetBeaverAction(inst, force_target)
            if action ~= nil then
                return BufferedAction(inst, force_target, action)
            end
        end
    end
end

local function BeaverLeftClickPicker(inst, target)
    if target ~= nil and target ~= inst then
        if inst.replica.combat:CanTarget(target) then
            return (not target:HasTag("player") or inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_ATTACK))
                and inst.components.playeractionpicker:SortActionList({ ACTIONS.ATTACK }, target, nil)
                or nil
        end
        for i, v in ipairs(BEAVER_LMB_ACTIONS) do
            if target:HasTag(v.."_workable") then
                return not target:HasTag("sign")
                    and inst.components.playeractionpicker:SortActionList({ ACTIONS[v] }, target, nil)
                    or nil
            end
        end

        if target:HasTag("walkingplank") and target:HasTag("interactable") and target:HasTag("plank_extended") then
            return inst.components.playeractionpicker:SortActionList({ ACTIONS.MOUNT_PLANK }, target, nil)
        end
    end
end

local function BeaverRightClickPicker(inst, target, pos)
    return target ~= nil
        and target ~= inst
        and (   (   inst:HasTag("on_walkable_plank") and
                    target:HasTag("walkingplank") and
                    inst.components.playeractionpicker:SortActionList({ ACTIONS.ABANDON_SHIP }, target, nil)
                ) or
                (   target:HasTag("HAMMER_workable") and
                    inst.components.playeractionpicker:SortActionList({ ACTIONS.HAMMER }, target, nil)
                ) or
                (   target:HasTag("DIG_workable") and
                    target:HasTag("sign") and
                    inst.components.playeractionpicker:SortActionList({ ACTIONS.DIG }, target, nil)
                )
            )
end

local function Empty()
end

local function SetWereActions(inst, mode)
    if not IsWereMode(mode) then
        inst.ActionStringOverride = nil
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller.actionbuttonoverride = nil
        end
        if inst.components.playeractionpicker ~= nil then
            inst.components.playeractionpicker.leftclickoverride = nil
            inst.components.playeractionpicker.rightclickoverride = nil
            inst.components.playeractionpicker.pointspecialactionsfn = nil
        end
    elseif mode == WEREMODES.BEAVER then
        inst.ActionStringOverride = BeaverActionString
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller.actionbuttonoverride = BeaverActionButton
        end
        if inst.components.playeractionpicker ~= nil then
            inst.components.playeractionpicker.leftclickoverride = BeaverLeftClickPicker
            inst.components.playeractionpicker.rightclickoverride = BeaverRightClickPicker
        end
    end
end

local function SetWereVision(inst, mode)
    if IsWereMode(mode) then
        inst.components.playervision:PushForcedNightVision(inst, 2, BEAVERVISION_COLOURCUBES, false)
    else
        inst.components.playervision:PopForcedNightVision(inst)
    end
end

local function SetWereMode(inst, mode, skiphudfx)
    if IsWereMode(mode) then
        TheWorld:PushEvent("enabledynamicmusic", false)
        if not TheFocalPoint.SoundEmitter:PlayingSound("beavermusic") then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/music/music_hoedown")
        end

        inst.HUD.controls.status:SetWereMode(true, skiphudfx)
        if inst.HUD.beaverOL ~= nil then
            inst.HUD.beaverOL:Show()
        end

        if not TheWorld.ismastersim then
            inst.CanExamine = CannotExamine
            SetWereActions(inst, mode)
            SetWereVision(inst, mode)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor.runspeed = TUNING.BEAVER_RUN_SPEED
            end
        end
    else
        TheWorld:PushEvent("enabledynamicmusic", true)
        TheFocalPoint.SoundEmitter:KillSound("beavermusic")

        inst.HUD.controls.status:SetWereMode(false, skiphudfx)
        if inst.HUD.beaverOL ~= nil then
            inst.HUD.beaverOL:Hide()
        end

        if not TheWorld.ismastersim then
            inst.CanExamine = nil
            SetWereActions(inst, mode)
            SetWereVision(inst, mode)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
            end
        end
    end
end

local function SetGhostMode(inst, isghost)
    if isghost then
        SetWereMode(inst, WEREMODES.NONE, true)
        inst._SetGhostMode(inst, true)
    else
        inst._SetGhostMode(inst, false)
        SetWereMode(inst, inst.weremode:value(), true)
    end
end

local function OnWereModeDirty(inst)
    if inst.HUD ~= nil and not inst:HasTag("playerghost") then
        SetWereMode(inst, inst.weremode:value())
    end
end

local function OnPlayerDeactivated(inst)
    inst:RemoveEventCallback("onremove", OnPlayerDeactivated)
    if not TheWorld.ismastersim then
        inst:RemoveEventCallback("weremodedirty", OnWereModeDirty)
    end
    TheFocalPoint.SoundEmitter:KillSound("beavermusic")
end

local function OnPlayerActivated(inst)
    if inst.HUD.beaverOL == nil then
        inst.HUD.beaverOL = inst.HUD.overlayroot:AddChild(Image("images/woodie.xml", "beaver_vision_OL.tex"))
        inst.HUD.beaverOL:SetVRegPoint(ANCHOR_MIDDLE)
        inst.HUD.beaverOL:SetHRegPoint(ANCHOR_MIDDLE)
        inst.HUD.beaverOL:SetVAnchor(ANCHOR_MIDDLE)
        inst.HUD.beaverOL:SetHAnchor(ANCHOR_MIDDLE)
        inst.HUD.beaverOL:SetScaleMode(SCALEMODE_FILLSCREEN)
        inst.HUD.beaverOL:SetClickable(false)
    end
    inst:ListenForEvent("onremove", OnPlayerDeactivated)
    if not TheWorld.ismastersim then
        inst:ListenForEvent("weremodedirty", OnWereModeDirty)
    end
    OnWereModeDirty(inst)
end

--------------------------------------------------------------------------

--Deprecated
local function GetBeaverness(inst) return 1 end
local function IsBeaverStarving(inst) return false end
--

local function GetWereness(inst)
    if inst.components.wereness ~= nil then
        return inst.components.wereness:GetPercent()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currentwereness:value() * .01
    else
        return 0
    end
end

local function GetWerenessDrainRate(inst)
    if inst.components.wereness ~= nil then
        return inst.components.wereness.rate
    elseif inst.player_classified ~= nil then
        return inst.player_classified.werenessdrainrate:value() / -6.3
    else
        return 0
    end
end

local function CanShaveTest(inst)
    return false, "REFUSE"
end

local function OnResetBeard(inst)
    inst.components.beard.bits = IsWereMode(inst.weremode:value()) and 0 or 3
end

local function WereSanityFn()
    return TUNING.WERE_SANITY_PENALTY
end

local function beaverbonusdamagefn(inst, target, damage, weapon)
    return (target:HasTag("tree") or target:HasTag("beaverchewable")) and TUNING.BEAVER_WOOD_DAMAGE or 0
end

local function CalculateWerenessDrainRate(inst, mode, isfullmoon)
    return -1
end

--------------------------------------------------------------------------

local function IsLucy(item)
    return item.prefab == "lucy"
end

local function onworked(inst, data)
    if data.target ~= nil and
        data.target.components.workable ~= nil and
        data.target.components.workable.action == ACTIONS.CHOP then
        local equipitem = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equipitem ~= nil and equipitem:HasTag("possessable_axe") then
            local itemuses = equipitem.components.finiteuses ~= nil and equipitem.components.finiteuses:GetUses() or nil
            if (itemuses == nil or itemuses > 0) and inst.components.inventory:FindItem(IsLucy) == nil then
                --Don't make Lucy if we already have one
                local lucy = SpawnPrefab("lucy")
                lucy.components.possessedaxe.revert_prefab = equipitem.prefab
                lucy.components.possessedaxe.revert_uses = itemuses
                equipitem:Remove()
                inst.components.inventory:Equip(lucy)
                if lucy.components.possessedaxe.transform_fx ~= nil then
                    local fx = SpawnPrefab(lucy.components.possessedaxe.transform_fx)
                    if fx ~= nil then
                        fx.entity:AddFollower()
                        fx.Follower:FollowSymbol(inst.GUID, "swap_object", 50, -25, 0)
                    end
                end
            end
        end
    end
end

local function OnIsFullmoon(inst, isfullmoon)

    if not isfullmoon then
        inst.fullmoontriggered = nil
        if inst.components.wereness:GetWereMode() == "fullmoon" then
            inst.components.wereness:SetWereMode(nil)
            if not IsWereMode(inst.weremode:value()) then
                inst.components.wereness:SetPercent(0, true)
            end
        end
    elseif not inst.fullmoontriggered then
        local pct = inst.components.wereness:GetPercent()
        if pct > 0 then
            inst.components.wereness:SetPercent(1)
        end
    end
    if IsWereMode(inst.weremode:value()) then
        inst.components.wereness:SetDrainRate(CalculateWerenessDrainRate(inst, inst.weremode:value(), isfullmoon))
    end
end

--------------------------------------------------------------------------

local function SetWereDrowning(inst, mode)
    --V2C: drownable HACKS, using "false" to override "nil" load behaviour
    --     Please refactor drownable to use POST LOAD timing.
    if inst.components.drownable ~= nil then
        inst.components.drownable.enabled = true
        if not inst:HasTag("playerghost") then
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
            inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
            inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            inst.Physics:CollidesWith(COLLISION.GIANTS)
            inst.Physics:Teleport(inst.Transform:GetWorldPosition())
        end
    end
end

--------------------------------------------------------------------------

local function OnBeaverWorkingOver(inst)
    if inst._beaverworkinglevel > 1 then
        inst._beaverworkinglevel = inst._beaverworkinglevel - 1
        inst._beaverworking = inst:DoTaskInTime(TUNING.BEAVER_WORKING_DRAIN_TIME_DURATION, OnBeaverWorkingOver)
    else
        inst._beaverworking = nil
        inst._beaverworkinglevel = nil
    end
    inst.components.wereness:SetDrainRate(CalculateWerenessDrainRate(inst, WEREMODES.BEAVER, TheWorld.state.isfullmoon))
end

local function OnBeaverWorking(inst)
    if inst._beaverworking ~= nil then
        inst._beaverworking:Cancel()
    end
    inst._beaverworking = inst:DoTaskInTime(TUNING.BEAVER_WORKING_DRAIN_TIME_DURATION, OnBeaverWorkingOver)
    inst._beaverworkinglevel = 2
    inst.components.wereness:SetDrainRate(CalculateWerenessDrainRate(inst, WEREMODES.BEAVER, TheWorld.state.isfullmoon))
end

local function OnBeaverFighting(inst, data)
    if data ~= nil and data.target ~= nil then
        OnBeaverWorking(inst)
    end
end

local function OnBeaverOnMissOther(inst, data)
    if not inst.sg:HasStateTag("tailslapping") then
        OnBeaverFighting(inst, data)
    end
end

local function SetWereWorker(inst, mode)
    inst:RemoveEventCallback("working", onworked)

    if mode == WEREMODES.BEAVER then
        if inst.components.worker == nil then
            local modifiers = TUNING.SKILLS.WOODIE.BEAVER_WORK_MULTIPLIER

            inst:AddComponent("worker")
            inst.components.worker:SetAction(ACTIONS.CHOP,   4)
            inst.components.worker:SetAction(ACTIONS.HACK,   4)
            inst.components.worker:SetAction(ACTIONS.MINE,   .5)
            inst.components.worker:SetAction(ACTIONS.DIG,    .5)
            inst.components.worker:SetAction(ACTIONS.HAMMER, .25)
            inst:ListenForEvent("working", OnBeaverWorking)
            inst:ListenForEvent("onattackother", OnBeaverFighting)
            inst:ListenForEvent("onmissother", OnBeaverOnMissOther)
            OnBeaverWorking(inst)
        end
    else
        if inst.components.worker ~= nil then
            inst:RemoveComponent("worker")
            inst:RemoveEventCallback("working", OnBeaverWorking)
            inst:RemoveEventCallback("onattackother", OnBeaverFighting)
            inst:RemoveEventCallback("onmissother", OnBeaverFighting)
            if inst._beaverworking ~= nil then
                inst._beaverworking:Cancel()
                inst._beaverworking = nil
                inst._beaverworkinglevel = nil
            end
        end

        inst:RemoveTag("toughworker")

        inst:ListenForEvent("working", onworked)
    end
end

--------------------------------------------------------------------------

local function SetWereSounds(inst, mode)
    inst.hurtsoundoverride =
        (mode == WEREMODES.BEAVER and "dontstarve/characters/woodie/hurt_beaver") or nil
end

--------------------------------------------------------------------------

local function ChangeWereModeValue(inst, newmode)
    if inst.weremode:value() ~= newmode then
        if IsWereMode(inst.weremode:value()) then
            if not IsWereMode(newmode) then
                inst:RemoveTag("wereplayer")
            end
            inst:RemoveTag(inst.weremode:value() == WEREMODES.BEAVER and "beaver" or ("were"..WEREMODE_NAMES[inst.weremode:value()]))
            inst.Network:RemoveUserFlag(USERFLAGS["CHARACTER_STATE_"..tostring(inst.weremode:value())])
        else
            inst:AddTag("wereplayer")
        end

        inst.weremode:set(newmode)

        if IsWereMode(newmode) then
            inst:AddTag(newmode == WEREMODES.BEAVER and "beaver" or ("were"..WEREMODE_NAMES[newmode]))
            inst.Network:AddUserFlag(USERFLAGS["CHARACTER_STATE_"..tostring(newmode)])
            inst.overrideskinmode = "were"..WEREMODE_NAMES[newmode].."_skin"
            inst.overrideghostskinmode = "ghost_"..inst.overrideskinmode
            inst:PushEvent("startwereplayer") --event for sentientaxe
        else
            inst.overrideskinmode = nil
            inst.overrideghostskinmode = nil
            inst:PushEvent("stopwereplayer") --event for sentientaxe
        end

        OnWereModeDirty(inst)
    end
end

--V2C: if the debuff symbol offsets change, then make sure you update the offsets
local SKIN_MODE_DATA =
{
    ["normal_skin"] = {
        bank = "wilson",
        shadow = { 1.3, .6 },
        debuffsymbol = { "headbase", 0, -200, 0 },
    },
    ["werebeaver_skin"] = {
        bank = "werebeaver",
        hideclothing = true,
        shadow = { 1.3, .6 },
        debuffsymbol = { "torso", 0, -280, 0 },
    },
    ["ghost_skin"] = {
        bank = "ghost",
        shadow = { 1.3, .6 },
    },
}
for i, v in ipairs(WEREMODE_NAMES) do
    SKIN_MODE_DATA["ghost_were"..v.."_skin"] = SKIN_MODE_DATA["ghost_skin"]
end

local function CustomSetShadowForSkinMode(inst, skinmode)
    inst.DynamicShadow:SetSize(unpack(SKIN_MODE_DATA[skinmode].shadow))
end

local function CustomSetDebuffSymbolForSkinMode(inst, skinmode)
    inst.components.debuffable:SetFollowSymbol(unpack(SKIN_MODE_DATA[skinmode].debuffsymbol))
end

local function CustomSetSkinMode(inst, skinmode)
    local data = SKIN_MODE_DATA[skinmode]
    if data.hideclothing then
        inst.components.skinner:HideAllClothing(inst.AnimState)
    end
    inst.AnimState:SetBank(data.bank)
    inst.components.skinner:SetSkinMode(skinmode)
    inst.DynamicShadow:SetSize(unpack(data.shadow))
    if data.debuffsymbol ~= nil then
        inst.components.debuffable:SetFollowSymbol(unpack(data.debuffsymbol))
    end
    if inst.components.freezable ~= nil then
        inst.components.freezable:SetShatterFXLevel(data.freezelevel or 4)
    end
    inst.Transform:SetFourFaced()
end

local function onbecamehuman(inst)
    if inst.prefab == nil then
        --when entity is being spawned
        CustomSetDebuffSymbolForSkinMode(inst, "normal_skin")
        --CustomSetShadowForSkinMode(inst, "normal_skin") --should be same as default already
    elseif not inst.sg:HasStateTag("ghostbuild") then
        CustomSetSkinMode(inst, "normal_skin")
    end

    inst.MiniMapEntity:SetIcon("woodie.png")

    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
    inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
    inst.components.combat.bonusdamagefn = nil
    inst.components.health:SetAbsorptionAmount(0)
    inst.components.sanity.custom_rate_fn = nil
    inst.components.pinnable.canbepinned = true
    if not GetGameModeProperty("no_hunger") then
        inst.components.hunger:Resume()
        if IsWereMode(inst.weremode:value()) then
            local hungerpercent = inst:HasTag("cursemaster") and TUNING.SKILLS.WOODIE.CURSE_MASTER_MIN_HUNGER or 0
            inst.components.hunger:SetPercent(hungerpercent, true)
        end
    end
    inst.components.temperature.inherentinsulation = 0
    inst.components.temperature.inherentsummerinsulation = 0
    inst.components.moisture:SetInherentWaterproofness(0)
    inst.components.talker:StopIgnoringAll("becamewere")
    inst.components.catcher:SetEnabled(true)
    inst.components.sandstormwatcher:SetSandstormSpeedMultiplier(TUNING.SANDSTORM_SPEED_MOD)
    inst.components.moonstormwatcher:SetMoonstormSpeedMultiplier(TUNING.MOONSTORM_SPEED_MOD)
    inst.components.miasmawatcher:SetMiasmaSpeedMultiplier(TUNING.MIASMA_SPEED_MOD)
    inst.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(TUNING.CAREFUL_SPEED_MOD)
    inst.components.wereeater:ResetFoodMemory()
    inst.components.wereness:StopDraining()

    if inst.components.inspectable.getstatus == GetWereStatus then
        inst.components.inspectable.getstatus = inst._getstatus
        inst._getstatus = nil
    end

    inst.CanExamine = nil

    --[[if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:SetCanUseMap(true)
    end]]

    SetWereDrowning(inst, WEREMODES.NONE)
    SetWereWorker(inst, WEREMODES.NONE)
    SetWereActions(inst, WEREMODES.NONE)
    SetWereSounds(inst, WEREMODES.NONE)
    SetWereVision(inst, WEREMODES.NONE)
    ChangeWereModeValue(inst, WEREMODES.NONE)
    OnResetBeard(inst)
end

local function onbecamebeaver(inst)
    if not inst.sg:HasStateTag("ghostbuild") then
        CustomSetSkinMode(inst, "werebeaver_skin")
    end

    inst.MiniMapEntity:SetIcon("woodie_1.png")

    inst.components.locomotor.runspeed = TUNING.BEAVER_RUN_SPEED
    inst.components.combat:SetDefaultDamage(TUNING.BEAVER_DAMAGE)
    inst.components.combat.bonusdamagefn = beaverbonusdamagefn
    inst.components.health:SetAbsorptionAmount(TUNING.BEAVER_ABSORPTION)
    inst.components.sanity.custom_rate_fn = WereSanityFn
    inst.components.pinnable.canbepinned = false
    if not GetGameModeProperty("no_hunger") then
        if inst.components.hunger:IsStarving() then
            inst.components.hunger:SetPercent(.001, true)
        end
        inst.components.hunger:Pause()
    end
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_LARGE
    inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_LARGE
    inst.components.moisture:SetInherentWaterproofness(TUNING.WATERPROOFNESS_LARGE)
    inst.components.talker:IgnoreAll("becamewere")
    inst.components.catcher:SetEnabled(false)
    inst.components.sandstormwatcher:SetSandstormSpeedMultiplier(1)
    inst.components.moonstormwatcher:SetMoonstormSpeedMultiplier(1)
    inst.components.miasmawatcher:SetMiasmaSpeedMultiplier(1)
    inst.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(1)
    inst.components.wereeater:ResetFoodMemory()
    inst.components.wereness:SetDrainRate(CalculateWerenessDrainRate(inst, WEREMODES.BEAVER, TheWorld.state.isfullmoon))
    inst.components.wereness:StartDraining()
    inst.components.wereness:SetWereMode(nil)

    if inst.components.inspectable.getstatus ~= GetWereStatus then
        inst._getstatus = inst.components.inspectable.getstatus
        inst.components.inspectable.getstatus = GetWereStatus
    end

    inst.CanExamine = CannotExamine

    --[[if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:SetCanUseMap(false)
    end]]

    SetWereDrowning(inst, WEREMODES.BEAVER)
    SetWereWorker(inst, WEREMODES.BEAVER)
    SetWereActions(inst, WEREMODES.BEAVER)
    SetWereSounds(inst, WEREMODES.BEAVER)
    SetWereVision(inst, WEREMODES.BEAVER)
    ChangeWereModeValue(inst, WEREMODES.BEAVER)
    OnResetBeard(inst)
end

local function onwerenesschange(inst)
    if inst.sg:HasStateTag("nomorph") or
        inst.sg:HasStateTag("silentmorph") or
        inst:HasTag("playerghost") or
        inst.components.health:IsDead() then
        return
    elseif IsWereMode(inst.weremode:value()) then
        if inst.components.wereness:GetPercent() <= 0 then
            inst:PushEvent("transform_person", { mode = WEREMODE_NAMES[inst.weremode:value()], cb = onbecamehuman })
        end
    elseif inst.components.wereness:GetPercent() > 0 then
        local weremode = inst.components.wereness:GetWereMode()
        if weremode ~= nil then
            if weremode ~= "fullmoon" then
                weremode = WEREMODES[string.upper(weremode)]
            elseif TheWorld.state.isfullmoon then
                weremode = math.random(#WEREMODE_NAMES)
            else
                weremode = WEREMODES.NONE
                inst.components.wereness:SetWereMode(nil)
                if not IsWereMode(inst.weremode:value()) then
                    inst.components.wereness:SetPercent(0, true)
                end
            end
            if IsWereMode(weremode) then
                inst:PushEvent("transform_wereplayer", {
                    mode = WEREMODE_NAMES[weremode],
                    cb = (weremode == WEREMODES.BEAVER and onbecamebeaver) or
                        nil
                })
            end
        end
    end
end

local function onnewstate(inst)
    if inst._wasnomorph ~= (inst.sg:HasStateTag("nomorph") or inst.sg:HasStateTag("silentmorph")) then
        inst._wasnomorph = not inst._wasnomorph
        if not inst._wasnomorph then
            onwerenesschange(inst)
        end
    end

    if IsWereMode(inst.weremode:value()) then
        inst.components.wereness:SetDrainRate(CalculateWerenessDrainRate(inst, inst.weremode:value(), TheWorld.state.isfullmoon))
    end
end

local function onrespawnedfromghost(inst, data, nofullmoontest)
    if inst._wasnomorph == nil then
        inst._wasnomorph = inst.sg:HasStateTag("nomorph") or inst.sg:HasStateTag("silentmorph")
        inst:ListenForEvent("werenessdelta", onwerenesschange)
        inst:ListenForEvent("newstate", onnewstate)
        inst:WatchWorldState("isfullmoon", OnIsFullmoon)
    end

    if IsWereMode(inst.weremode:value()) then
        inst.components.inventory:Close()
        if inst.weremode:value() == WEREMODES.BEAVER then
            onbecamebeaver(inst)
        end
    else
        onbecamehuman(inst)
    end

    -- nofullmoontest is an argument passed manually only!
    if not nofullmoontest then
        OnIsFullmoon(inst, TheWorld.state.isfullmoon)
    end
end

local function onbecameghost(inst, data)
    if not IsWereMode(inst.weremode:value()) then
        --clear any queued transformations
        inst.components.wereness:SetPercent(0, true)
    elseif data == nil or not data.corpse then
        CustomSetSkinMode(inst, "ghost_were"..WEREMODE_NAMES[inst.weremode:value()].."_skin")
    end

    inst.components.wereeater:ResetFoodMemory()
    inst.components.wereness:StopDraining()
    inst.components.wereness:SetWereMode(nil)

    if inst._wasnomorph ~= nil then
        inst._wasnomorph = nil
        inst:RemoveEventCallback("werenessdelta", onwerenesschange)
        inst:RemoveEventCallback("newstate", onnewstate)
        inst:StopWatchingWorldState("isfullmoon", OnIsFullmoon)
    end

    SetWereDrowning(inst, WEREMODES.NONE)
    SetWereWorker(inst, WEREMODES.NONE)
    SetWereActions(inst, WEREMODES.NONE)
    SetWereSounds(inst, WEREMODES.NONE)
    SetWereVision(inst, WEREMODES.NONE)
end

local function OnForceTransform(inst, weremode)
    inst.components.wereness:SetWereMode("beaver")
    inst.components.wereness:SetPercent(1, true)
    -- NOTES(JBK): Do not call StartDraining here it is handled by the stategraph callback.
end

--------------------------------------------------------------------------

--Re-enter idle state right after loading because
--idle animations are determined by were state.
local function onentityreplicated(inst)
    if inst.sg ~= nil and inst:HasTag("wereplayer") then
        inst.sg:GoToState("idle")
    end
end

local function onpreload(inst, data)
    if data ~= nil and data.fullmoontriggered then
        if inst.fullmoontriggered then
            inst.components.wereness:SetWereMode(nil)
            inst.components.wereness:SetPercent(0, true)
        else
            inst.fullmoontriggered = true
        end
    end

    if data ~= nil then
        if data.isbeaver then
            onbecamebeaver(inst)
        else
            return
        end
        inst.sg:GoToState("idle")
    end
end

local function onload(inst)
    if IsWereMode(inst.weremode:value()) and not inst:HasTag("playerghost") then
        inst.components.inventory:Close()
        if inst.components.wereness:GetPercent() <= 0 then
            --under these conditions, we won't get a "werenessdelta" event on load
            --but we do want to trigger a transformation back to human right away.
            onwerenesschange(inst)
        end
    end

    OnIsFullmoon(inst, TheWorld.state.isfullmoon)
end

local function onsave(inst, data)
    if IsWereMode(inst.weremode:value()) then
        data["is"..WEREMODE_NAMES[inst.weremode:value()]] = true
    end
    data.fullmoontriggered = inst.fullmoontriggered
end

--------------------------------------------------------------------------

local TALLER_FROSTYBREATHER_OFFSET = Vector3(.3, 3.75, 0)
local WEREMODE_FROSTYBREATHER_OFFSET =
{
    [WEREMODES.BEAVER] = Vector3(1.2, 2.15, 0),
}
local DEFAULT_FROSTYBREATHER_OFFSET = Vector3(.3, 1.15, 0)
local function GetFrostyBreatherOffset(inst)
    local rider = inst.replica.rider
    return (rider ~= nil and rider:IsRiding() and TALLER_FROSTYBREATHER_OFFSET)
        or WEREMODE_FROSTYBREATHER_OFFSET[inst.weremode:value()]
        or DEFAULT_FROSTYBREATHER_OFFSET
end

local function customidleanimfn(inst)
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return item ~= nil and item.prefab == "lucy" and "idle_woodie" or nil
end

--------------------------------------------------------------------------

local function UseWereFormSkill(inst, act)

end

local function IsWerebeaver(inst)
    return inst.weremode:value() == WEREMODES.BEAVER
end

--------------------------------------------------------------------------

local function common_postinit(inst)
    inst:AddTag("woodcutter")
    inst:AddTag("polite")
    inst:AddTag("werehuman")

    --bearded (from beard component) added to pristine state for optimization
    inst:AddTag("bearded")

    inst.AnimState:AddOverrideBuild("player_actions_woodcarving")

    inst.AnimState:OverrideSymbol("round_puff01", "round_puff_fx", "round_puff01")

    inst:AddTag("wereness")

    --Deprecated
    inst.GetBeaverness = GetBeaverness
    inst.IsBeaverStarving = IsBeaverStarving
    --
    inst.GetWereness = GetWereness -- Didn't want to make wereness a networked component
    inst.GetWerenessDrainRate = GetWerenessDrainRate

    inst.weremode = net_tinybyte(inst.GUID, "woodie.weremode", "weremodedirty")

    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)

    if inst.ghostenabled then
        inst._SetGhostMode = inst.SetGhostMode
        inst.SetGhostMode = SetGhostMode
    end

    inst.components.frostybreather:SetOffsetFn(GetFrostyBreatherOffset)

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = onentityreplicated
    end    
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

    inst.customidleanim = customidleanimfn

    inst.components.health:SetMaxHealth(TUNING.WOODIE_HEALTH)
    inst.components.hunger:SetMax(TUNING.WOODIE_HUNGER)
    inst.components.sanity:SetMax(TUNING.WOODIE_SANITY)

    -- Give Woodie a beard so he gets some insulation from winter cold
    -- (Value is Wilson's level 2 beard.)
    inst:AddComponent("beard")
    inst.components.beard.canshavetest = CanShaveTest
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard:EnableGrowth(false)

    OnResetBeard(inst)

    inst:AddComponent("wereness")

    inst:AddComponent("wereeater")
    inst.components.wereeater:SetForceTransformFn(OnForceTransform)

    inst._getstatus = nil
    inst._wasnomorph = nil

    inst.CustomSetSkinMode = CustomSetSkinMode
    inst.CustomSetShadowForSkinMode = CustomSetShadowForSkinMode
    inst.CustomSetDebuffSymbolForSkinMode = CustomSetDebuffSymbolForSkinMode

    inst.UseWereFormSkill = UseWereFormSkill

    inst.IsWerebeaver = IsWerebeaver

    inst:ListenForEvent("ms_respawnedfromghost", onrespawnedfromghost)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    onrespawnedfromghost(inst, nil, true)

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnPreLoad = onpreload
end

return MakePlayerCharacter("woodie", prefabs, assets, common_postinit, master_postinit)
