local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function PlayOincSound(inst)
    local transaction_amount = inst._oinc_sound:value()
    if transaction_amount == 0 then
        return
    end
    if transaction_amount == 1 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/1")
    elseif transaction_amount == 2 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/2")
    else
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/coins/3_plus")
    end
    inst._oinc_sound:set_local(0)
end

local function ScheduleOincSoundEvent(inst, amount)
    if not inst.oinc_transaction then
        inst.oinc_transaction = 0
    end
    inst.oinc_transaction = inst.oinc_transaction + amount
    if not inst.oinc_transaction_task then
        inst.oinc_transaction_task = inst:DoTaskInTime(0, function()
            inst._oinc_sound:set(inst.oinc_transaction)
            inst.oinc_transaction = nil
            inst.oinc_transaction_task = nil
        end)
    end
end

local function OnItemGet(inst, data)
    local item = data.item
    if not item or not item:HasTag("oinc") then
        return
    end

    ScheduleOincSoundEvent(inst, item.components.stackable and item.components.stackable:StackSize() or 1)

    item.oinc_sound_stackchange_listener = function(_, data)
        local amount_changed = math.abs(data.stacksize - data.oldstacksize)
        ScheduleOincSoundEvent(inst, amount_changed)
    end
    item:ListenForEvent("stacksizechange", item.oinc_sound_stackchange_listener)
end

local function OnItemLose(inst, data)
    local item = data.prev_item
    if not item or not item:HasTag("oinc") then
        return
    end

    ScheduleOincSoundEvent(inst, item.components.stackable and item.components.stackable:StackSize() or 1)

    if item.oinc_sound_stackchange_listener then
        item:RemoveEventCallback("stacksizechange", item.oinc_sound_stackchange_listener)
        item.oinc_sound_stackchange_listener = nil
    end
end

local function OnDeath(inst, data)
    if inst.components.poisonable ~= nil then
        inst.components.poisonable:SetBlockAll(true)
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable()
    end
end

local function OnRespawnFromGhost(inst, data)
    if inst.components.poisonable ~= nil and not inst:HasTag("beaver") then
        inst.components.poisonable:SetBlockAll(false)
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:OnHayFever(TheWorld.state.ishayfever)
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
    local rets = {inst.Pl_OnLoad(inst, data, ...)}
    inst.DoTaskInTime = _DoTaskInTime
    return unpack(rets)
end

AddPlayerPostInit(function(inst)
    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, function()
            if inst == ThePlayer then -- only do this for the local player character
                inst:ListenForEvent("oincsounddirty", PlayOincSound)
                if TheWorld:HasTag("porkland") then
                    inst:AddComponent("windvisuals")
                end
            end
        end)
    end

    local _IsInLight = inst.IsInLight
    function inst:IsInLight()
        if inst:HasTag("inside_interior") then
            local pos = inst:GetPosition()
            return TheSim:GetLightAtPoint(pos.x, pos.y, pos.z, 0.1) > 0.1
        else
            return _IsInLight(self)
        end
    end

    inst._oinc_sound = net_byte(inst.GUID, "player._oincsoundpush", "oincsounddirty")

    if not TheWorld.ismastersim then
        return
    end

    if not inst.components.hayfever then
        inst:AddComponent("hayfever")
    end

    inst:AddComponent("interiorvisitor")
    inst:AddComponent("sailor")

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)

    inst:ListenForEvent("itemget", OnItemGet)
    inst:ListenForEvent("itemlose", OnItemLose)

    if inst.OnLoad then
        inst.Pl_OnLoad = inst.OnLoad
        inst.OnLoad = OnLoad
    end
end)
