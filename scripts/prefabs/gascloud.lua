local assets =
{
    Asset("ANIM", "anim/cropdust_fx.zip"),
}

local function Spawn(inst)
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:PushAnimation("idle_loop", true)
end

local function Despawn(inst)
    inst.AnimState:PlayAnimation("disappear")
    -- should probably disable DynamicShadow here
    inst:ListenForEvent("animover", function()
        for _, ent in ipairs(inst.ents_in_gas) do
            StopTakingGasDamage(ent)
        end
        inst:Remove()
    end)
    inst.persists = false
end

local START_RANGE = 2
local END_RANGE = 2.2
local DO_GAS_ONE_OF_TAGS = {"animal", "character", "monster", "insect"}
local DO_GAS_NO_TAGS = {"gas", "INLIMBO"}

local function OnUpdate(inst, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    local new_ents = TheSim:FindEntities(x, y, z, START_RANGE, nil, DO_GAS_NO_TAGS, DO_GAS_ONE_OF_TAGS)

    local old_ents = inst.ents_in_gas
    local num_old_ents = #old_ents

    inst.ents_in_gas = new_ents

    for _, ent in ipairs(inst.ents_in_gas) do
        local was_in_gas = false

        for i = 1, num_old_ents do -- don't use pairs for this
            if old_ents[i] == ent then
                was_in_gas = true
                old_ents[i] = nil
                break
            end
        end

        if not was_in_gas then
            if ent.OnGasChange then -- gnat
                ent:OnGasChange()
                return
            end
            StartTakingGasDamage(ent)
        end
    end

    for _, ent in ipairs(old_ents) do
        StopTakingGasDamage(ent)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cropdust_fx")
    inst.AnimState:SetBuild("cropdust_fx")
    inst.AnimState:PlayAnimation("idle_loop",true)
    inst.AnimState:SetRayTestOnBB(true)

    inst.DynamicShadow:SetSize(2.5, 1.5)

    inst.Transform:SetFourFaced()

    inst:AddTag("gas")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("creatureprox")
    inst.components.creatureprox:SetDist(START_RANGE, END_RANGE)
    inst.components.creatureprox:SetOnUpdate(OnUpdate)
    inst.components.creatureprox:Schedule(0.01)

    inst:AddComponent("inspectable")

    inst:DoTaskInTime(20, Despawn)

    inst.ents_in_gas = {}

    inst.Spawn = Spawn

    return inst
end

return Prefab("gascloud", fn, assets)
