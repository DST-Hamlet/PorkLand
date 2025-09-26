local assets = {
    Asset("ANIM", "anim/daywalker_pillar.zip"),
}

local prefabs = {
    "statue_transition_2",
}

local START_CHAIN_RANGE = 4
local STOP_CHAIN_RANGE = 8

local BreakChain, DoChainTask

BreakChain = function(inst)

    if inst._pull_task then
        inst._pull_task:Cancel()
    end

    if inst._target and inst._target:IsValid() and inst._target.components.physicsmodifiedexternally then
        inst._target.components.physicsmodifiedexternally:RemoveSource(inst)
    end

    inst:RemoveEventCallback("death", BreakChain)
    inst:RemoveEventCallback("death", BreakChain, inst._target)
    inst:RemoveEventCallback("remove", BreakChain, inst._target)
    inst._target = nil

    if not inst.components.health:IsDead() then
        inst._chain_task = inst:DoPeriodicTask(0.1, DoChainTask)
    end
end

-- 限制生物的接口
local function DoPullTask(inst)
    local target = inst._target
    if not target or not target:IsValid() then
        return
    end

    local x, _, z = inst.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()

    local distsq = (x-tx)^2 + (z-tz)^2
    if distsq < STOP_CHAIN_RANGE * STOP_CHAIN_RANGE then -- 检测是否在范围内
        return
    end

    -- 一定范围外才拉进来
    -- 或许该写个一定范围外扯断
    if distsq >= START_CHAIN_RANGE * START_CHAIN_RANGE then
        local scale = (target:HasTag("smallcreature") and 3) or (target:HasTag("largecreature") and 1) or 2 -- 这里用的标签检测生物大小
        local angle = inst:GetAngleToPoint(tx, 0, tz)
        local velx, velz = (scale) * math.cos(angle * DEGREES), (scale) * math.sin(angle * DEGREES)

        target.components.physicsmodifiedexternally:SetVelocityForSource(inst, velx, velz) -- 施加一个朝向柱子的速度向量
        target.components.combat:GetAttacked(inst, 10) -- 拉仇恨
    else
        target.components.physicsmodifiedexternally:SetVelocityForSource(inst, 0, 0)
    end
end

local CHAIN_MUST_TAGS = {"_combat"}
local CHAIN_ONEOF_TAGS = {"character", "animal", "monster", "insect", "smallcreature", "largecreature"}
local CHAIN_NO_TAGS = {"INLIMBO", "player", "bird"}
DoChainTask = function(inst)
    local ent = FindClosestEntity(inst, START_CHAIN_RANGE, true, CHAIN_MUST_TAGS, CHAIN_NO_TAGS, CHAIN_ONEOF_TAGS)
    if not ent then
        return
    end

    inst._target = ent

    local x, y, z = inst._target.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2") -- placeholder fx for chain
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 2, 1)
    end

    if inst._chain_task then
        inst._chain_task:Cancel()
    end

    if not inst._target.components.physicsmodifiedexternally then
        inst._target:AddComponent("physicsmodifiedexternally")
    end
    inst._target.components.physicsmodifiedexternally:AddSource(inst)
    inst._pull_task = inst:DoPeriodicTask(1, DoPullTask)
    inst:ListenForEvent("remove", BreakChain, inst._target)
    inst:ListenForEvent("death", BreakChain, inst._target)
    inst:ListenForEvent("death", BreakChain)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("daywalker_pillar")
	inst.AnimState:SetBuild("daywalker_pillar")
	inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1, 1, 1, 0.2)

    inst.Transform:SetScale(0.5, 0.5, 0.5)

    inst:AddTag("waxwell_pillar")
    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(150)
    inst.components.health:StartRegen(-1, 1)

    inst.persists = false

    inst._chain_task = inst:DoPeriodicTask(0.1, DoChainTask)

    inst:ListenForEvent("death", function()
        inst.AnimState:PlayAnimation("pillar_fall")
    end)

    c_showradius({START_CHAIN_RANGE * TILE_SCALE, STOP_CHAIN_RANGE * TILE_SCALE}, inst)

    return inst
end

return Prefab("waxwell_pillar", fn, assets, prefabs)
