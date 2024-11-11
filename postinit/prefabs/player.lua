local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function PlayOincSound(inst)
    local transaction_amount = inst._oinc_sound:value()
    if transaction_amount == 0 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/1")
    elseif transaction_amount == 1 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/1")
    elseif transaction_amount == 2 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/2")
    else
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/3_plus")
    end
end

local function ScheduleOincSoundEvent(inst, amount)
    if not inst.oinc_transaction then
        inst.oinc_transaction = 0
    end
    if not inst.max_oinc_transaction then
        inst.max_oinc_transaction = 0
    end
    inst.oinc_transaction = inst.oinc_transaction + amount
    if math.abs(inst.oinc_transaction) > inst.max_oinc_transaction then
        inst.max_oinc_transaction = math.abs(inst.oinc_transaction)
    end

    if not inst.oinc_transaction_task then
        inst.oinc_transaction_task = inst:DoTaskInTime(0, function()
            inst._oinc_sound:set_local(0)
            inst._oinc_sound:set(inst.max_oinc_transaction)
            inst.max_oinc_transaction = nil
            inst.oinc_transaction = nil
            inst.oinc_transaction_task = nil
        end)
    end
end

local function OnItemGet(inst, data)
    local item = data.item
    if not item then
        return
    end

    if item:HasTag("oinc") then
        ScheduleOincSoundEvent(inst, item.components.stackable and item.components.stackable:StackSize() or 1)

        item.oinc_sound_stackchange_listener = function(_, data)
            local amount_changed = data.stacksize - data.oldstacksize
            ScheduleOincSoundEvent(inst, amount_changed)
        end
        item:ListenForEvent("stacksizechange", item.oinc_sound_stackchange_listener)
    end
end

local function OnItemLose(inst, data)
    local item = data.prev_item
    if not item then
        return
    end

    if item:HasTag("oinc") then
        ScheduleOincSoundEvent(inst, item.components.stackable and (- item.components.stackable:StackSize()) or - 1)

        if item.oinc_sound_stackchange_listener then
            item:RemoveEventCallback("stacksizechange", item.oinc_sound_stackchange_listener)
            item.oinc_sound_stackchange_listener = nil
        end
    end
end


local function OnDeath(inst, data)
    if inst.components.poisonable ~= nil then
        inst.components.poisonable:SetBlockAll(true)
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable(true)
    end
end

local function OnRespawnFromGhost(inst, data)
    if inst.components.poisonable ~= nil and not inst:HasTag("beaver") then
        inst.components.poisonable:SetBlockAll(false)
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:OnHayFever(TheWorld.state.ishayfever, true, true)
    end
end

local function OnLoad(inst, data, ...)
    if data ~= nil then
        if data.is_ghost then
            --blockPoison(inst)
        end
    end
    -- Well this really sucks, thanks for making my life hell klei :) (I blame Zarklord specifically because funi)
    local _DoTaskInTime = inst.DoTaskInTime
    function inst:DoTaskInTime(time, fn, ...)
        return _DoTaskInTime(self, time, fn ~= nil and function(...)
            local _enabled = nil
            local _drownable = inst:CanOnWater(true) and inst.components.drownable or nil
            if _drownable then
                _enabled = _drownable.enabled
                _drownable.enabled = false
            end
            local _rets = {fn(...)}
            if _drownable then
                _drownable.enabled = _enabled
            end
            return unpack(_rets)
        end or nil, ...)
    end
    local rets = {inst.__OnLoad(inst, data, ...)}
    inst.DoTaskInTime = _DoTaskInTime
    return unpack(rets)
end

local SANITY_MODIFIER_NAME = "PLAYERHOUSE_SANITY"

local function UpdateInteriorSanity(inst, data)
    if data.from then
        inst.components.sanity.externalmodifiers:RemoveModifier(data.from, SANITY_MODIFIER_NAME) -- remove sanity from whichever room we were
    end

    if data.to then -- still inside
        local interiorID = data.to.interiorID
        if TheWorld.components.interiorspawner:GetInteriorDefinition(interiorID).dungeon_name:find("playerhouse") then
            inst.components.sanity.externalmodifiers:SetModifier(data.to, TUNING.SANITY_PLAYERHOUSE_GAIN, SANITY_MODIFIER_NAME)
        end
    end
end

local function UpdateHomeTechBonus(inst, data)
    if data.to and data.to:HasInteriorTag("home_prototyper") then
        inst.components.builder.home_bonus = 2
    else
        inst.components.builder.home_bonus = 0
    end
end

local function OnInteriorChange(inst, data)
    UpdateInteriorSanity(inst, data)
    UpdateHomeTechBonus(inst, data)
end

AddPlayerPostInit(function(inst)
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, function()
            if inst == ThePlayer then -- only do this for the local player character
                inst:ListenForEvent("oincsounddirty", PlayOincSound)
                if TheWorld:HasTag("porkland") then
                    inst:AddComponent("windvisuals")
                    inst:AddComponent("cloudpuffmanager")
                    inst:AddComponent("persistencevision")
                end
            end
        end)
    end

    inst._oinc_sound = net_byte(inst.GUID, "player._oincsoundpush", "oincsounddirty")

    if inst.components.hudindicatable then
        local _shouldtrackfn = inst.components.hudindicatable.shouldtrackfn
        local function ShouldTrackfn(inst, viewer, ...)
            return _shouldtrackfn(inst, viewer, ...)
                and inst:IsNear(viewer, TUNING.MAX_INDICATOR_RANGE * 1.5)
        end
        inst.components.hudindicatable:SetShouldTrackFunction(ShouldTrackfn)
    end

    local _OnSetOwner = inst:GetEventCallbacks("setowner", inst, "scripts/prefabs/player_common.lua")
    local _RegisterActivePlayerEventListeners = ToolUtil.GetUpvalue(_OnSetOwner, "RegisterActivePlayerEventListeners")

    local function RegisterActivePlayerEventListeners(inst)
        _RegisterActivePlayerEventListeners(inst)
        if inst._PICKUPSOUNDS then
            for k, v in pairs(inst._PICKUPSOUNDS) do
                inst._PICKUPSOUNDS[k] = "dontstarve/HUD/collect_resource"
            end
        end
    end

    ToolUtil.SetUpvalue(_OnSetOwner, RegisterActivePlayerEventListeners, "RegisterActivePlayerEventListeners")

    local _OnGotNewItem, i = ToolUtil.GetUpvalue(_RegisterActivePlayerEventListeners, "OnGotNewItem")

    local function OnGotNewItem(inst, data, ...)
        if TheWorld:HasTag("porkland") then
            if data.slot ~= nil or data.eslot ~= nil or data.toactiveitem ~= nil then
                if inst.replica.sailor and inst.replica.sailor:GetBoat() then
                    TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_water_collect_resource")
                    return
                end
            end
        end
        return _OnGotNewItem(inst, data, ...)
    end

    if i then
        debug.setupvalue(_RegisterActivePlayerEventListeners, i, OnGotNewItem)
    end

    local REPLACE_ANIMS =
    {
        -- ["atk_pre"] = "atk_pre_old",
        -- ["atk_lag"] = "atk_lag_old",
        -- ["atk"] = "atk_old",
        ["hit"] = "hit_old",
        ["hit_goo"] = "hit_goo_old",
    }

    local wilson_bank_hash = inst.AnimState:GetBankHash()

    local _AnimState = inst.AnimState
    local AnimState = setmetatable({}, {__index = function(t, k)
        if k == "PlayAnimation" then
            return function(t, animname, ...)
                if _AnimState:GetBankHash() == wilson_bank_hash and REPLACE_ANIMS[animname] then
                    return _AnimState:PlayAnimation(REPLACE_ANIMS[animname], ...)
                else
                    return _AnimState:PlayAnimation(animname, ...)
                end
            end
        elseif k == "PushAnimation" then
            return function(t, animname, ...)
                if _AnimState:GetBankHash() == wilson_bank_hash and REPLACE_ANIMS[animname] then
                    return _AnimState:PushAnimation(REPLACE_ANIMS[animname], ...)
                else
                    return _AnimState:PushAnimation(animname, ...)
                end
            end
        end

        return function(t, ...)
            return _AnimState[k](_AnimState, ...)
        end
    end})
    rawset(inst, "AnimState", AnimState)

    inst.components.lightwatcherproxy:UseHighPrecision()

    if not TheWorld.ismastersim then
        return
    end

    if not inst.components.hayfever then
        inst:AddComponent("hayfever")
    end

    inst:AddComponent("interiorvisitor")
    inst:AddComponent("sailor")

    inst:AddComponent("infestable")

    inst:AddComponent("shopper")

    inst:AddComponent("uniqueidentity")

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    inst:ListenForEvent("enterinterior", OnInteriorChange)
    inst:ListenForEvent("leaveinterior", OnInteriorChange)

    if inst.OnLoad then
        inst.__OnLoad = inst.OnLoad
        inst.OnLoad = OnLoad
    end

end)
