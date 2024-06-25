local assets =
{
    Asset("ANIM", "anim/ruins_blow_dart.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins_blue.zip"),
}

local prefabs =
{

}

local function OnCollide(inst, other)
    if other and other.prefab ~= inst.prefab then
        inst.components.combat:DoAttack(other, nil, nil, nil, nil) --2*25 dmg

        local x, y, z = inst.Transform:GetWorldPosition()
        local impactfx = SpawnPrefab("impact")
        impactfx:FacePoint(x, y, z)

        local fx = SpawnPrefab("circle_puff_fx")
        fx.Transform:SetPosition(x,y,z)
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, 0.5)

    inst.AnimState:SetBank("dart")
    inst.AnimState:SetBuild("ruins_blow_dart")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetEightFaced()

    inst:AddTag("projectile")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.PIG_RUINS_DART_DAMAGE)

    return inst
end

local function UpdateArt(inst)
    local anim = inst.animframe
    if not inst.components.disarmable.armed then
        anim = anim .."_disarmed"
    end
    inst.AnimState:PlayAnimation(anim)
end

local function OnSave(inst, data)
    if inst.animframe then
        data.animframe = inst.animframe
    end
end

local function OnLoad(inst, data)
    if data.animframe then
        inst.animframe = data.animframe
    end

    inst:DoTaskInTime(0, UpdateArt)
end

local function LaunchDart(inst, angle, xmod, zmod)
    inst:DoTaskInTime(math.random() * 0.6, function()
        local x, y, z = inst.Transform:GetWorldPosition()

        local projectile = SpawnPrefab("pig_ruins_dart")
        projectile.Transform:SetPosition(x + xmod, y, z + zmod)
        projectile.Transform:SetRotation(angle)
        projectile.Physics:SetMotorVel(30, 0, 0)
        projectile.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/blowdart_fire")

        local fx = SpawnPrefab("circle_puff_fx")
        if fx then
            local follower = fx.entity:AddFollower()
            follower:FollowSymbol(inst.GUID, "fx_marker", 0, 0, 0)
        end
    end)
end

local function Shoot(inst)
    if not inst.components.disarmable.armed then
        return
    end

    if inst:HasTag("dartthrower_left") then
        LaunchDart(inst, -90, 0, 2)
    elseif inst:HasTag("dartthrower_right") then
        LaunchDart(inst, 90, 0, -2)
    elseif inst:HasTag("dartthrower") then
        LaunchDart(inst, 0, 2, 0)
    end
end

local function Disarm(inst, doer)
    local pt = inst:GetPosition()
    inst.components.lootdropper:SpawnLootPrefab("blowdart_pipe", pt)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/disarm_wall")
    UpdateArt(inst)
end

local function MakeDart(name, build, bank, animframe, facing)
    local function dartfn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(animframe)
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(1)

        inst.Transform:SetRotation(-90)

        inst:AddTag("dartthrower")

        if facing == "left" then
            inst.AnimState:SetScale(-1, 1, 1)
            inst:AddTag("dartthrower_right")
        end
        if facing == "right" then
            inst:AddTag("dartthrower_left")
        end

        inst.name = STRINGS.NAMES.PIG_RUINS_DART_TRAP

        inst:AddComponent("rotatingbillboard")
        inst.components.rotatingbillboard.animdata = {
            bank = bank,
            build = build,
            animation = animframe,
        }

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "pig_ruins_dart_trap"

        inst:AddComponent("disarmable")
        inst.components.disarmable.disarmfn = Disarm

        inst:AddComponent("lootdropper")

        inst:AddComponent("hiddendanger")
        inst.components.hiddendanger.offset = {x = 0, y = 1.7, z = 0}

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.shoot = Shoot

        inst.setbackground = 1
        inst.animframe = animframe

        UpdateArt(inst)

        return inst
    end

    return Prefab(name, dartfn, assets, prefabs)
end

return  Prefab("pig_ruins_dart", fn, assets, prefabs),
        MakeDart("pig_ruins_pigman_relief_dart1", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_confused", "down"),
        MakeDart("pig_ruins_pigman_relief_dart2", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_happy", "down"),
        MakeDart("pig_ruins_pigman_relief_dart3", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_surprise", "down"),
        MakeDart("pig_ruins_pigman_relief_dart4", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_head", "down"),

        MakeDart("pig_ruins_pigman_relief_leftside_dart", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_sidewall", "right"),
        MakeDart("pig_ruins_pigman_relief_rightside_dart", "interior_wall_decals_ruins", "interior_wall_decals_ruins", "relief_sidewall", "left"),

        MakeDart("pig_ruins_pigman_relief_dart1_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_confused", "down"),
        MakeDart("pig_ruins_pigman_relief_dart2_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_happy", "down"),
        MakeDart("pig_ruins_pigman_relief_dart3_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_surprise", "down"),
        MakeDart("pig_ruins_pigman_relief_dart4_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_head", "down"),

        MakeDart("pig_ruins_pigman_relief_leftside_dart_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_sidewall", "right"),
        MakeDart("pig_ruins_pigman_relief_rightside_dart_blue", "interior_wall_decals_ruins_blue", "interior_wall_decals_ruins", "relief_sidewall", "left")
