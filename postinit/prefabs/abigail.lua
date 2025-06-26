local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local auratest = nil

local function FreezeMovements(inst, should_freeze)
    inst._playerlink:AddOrRemoveTag("has_movements_frozen_follower", should_freeze)
    inst:AddOrRemoveTag("movements_frozen", should_freeze)
end

local function OnGotoCommand(inst, data)
    local position = data.position
    if position == nil then
        return
    end
    inst._goto_position = position
    inst:_OnHauntTargetRemoved()
    inst:_OnNextHauntTargetRemoved()
end

local HAUNT_CANT_TAGS = {"catchable", "DECOR", "FX", "haunted", "INLIMBO", "NOCLICK"}
local function DoGhostHauntTarget(inst, data)
    local target = data.target
    if target == nil then
        return
    end
    if (inst.sg and inst.sg:HasStateTag("nocommand"))
            or (inst.components.health and inst.components.health:IsDead()) then
        return
    end

    for _, cant_tag in pairs(HAUNT_CANT_TAGS) do
        if target:HasTag(cant_tag) then
            return
        end
    end

    inst._next_haunt_target = target
    inst._goto_position = nil
    inst:ListenForEvent("onremove", inst._OnNextHauntTargetRemoved, inst._next_haunt_target)
end

AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("do_ghost_haunt_target", DoGhostHauntTarget)
    inst:ListenForEvent("do_ghost_goto_position", OnGotoCommand)
    inst.FreezeMovements = FreezeMovements
    inst.OnGotoCommand = OnGotoCommand

    local link_to_player = inst.LinkToPlayer
    inst.LinkToPlayer = function(inst, ...)
        local ret = { link_to_player(inst, ...) }
        FreezeMovements(inst, false)
        return unpack(ret)
    end

    inst._OnNextHauntTargetRemoved = function()
        if inst._next_haunt_target then
            inst:RemoveEventCallback("onremove", inst._OnNextHauntTargetRemoved, inst._next_haunt_target)
            inst._next_haunt_target = nil
        end
    end

    inst._SetNewHauntTarget = function()
        inst:_OnHauntTargetRemoved()
        if inst._next_haunt_target and inst._next_haunt_target:IsValid() then
            inst._haunt_target = inst._next_haunt_target
            inst:ListenForEvent("onremove", inst._OnHauntTargetRemoved, inst._haunt_target)
        end
        inst:_OnNextHauntTargetRemoved()
    end

    local _BecomeAggressive = inst.BecomeAggressive
    inst.BecomeAggressive = function(inst, ...)
        _BecomeAggressive(inst, ...)
        local _Retarget = inst.components.combat.targetfn
        local function Retarget(...)
            local rets = {_Retarget(...)}
            if rets[1] then
                rets[2] = true -- 强制转移仇恨目标
            end
            return unpack(rets)
        end
        inst.components.combat:SetRetargetFunction(0.01, Retarget) -- 增加阿比的响应频率
    end

    local _BecomeDefensive = inst.BecomeDefensive
    inst.BecomeDefensive = function(inst, ...)
        _BecomeDefensive(inst, ...)
        local _Retarget = inst.components.combat.targetfn
        local function Retarget(...)
            local rets = {_Retarget(...)}
            if rets[1] then
                rets[2] = true -- 强制转移仇恨目标
            end
            return unpack(rets)
        end
        inst.components.combat:SetRetargetFunction(0.01, Retarget) -- 增加阿比的响应频率
    end
end)
