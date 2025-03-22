--[[
birds.lua

Different birds are just reskins of crow without any special powers at the moment.
To make a new bird add it at the bottom of the file as a 'makebird(name)' call

This assumes the bird already has a build, inventory icon, sounds and a feather_name prefab exists, unless no_feather is set

]]--

local toucan_sounds = {
    takeoff = "dontstarve_DLC002/creatures/toucan/takeoff",
    chirp = "dontstarve_DLC002/creatures/toucan/chirp",
    flyin = "dontstarve/birds/flyin",
}

local pigeon_sounds = {
    takeoff = "dontstarve_DLC003/creatures/pigeon/takeoff",
    chirp = "dontstarve_DLC003/creatures/pigeon/chirp",
    flyin = "dontstarve/birds/flyin",
}

local parrot_blue_sounds = {
    takeoff = "dontstarve_DLC002/creatures/parrot/takeoff",
    chirp = "dontstarve_DLC002/creatures/parrot/chirp",
    flyin = "dontstarve/birds/flyin",
}

local kingfisher_sounds = {
    takeoff = "porkland_soundpackage/birds/takeoff_faster",
    takeoff_2 = "dontstarve_DLC003/creatures/king_fisher/take_off",
    chirp = "dontstarve_DLC003/creatures/king_fisher/chirp",
    flyin = "dontstarve/birds/flyin",
}

local crow_sounds =
{
    takeoff = "dontstarve/birds/takeoff_crow",
    chirp = "dontstarve/birds/chirp_crow",
    flyin = "dontstarve/birds/flyin",
}

local robin_sounds =
{
    takeoff = "dontstarve/birds/takeoff_robin",
    chirp = "dontstarve/birds/chirp_robin",
    flyin = "dontstarve/birds/flyin",
}

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and not inst.sg:HasStateTag("flight")
end

local BIRD_TAGS = {"bird"}
local function OnAttacked(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, BIRD_TAGS)
    local num_friends = 0
    local maxnum = 5
    for _, v in pairs(ents) do
        if v ~= inst then
            v:PushEvent("gohome")
            num_friends = num_friends + 1
        end

        if num_friends > maxnum then
            return
        end
    end
end

local function OnTrapped(inst, data)
    if data and data.trapper and data.trapper.settrapsymbols then
        data.trapper.settrapsymbols(inst.trappedbuild)
    end
end

local function OnPutInInventory(inst)
    -- Otherwise sleeper won't work if we're in a busy state
    inst.sg:GoToState("idle")
end

local function OnDropped(inst)
    inst.sg:GoToState("stunned")
end

local function SpawnPrefabChooser(inst) -- 鸟在每次起飞的时候会调用本函数留下种子，而在室内会因为撞墙多次起飞，因此在室内不调用本函数留下种子
    local x, _, z = inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return nil
    end
    if inst.prefab == "kingfisher" and math.random() < 0.1 then
        return "coi"
    else
        return "seeds"
    end
end

local brain = require("brains/birdbrain")

local function MakeBird(name, sounds, feather_name, isreplace)
    local assets =
    {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/" .. name .. "_build.zip"),
        Asset("SOUND", "sound/birds.fsb"),
    }

    local prefabs = {
        "seeds",
        "smallmeat",
        "cookedsmallmeat",
        "feather_" .. feather_name
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddPhysics()
        inst.entity:AddAnimState()
        inst.entity:AddDynamicShadow()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:SetMass(1)
        inst.Physics:SetSphere(1)

        if TheWorld:HasTag("porkland") then
            inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
            inst.Physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
        end

        inst.AnimState:SetBank("crow")
        inst.AnimState:SetBuild(name .. "_build")
        inst.AnimState:PlayAnimation("idle")

        inst.DynamicShadow:SetSize(1, 0.75)
        inst.DynamicShadow:Enable(false)

        inst.Transform:SetTwoFaced()

        inst:AddTag("bird")
        inst:AddTag(name)
        inst:AddTag("smallcreature")
        inst:AddTag("likewateroffducksback")
        inst:AddTag("stunnedbybomb")
        inst:AddTag("noember")

        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")

        if isreplace then
            inst:SetPrefabNameOverride(name)
        end

        MakeFeedableSmallLivestockPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        inst.components.locomotor:SetTriggersCreep(false)


        inst:AddComponent("lootdropper")
        inst.components.lootdropper:AddRandomLoot("feather_" .. feather_name, 1)
        inst.components.lootdropper:AddRandomLoot("smallmeat", 1)
        inst.components.lootdropper.numrandomloot = 1

        inst:AddComponent("occupier")

        inst:AddComponent("eater")
        if name == "kingfisher" then
            inst.components.eater:SetDiet({FOODTYPE.SEEDS, FOODTYPE.MEAT}, {FOODTYPE.SEEDS, FOODTYPE.MEAT})
        else
            inst.components.eater:SetDiet({FOODTYPE.SEEDS}, {FOODTYPE.SEEDS})
        end

        inst:AddComponent("sleeper")
        inst.components.sleeper.watchlight = true
        inst.components.sleeper:SetSleepTest(ShouldSleep)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.nobounce = true
        inst.components.inventoryitem.canbepickedup = false
        inst.components.inventoryitem.canbepickedupalive = true
        inst.components.inventoryitem:SetSinks(true)
        if isreplace then
            inst.components.inventoryitem:ChangeImageName(name)
        end

        inst:AddComponent("cookable")
        inst.components.cookable.product = "cookedsmallmeat"

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(TUNING.BIRD_HEALTH)
        inst.components.health.murdersound = "dontstarve/wilson/hit_animal"

        inst:AddComponent("inspectable")

        inst:AddComponent("combat")
        inst.components.combat.hiteffectsymbol = "crow_body"

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
        inst.components.hauntable.panicable = true

        inst:AddComponent("periodicspawner")
        inst.components.periodicspawner:SetPrefab(SpawnPrefabChooser)
        inst.components.periodicspawner:SetDensityInRange(20, 2)
        inst.components.periodicspawner:SetMinimumSpacing(8)
        if name == "kingfisher" then
            inst.components.periodicspawner.onlanding = true
        end

        MakeSmallBurnableCharacter(inst, "crow_body")
        MakeTinyFreezableCharacter(inst, "crow_body")
        MakeFeedableSmallLivestock(inst, TUNING.BIRD_PERISH_TIME, OnPutInInventory, OnDropped)

        inst:SetBrain(brain)
        inst:SetStateGraph("SGpl_bird")

        inst.flyawaydistance = TUNING.BIRD_SEE_THREAT_DISTANCE

        inst.sounds = sounds
        inst.trappedbuild = name .. "_build"

        inst:ListenForEvent("ontrapped", OnTrapped)
        inst:ListenForEvent("attacked", OnAttacked)
        local birdspawner = TheWorld.components.birdspawner
        if birdspawner then
            inst:ListenForEvent("onremove", birdspawner.StopTrackingFn)
            inst:ListenForEvent("enterlimbo", birdspawner.StopTrackingFn)
            birdspawner:StartTracking(inst)
        end

        return inst
    end

    local prefabname = name
    if isreplace then
        prefabname = "pl_"..name
    end

    return Prefab(prefabname, fn, assets, prefabs)
end

local function DoSpawn(inst)
    local DIST = 8
    local pigeon = SpawnPrefab("pigeon")
    local x, _, z = inst.Transform:GetWorldPosition()
    x = x + math.random() * DIST - DIST / 2
    z = z + math.random() * DIST - DIST / 2
    pigeon.Transform:SetPosition(x, 15, z)

    if math.random() < 0.5 then
       pigeon.Transform:SetRotation(180)
    end
end

local function SpawnPigeon(inst)
    inst.pigeon_count = inst.pigeon_count - 1
    DoSpawn(inst)
    if inst.pigeon_count > 0 then
        inst:DoTaskInTime(math.random() * 0.7, function()
            SpawnPigeon(inst)
        end)
    else
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics() -- for birdspawner
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local birdspawner = TheWorld.components.birdspawner
    if birdspawner then
        inst:ListenForEvent("onremove", birdspawner.StopTrackingFn)
        birdspawner:StartTracking(inst)
    end

    inst.pigeon_count = math.random(3,7)

    SpawnPigeon(inst)

    return inst
end

return  MakeBird("toucan", toucan_sounds, "crow"),
        MakeBird("pigeon", pigeon_sounds, "robin_winter"),
        MakeBird("parrot_blue", parrot_blue_sounds, "robin_winter"),
        MakeBird("kingfisher", kingfisher_sounds, "robin_winter"),
        MakeBird("crow", crow_sounds, "crow", true),
        MakeBird("robin", robin_sounds, "robin", true),
        Prefab("pigeon_swarm", fn, {}, {"pigeon"})
