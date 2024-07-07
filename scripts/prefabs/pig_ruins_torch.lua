local assets =
{
    Asset("ANIM", "anim/ruins_torch.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins_blue.zip"),
}

local prefabs =
{
    "campfirefire"
}

local PIG_WRITING_MUST_TAGS = {"pig_writing_1"}

local function OnIgnite(inst)
    if not inst.components.cooker then
        inst:AddComponent("cooker")
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 50, PIG_WRITING_MUST_TAGS)
    for _, ent in pairs(ents) do
        ent:PushEvent("fire_lit")
    end
end

local function OnExtinguish(inst)
    if inst.components.cooker then
        inst:RemoveComponent("cooker")
    end
    if inst.components.fueled then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function OnTakeFuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function UpdateFuelRate(inst)
    local rate = 1
    if TheWorld.state.israining and not inst.components.rainimmunity then
        rate = rate + TUNING.FIREPIT_RAIN_RATE * (TheWorld.state.precipitationrate or 1)
    end
    if TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy() then
        rate = rate + TheWorld.net.components.plateauwind:GetWindSpeed() * TUNING.FIREPIT_WIND_RATE
    end
    if inst:GetCurrentInteriorID() ~= nil then
        rate = 1
    end
    inst.components.fueled.rate = rate
end

local function FueledUpdateFn(inst)
    UpdateFuelRate(inst)
    inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
end

local function FueledSectionCallback(new_section, old_section, inst)
    if new_section == 0 then
        inst.components.burnable:Extinguish()
    else
        if not inst.components.burnable:IsBurning() then
            inst.components.burnable:Ignite()
        end

        inst.components.burnable:SetFXLevel(new_section, inst.components.fueled:GetSectionPercent())
    end
end

local status = {"OUT", "EMBERS", "LOW", "NORMAL", "HIGH"}

local function GetStatus(inst)
    local section = inst.components.fueled:GetCurrentSection()
    return status[section + 1]
end

local function OnHaunt(inst)
    if inst.components.fueled ~= nil and
        inst.components.fueled.accepting and
        math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        inst.components.fueled:DoDelta(TUNING.TINY_FUEL)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()
    if inst.flipped then
        data.flipped = inst.flipped
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end

    if data.flipped then
        inst.flipped = data.flipped
        local rx, ry, rz = inst.Transform:GetScale()
        inst.Transform:SetScale(rx, ry, -rz)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ruinstorch")
    inst.AnimState:SetBuild("ruins_torch")
    inst.AnimState:PlayAnimation("idle")

    MakeObstaclePhysics(inst, 0.2)

    inst:AddTag("campfire")
    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("propagator")

    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0), "fire_marker")

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(4)
    inst.components.fueled.ontakefuelfn = OnTakeFuel
    inst.components.fueled:SetUpdateFn(FueledUpdateFn)
    inst.components.fueled:SetSectionCallback(FueledSectionCallback)
    inst.components.fueled:InitializeFuelLevel(0)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onextinguish", OnExtinguish)
    inst:ListenForEvent("onignite", OnIgnite)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function pillarfn()
    local inst = fn()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("ruins_torch.tex")

    return inst
end

local function wallfn()
    local inst = fn()

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)

    inst:AddTag("wall_torch")

    inst.AnimState:SetBank("interior_wall_decals_ruins")
    inst.AnimState:SetBuild("interior_wall_decals_ruins")
    inst.AnimState:PlayAnimation("sconce_front")

    return inst
end

local function sidewallfn()
    local inst = fn()

    local anim_data = {
        bank = "interior_wall_decals_ruins",
        build = "interior_wall_decals_ruins",
        animation = "sconce_sidewall",
    }

    inst.AnimState:SetBank(anim_data.bank)
    inst.AnimState:SetBuild(anim_data.build)
    inst.AnimState:PlayAnimation(anim_data.animation)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetTwoFaced()

    inst:AddTag("wall_torch")

    --inst:AddComponent("rotatingbillboard") --由于rotatingbillboard会导致火焰效果出现问题，因此暂时禁用这部分功能
    --inst.components.rotatingbillboard.animdata = anim_data

    inst:SetPrefabNameOverride("pig_ruins_torch_wall")

    return inst
end

local function wallbluefn()
    local inst = wallfn()
    inst:SetPrefabNameOverride("pig_ruins_torch_wall")
    inst.AnimState:SetBuild("interior_wall_decals_ruins_blue")
    return inst
end

local function sidewallbluefn()
    local inst = sidewallfn()
    inst.AnimState:SetBuild("interior_wall_decals_ruins_blue")
    return inst
end

return  Prefab("pig_ruins_torch", pillarfn, assets, prefabs),
        Prefab("pig_ruins_torch_wall", wallfn, assets, prefabs),
        Prefab("pig_ruins_torch_sidewall", sidewallfn, assets, prefabs),
        Prefab("pig_ruins_torch_wall_blue", wallbluefn, assets, prefabs),
        Prefab("pig_ruins_torch_sidewall_blue", sidewallbluefn, assets, prefabs)
