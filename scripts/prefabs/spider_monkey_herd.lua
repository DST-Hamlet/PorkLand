local assets =
{

}

local prefabs =
{
    "spider_monkey",
}

local function CanSpawn(inst)
    return inst.components.herd and not inst.components.herd:IsFull()
end

local function OnSpawned(inst, newent)
    if inst.components.herd then
        inst.components.herd:AddMember(newent)
    end
end

local function ReplaceTree(tree)
    local treePos = Vector3(tree.Transform:GetWorldPosition())
    tree:Remove()
    local homeTree = SpawnPrefab("spider_monkey_tree")
    homeTree.Transform:SetPosition(treePos.x, treePos.y, treePos.z)
    return homeTree
end

local function GetNewHomeTree(inst)
    local playerPos = Vector3(ThePlayer.Transform:GetWorldPosition())

    for k, v in pairs(inst.components.herd.members) do
        local x, y, z = k.Transform:GetWorldPosition()
        local noneOfTags = {"player", "fx", "burnt", "stump"}
        local possibleHomeTrees = nil

        if x and y and z then
            possibleHomeTrees = TheSim:FindEntities(x, y, z, 300, {"jungletree"}, noneOfTags)
        end

        if possibleHomeTrees then
            for i, possibleHomeTree in ipairs(possibleHomeTrees) do
                local possibleHomeTreePos = Vector3(possibleHomeTree.Transform:GetWorldPosition())
                local tile = TheWorld.Map:GetTileAtPoint(possibleHomeTreePos.x, 0, possibleHomeTreePos.z)

                -- Only get the new tree if it's offscreen because there is no animation
                -- for it transforming from a jungle tree to a spider monkey tree.
                local isJungleTile = tile == WORLD_TILES.DEEPRAINFOREST or tile == WORLD_TILES.DEEPRAINFOREST_NOCANOPY
                local possibleTreeIsOffCamera = distsq(possibleHomeTreePos, playerPos) > (50 * 50)

                if isJungleTile and possibleTreeIsOffCamera then
                    local possibleNeighborTrees = TheSim:FindEntities(possibleHomeTreePos.x, possibleHomeTreePos.y, possibleHomeTreePos.z, 7, {"jungletree"}, noneOfTags)

                    -- Allow neighboring trees to be affected by the ground creep of the cobwebs.
                    if possibleNeighborTrees then
                        for i, possibleNeighborTree in ipairs(possibleNeighborTrees) do
                            if possibleNeighborTree ~= possibleHomeTree then
                                ReplaceTree(possibleNeighborTree)
                            end
                        end
                    end

                    return ReplaceTree(possibleHomeTree)
                end
            end
        end
    end

    return nil
end

local function OnAddMember(inst, member)
    if inst.homeTree then
        member.components.knownlocations:RememberLocation("home", inst.homeTree:GetPosition(), false)
    end
end

local function RefreshHerdMemberHomeLocations(inst)
    for k, v in pairs(inst.components.herd.members) do
        OnAddMember(inst, k)
    end
end

local function RefreshHomeTree(inst)
    if not inst.homeTree or not inst.homeTree:IsValid() or inst.homeTree:HasTag("stump") or inst.homeTree:HasTag("burnt") then
        inst.homeTree = GetNewHomeTree(inst)

        if inst.homeTree then
            -- Cross reference the spider monkey tree with the herd
            inst.homeTree.spiderMonkeyHerd = inst

            -- Ensure that all of the herd members remember the home tree location.
            RefreshHerdMemberHomeLocations(inst)
        end
    end
end

local function OnSave(inst, data)
    if inst.homeTree and inst.homeTree:IsValid() and not inst.homeTree:HasTag("stump") and not inst.homeTree:HasTag("burnt") then
        data.homeTree = inst.homeTree.GUID
        return {inst.homeTree.GUID}
    end
end

local function OnLoadPostPass(inst, ents, data)
    if data and data.homeTree and ents[data.homeTree] then
        inst.homeTree = ents[data.homeTree].entity
        inst.homeTree.spiderMonkeyHerd = inst

        RefreshHerdMemberHomeLocations(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("herd")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("herd")
    inst.components.herd:SetMemberTag("spider_monkey")
    inst.components.herd:SetGatherRange(40)
    inst.components.herd:SetUpdateRange(20)
    inst.components.herd:SetOnEmptyFn(inst.Remove)
    inst.components.herd:SetAddMemberFn(OnAddMember)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetRandomTimes(TUNING.SPIDER_MONKEY_MATING_SEASON_BABYDELAY, TUNING.SPIDER_MONKEY_MATING_SEASON_BABYDELAY_VARIANCE)
    inst.components.periodicspawner:SetPrefab("spider_monkey")
    inst.components.periodicspawner:SetOnSpawnFn(OnSpawned)
    inst.components.periodicspawner:SetSpawnTestFn(CanSpawn)
    inst.components.periodicspawner:SetDensityInRange(20, 6)
    inst.components.periodicspawner:SetOnlySpawnOffscreen(true)
    inst.components.periodicspawner:Start()

    inst.RefreshHomeTreeFn = RefreshHomeTree
    inst.RefreshHomeTreeTask = inst:DoPeriodicTask(5, inst.RefreshHomeTreeFn)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("spider_monkey_herd", fn, assets, prefabs)
