local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local IronlordBadge = require("widgets/ironlordbadge")

local function OnPoisonDamage(parent, data)
    parent.player_classified.poisonpulse:set_local(true)
    parent.player_classified.poisonpulse:set(true)
end

local function OnPoisonPulseDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("poisondamage")
    end
end

local ACTION_BUTTON_NO_TAGS = {"DECOR", "INLIMBO", "fire", "burnt", "FX"}
local ACTION_BUTTON_ONE_OF_TAGS = {"exterior_door", "interior_door", "pickable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable", "HACK_workable"}
local WORK_ACTIONS = {"CHOP", "DIG", "HAMMER", "MINE", "HACK"}

local function ActionStringOverride(inst, action)
    if action.action.id == "CHARGE_UP" then
        return STRINGS.ACTIONS.CHARGE_UP
    end
    return STRINGS.ACTIONS.PUNCH
end

local function ActionButtonOverride(inst, force_target)
    if inst.components.playercontroller:IsDoingOrWorking() then
        return nil, false
    end

    local function get_action(target)
        if target:HasTag("interior_door") or target:HasTag("exterior_door") and not target:HasTag("disabled") then
            return ACTIONS.USEDOOR
        end
        for _, work_action in ipairs(WORK_ACTIONS) do
            if target:HasTag(work_action .. "_workable") then
                return ACTIONS[work_action]
            end
        end
    end

    local is_direct_walking = inst.components.playercontroller.directwalking
    local action_dist = not force_target and (is_direct_walking and 3 or 6) or (is_direct_walking and 9 or 36)

    local x, y, z = inst.Transform:GetWorldPosition()
    local action_target = TheSim:FindEntities(x, y, z, action_dist, nil, ACTION_BUTTON_NO_TAGS, ACTION_BUTTON_ONE_OF_TAGS)

    for i, v in ipairs(action_target) do
        if v ~= inst and v.entity:IsVisible() and CanEntitySeeTarget(inst, v) then
            local action = get_action(v)
            if action ~= nil then
                return BufferedAction(inst, v, action)
            end
        end
    end

    return nil, false
end

local function LeftClickPicker(inst, target, pos)
    if not target or target == inst then
        return
    end

    if target:HasTag("interior_door") or target:HasTag("exterior_door") and not target:HasTag("disabled")
        and not (target:HasTag("burnt") or target:HasTag("fire")) then
        return inst.components.playeractionpicker:SortActionList({ACTIONS.USEDOOR}, target, nil)
    end

    if inst.replica.combat:CanTarget(target) then
        return inst.components.playeractionpicker:SortActionList({ACTIONS.ATTACK}, target, nil)
    end

    for _, work_action in ipairs(WORK_ACTIONS) do
        if target:HasTag(work_action .. "_workable") then
            return inst.components.playeractionpicker:SortActionList({ACTIONS[work_action]}, target, nil)
        end
    end
end

local function RightClickPicker(inst, target, pos)
    if not inst:HasTag("charging") then
        return inst.components.playeractionpicker:SortActionList({ACTIONS.CHARGE_UP}, pos, nil)
    end
    return {}
end

local function OverrideAction(inst)
    local player = inst._parent
    if not player or not player:IsValid() then
        return
    end

    if inst.isironlord:value() then
        player.ActionStringOverride = ActionStringOverride
        player.components.playercontroller.actionbuttonoverride = ActionButtonOverride
        player.components.playeractionpicker.leftclickoverride = LeftClickPicker
        player.components.playeractionpicker.rightclickoverride = RightClickPicker
    else
        player.ActionStringOverride = nil
        player.components.playercontroller.actionbuttonoverride = nil
        player.components.playeractionpicker.leftclickoverride = nil
        player.components.playeractionpicker.rightclickoverride = nil
    end
end

local function DoFlashTask(inst)
    local time = 0
    local nextflash = 0
    local intensity = 0

    local per = inst.player_classified.ironlordtimeleft:value()/TUNING.IRON_LORD_TIME
    if per > 0.5 then
        time = 1
        nextflash = 2
        intensity = 0
    elseif per > 0.3 then
        time = 0.5
        nextflash = 1
        intensity = 0.25
    elseif per > 0.05 then
        time = 0.3
        nextflash = 0.6
        intensity = 0.5
    else
        time = 0.13
        nextflash = 0.26
        intensity = 0.8
    end

    inst:PushEvent("livingartifactoverpulse", {time = time})
    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/common/crafted/iron_lord/pulse", {intensity = intensity})
    inst._ironlord_flash_task = inst:DoTaskInTime(nextflash, DoFlashTask)
end

local function OnIronlordDirty(inst)
    local player = inst._parent
    -- if not player or not player:IsValid() then
    --     return
    -- end

    if inst.isironlord:value() then
        TheWorld:PushEvent("enabledynamicmusic", false)
        if inst.instantironlord then -- in case of loading
            if not TheFocalPoint.SoundEmitter:PlayingSound("ironlordmusic") then
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/music/fight_epic_4", "ironlordmusic")
            end
        else
            player:DoTaskInTime(152 * FRAMES, function() -- 152 frames delay is for transform animation & sfx
                if not TheFocalPoint.SoundEmitter:PlayingSound("ironlordmusic") then
                    TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/music/fight_epic_4", "ironlordmusic")
                end
            end)
        end

        player:PushEvent("livingartifactoveron")

        player._ironlord_flash_task = player:DoTaskInTime(3, DoFlashTask)

        player.HUD.controls.ironlordbadge = player.HUD.controls.sidepanel:AddChild(IronlordBadge(player))
        player.HUD.controls.ironlordbadge:SetPosition(0, -100, 0)
        player.HUD.controls.ironlordbadge:SetPercent(1, TUNING.IRON_LORD_TIME)

        player.HUD.controls.crafttabs:Hide()
        player.HUD.controls.inv:Hide()
        player.HUD.controls.status:Hide()
        player.HUD.controls.mapcontrols.minimapBtn:Hide()
    else
        TheWorld:PushEvent("enabledynamicmusic", true)
        TheFocalPoint.SoundEmitter:KillSound("ironlordmusic")

        player:PushEvent("livingartifactoveroff")

        if player._ironlord_flash_task then
            player._ironlord_flash_task:Cancel()
            player._ironlord_flash_task = nil
        end

        if player.HUD.controls.ironlordbadge then
            player.HUD.controls.ironlordbadge:Kill()
            player.HUD.controls.ironlordbadge = nil
        end

        player.HUD.controls.crafttabs:Show()
        player.HUD.controls.inv:Show()
        player.HUD.controls.status:Show()
        player.HUD.controls.mapcontrols.minimapBtn:Show()
    end
end

local function OnIronlordTimeDirty(inst)
    inst._parent:PushEvent("ironlorddelta", {percent = inst.ironlordtimeleft:value() / TUNING.IRON_LORD_TIME})
end

local function RegisterNetListeners(inst)
    if TheWorld.ismastersim then
        inst._parent = inst.entity:GetParent()
        inst:ListenForEvent("poisondamage", OnPoisonDamage, inst._parent)
    else
        inst.poisonpulse:set_local(false)
        inst.isquaking:set_local(false)
        inst:ListenForEvent("poisonpulsedirty", OnPoisonPulseDirty)
    end

    if not TheNet:IsDedicated() then
        inst.isironlord:set_local(false)
        inst:ListenForEvent("ironlorddirty", OnIronlordDirty)
        inst.ironlordtimeleft:set_local(0)
        inst:ListenForEvent("ironlordtimedirty", OnIronlordTimeDirty)
        inst.instantironlord:set_local(false)
    end

    inst:ListenForEvent("ironlorddirty", OverrideAction)
end

AddPrefabPostInit("player_classified", function(inst)
    inst.ispoisoned = net_bool(inst.GUID, "poisonable.ispoisoned")
    inst.poisonpulse = net_bool(inst.GUID, "poisonable.poisonpulse", "poisonpulsedirty")
    inst.riderspeedmultiplier = net_float(inst.GUID, "rider.riderspeedmultiplier")
    inst.isquaking = net_bool(inst.GUID, "interiorquaker.isquaking", "isquakingdirty")

    inst.isironlord = inst.isironlord or net_bool(inst.GUID, "livingartifact.isironlord", "ironlorddirty")
    inst.ironlordtimeleft = inst.ironlordtimeleft or net_float(inst.GUID, "livingartifact.ironlordtimeleft", "ironlordtimedirty")
    inst.instantironlord = inst.instant_ironlord or net_bool(inst.GUID, "livingartifact.instantironlord") -- just a flag for loading

    inst.ispoisoned:set(false)
    inst.riderspeedmultiplier:set(1)
    inst.isquaking:set(false)

    inst:DoTaskInTime(0, RegisterNetListeners)
end)
