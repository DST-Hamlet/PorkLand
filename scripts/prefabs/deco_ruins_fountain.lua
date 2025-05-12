local assets =
{
    Asset("ANIM", "anim/pig_ruins_well.zip"),
}

local prefabs =
{

}

local function ShouldAcceptItem(inst, item)
    if item:HasTag("irreplaceable") then
        return false
    end

    if inst:HasTag("vortex") then
        return true
    end

    return item.components.currency or item.prefab == "goldnugget"
end

local item_values = {
    oinc = 1, -- 4%
    oinc10 = 10, -- 40%
    oinc100 = 100, -- 100%
    goldnugget = 20, -- 80%
    dubloon = 5, -- 20%
}

local function OnGetItemFromPlayer_Wishing(inst, giver, item)
    local value = item_values[item.prefab] or 0

    inst.AnimState:PlayAnimation("splash")
    inst.AnimState:PushAnimation("idle_full", true)

    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/item_sink")

    inst:DoTaskInTime(1, function()
        if math.random() < (value / 25) then
            if giver.components.poisonable and giver.components.poisonable.poisoned then
                giver.components.poisonable:Cure(inst)
            end
            if giver.components.health and giver.components.health:GetPercent() < 1 then
                giver.components.health:DoDelta(value * 5, false, inst.prefab)
                giver:PushEvent("celebrate")
            end
        end
    end)
end

local function OnGetItemFromPlayer_Vortex(inst, giver, item)
    inst.AnimState:PlayAnimation("vortex_splash")
    inst.AnimState:PushAnimation("vortex_idle_full",true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/endswell/splash")

    local value = 1
    if item.prefab == "nightmarefuel" then
        value = 100
    elseif item.prefab == "redgem" or item.prefab == "bluegem" or item.prefab == "orangegem" or item.prefab == "yellowgem" or item.prefab == "greengem" then
        value = 50
    end

    value = value + math.random() * 100

    inst:DoTaskInTime(1, function()
        local gems = 0
        if value < 100 then
            if math.random() <= 0.6 then
                SpawnAt("crawlingnightmare", inst)
            else
                SpawnAt("nightmarebeak", inst)
            end
        elseif value < 150 then
            gems = 1
        elseif value < 200 then
            gems = 3
        end

        if gems <= 0 then
            return
        end

        inst.AnimState:PlayAnimation("vortex_splash")
        inst.AnimState:PushAnimation("vortex_idle_full", true)
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/endswell/splash")

        for i = 1, gems do
            local spawn_point = inst:GetPosition() + Vector3(0, 4.5, 0)
            local x, y, z = spawn_point:Get()
            local angle = (math.random() * 360) * DEGREES
            if giver ~= nil and giver:IsValid() then
                angle = 180 - giver:GetAngleToPoint(x, 0, z)
            end

            local speed = math.random() * 4 + 2

            local gem = SpawnPrefab("purplegem")
            gem.Transform:SetPosition(x, y, z)
            gem.components.inventoryitem:Launch(Vector3(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle)))
            -- gem.components.inventoryitem:OnStartFalling()
        end
    end)
end

local function OnSave(inst, data)
    data.rotation = inst.Transform:GetRotation()

    if inst.animdata then
        data.animdata = inst.animdata
    end
end

local function OnLoad(inst, data)
    if not data then
        return
    end

    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end

    if data.animdata then
        inst.animdata = data.animdata
        if inst.animdata.build then
            inst.AnimState:SetBuild(inst.animdata.build)
        end
        if inst.animdata.bank then
            inst.AnimState:SetBank(inst.animdata.bank)
        end
        if inst.animdata.anim then
            inst.AnimState:PlayAnimation(inst.animdata.anim, inst.animdata.animloop)
        end
    end
end

local function MakeFountain(name, build, bank, animframe, is_vortex)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddPhysics()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild(build)
        inst.AnimState:SetBank(bank)
        inst.AnimState:PlayAnimation(animframe, true)
        inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())

        inst.Transform:SetTwoFaced()

        inst.Physics:SetMass(0)
        inst.Physics:SetCapsule(2, 1)
        inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)

        inst.MiniMapEntity:SetIcon("pig_ruins_well.tex")

        if is_vortex then
            inst:AddTag("vortex")
            inst:DoTaskInTime(0, function()
                inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/endswell/hum_LP", "doom")
            end)
            inst.MiniMapEntity:SetIcon("pig_ruins_well_vortex.tex")
        end

        inst:AddTag("blocker")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("trader")
        inst.components.trader.acceptnontradable = true
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = is_vortex and OnGetItemFromPlayer_Vortex or OnGetItemFromPlayer_Wishing

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return  MakeFountain("deco_ruins_fountain", "pig_ruins_well", "pig_ruins_well", "idle_full", false),
        MakeFountain("deco_ruins_endswell", "pig_ruins_well", "pig_ruins_well", "vortex_idle_full", true)
