local assets = {

}

local prefabs = {

}

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "playerghost", "INLIMBO" }
local function RetargetFn(inst)
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil
        and FindEntity(leader, TUNING.SHADOWWAXWELL_TARGET_DIST, function(guy)
            return guy ~= inst and (guy.components.combat:TargetIs(leader) or guy.components.combat:TargetIs(inst)) and inst.components.combat:CanTarget(guy)
        end,
        RETARGET_MUST_TAGS,
        RETARGET_CANT_TAGS) or nil
end

local function KeepTargetFn(inst, target)
    return inst.components.follower:IsNearLeader(14) and inst.components.combat:CanTarget(target)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * 0.5)
    inst.components.health:StartRegen(1, 1)
    inst.components.health.nofadeout = true

    inst:AddComponent("combat")
    inst.components.combat:SetRange(2)
    inst.components.combat:SetDefaultDamage(27)
    inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, RetargetFn) --Look for leader's target.
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn) --Keep attacking while leader is near.
    inst.components.combat.hiteffectsymbol = "torso"

    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true
    inst.components.follower.keepleaderduringminigame = true

    inst._current_task = nil
    inst._queued_task = nil

    return inst
end

return Prefab("waxwell_minion", fn, assets, prefabs)

