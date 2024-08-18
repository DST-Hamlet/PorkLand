
local assets =
{
    Asset("ANIM", "anim/cave_exit_rope.zip"),
    Asset("ANIM", "anim/vine01_build.zip"),
    Asset("ANIM", "anim/vine02_build.zip"),
}

local assets_fx = {
    Asset("ANIM", "anim/vine01_break_fx.zip"),
    Asset("ANIM", "anim/vine02_break_fx.zip"),
}

local prefabs =
{
    "grabbing_vine",
}

local function OnNear(inst)
    if not inst.near then
        inst.near = true
        inst:RemoveTag("fireimmune")
        inst.AnimState:PlayAnimation("down")
        inst.AnimState:PushAnimation("idle_loop", true)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/drop")
        inst.DynamicShadow:SetSize(1.5, .75)
    end
end

local function OnFar(inst)
    if not inst.components.burnable:IsBurning() and inst.near then
        inst.near = false
        inst:AddTag("fireimmune")
        inst.AnimState:PlayAnimation("up")
        inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
        inst.DynamicShadow:SetSize(0, 0)
    end
end

local function OnExtinguish(inst)
    if not inst:IsNearPlayer(16) then
        OnFar(inst)
    end
end

local function OnRemoveEntity(inst)
    local fx = SpawnPrefab(inst.vine .. "_break_fx")
    if fx then
        local x, y, z = inst.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x, y, z)
    end
    if inst.spawn_patch then
        inst.spawn_patch:SpawnNewVine(inst.prefab, inst.GUID)
    end
end

local function OnSave(inst, data)
    local ents = {}
    if inst.spawn_patch then
        data.spawn_patch = inst.spawn_patch.GUID
        table.insert(ents, inst.spawn_patch.GUID)
    end
    return ents
end

local function LoadPostPass(inst, ents, data)
    if data and data.spawn_patch then
        local spawn_patch = ents[data.spawn_patch]
        if spawn_patch then
            inst.spawn_patch = spawn_patch.entity
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(0, 0)

    inst:AddTag("hangingvine")
    inst:AddTag("veggie")

    inst.vine = math.random() < 0.5 and "vine01" or "vine02"
    inst.AnimState:SetBuild(inst.vine .. "_build")
    inst.AnimState:SetBank("exitrope")
    inst.AnimState:PlayAnimation("up")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetDist(10, 16)

    inst:AddComponent("shearable")
    inst.components.shearable:SetUp("rope", 1)
    inst.components.shearable:SetOnShearFn(inst.Remove)

    inst.OnSave = OnSave
    inst.LoadPostPass = LoadPostPass
    inst.OnRemoveEntity = OnRemoveEntity

    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetBurnTime(10)
    inst.components.burnable:AddBurnFX("fire", Vector3(0, 20, 0), "swap_fire", true) -- 出于未知原因，如果不加第四个参数，那么冒烟特效就会消失
    inst.components.burnable:SetOnExtinguishFn(OnExtinguish)
    inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    return inst
end

local function MakeBreakFX(vine)
    local function fx_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild(vine .. "_break_fx")
        inst.AnimState:SetBank("exitrope")
        inst.AnimState:PlayAnimation("break")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")

        inst:AddTag("FX")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:DoTaskInTime(0.05, function() inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds") end)
        inst:DoTaskInTime(0.10, function() inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds") end)
        inst:DoTaskInTime(0.15, function() inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds") end)
        inst:DoTaskInTime(0.20, function() inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds") end)

        inst:ListenForEvent("animover", inst.Remove)
        inst:ListenForEvent("entitysleep", inst.Remove)

        inst.persists = false

        return inst
    end

    return Prefab(vine .. "_break_fx", fx_fn, assets_fx)
end

return Prefab("hanging_vine", fn, assets, prefabs),
    MakeBreakFX("vine01"),
    MakeBreakFX("vine02")
