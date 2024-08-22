local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

--Only use for hit and idle anims
local function PushStateAnim(inst, anim, loop)
    inst.AnimState:PushAnimation(anim..inst.CAGE_STATE, loop)
end

local function GetBird(inst)
    return (inst.components.occupiable and inst.components.occupiable:GetOccupant()) or nil
end

local function DigestFood(inst, food)
    if food.components.edible.foodtype == FOODTYPE.MEAT then
        --If the food is meat:
            --Spawn an egg.
        inst.components.lootdropper:SpawnLootPrefab("bird_egg")
    else
        local seed_name = string.lower(food.prefab .. "_seeds")

        if Prefabs[seed_name] then
            local num_seeds = math.random(2)
            for i = 1, num_seeds do
                inst.components.lootdropper:SpawnLootPrefab(seed_name)
            end

            if math.random() < 0.5 then
                inst.components.lootdropper:SpawnLootPrefab("seeds")
            end
        else
            inst.components.lootdropper:SpawnLootPrefab("seeds")
        end
    end

    --Refill bird stomach.
    local bird = GetBird(inst)
    if bird and bird:IsValid() and bird.components.perishable then
        bird.components.perishable:SetPercent(1)
    end
end

local function OnGetItem(inst, giver, item)
    --If you're sleeping, wake up.
    if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end

    if item.components.edible ~= nil and
        (   item.components.edible.foodtype == FOODTYPE.MEAT
            or item.prefab == "seeds"
            or string.match(item.prefab, "_seeds")
            or Prefabs[string.lower(item.prefab .. "_seeds")] ~= nil
        ) then
        --If the item is edible...
        --Play some animations (peck, peck, peck, hop, idle)
        inst.AnimState:PlayAnimation("peck")
        inst.AnimState:PushAnimation("peck")
        inst.AnimState:PushAnimation("peck")
        inst.AnimState:PushAnimation("hop")
        PushStateAnim(inst, "idle", true)
        --Digest Food in 60 frames.
        inst:DoTaskInTime(60 * FRAMES, DigestFood, item)
    end
end

local function birdcage_postinit(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.trader.onaccept = OnGetItem
end

AddPrefabPostInit("birdcage", birdcage_postinit)
