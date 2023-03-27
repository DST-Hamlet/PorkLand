local prefabs = {
    "glowfly",
    "glowfly_cocoon"
}

local assets = {
    Asset("ANIM", "anim/pillar_tree.zip"),
}

-- 生成虫卵
local function SpawnCocoons(inst)
    if math.random() < 0.4 then
        local pt = inst:GetPosition()
        local radius = 5 + math.random() * 10
        local start_angle = math.random() * 2 * PI
        local offset = FindWalkableOffset(pt, start_angle, radius, 10)

        if offset ~= nil then
            local newpoint = pt + offset
            for _, player in ipairs(AllPlayers) do
            local distsq = player:GetDistanceSqToPoint(newpoint)
                if distsq > 40 * 40 then
                    for i = 1, math.random(6,10) do
                        radius = math.random() * 8
                        start_angle = math.random() * 2 * PI
                        local suboffset = FindWalkableOffset(newpoint, radius, start_angle, 10)
                        local cocoon = SpawnPrefab("glowfly_cocoon")
                        local spawnpt = newpoint + suboffset
                        cocoon.Physics:Teleport(spawnpt.x,spawnpt.y,spawnpt.z)
                    end
                end
            end
        end
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 3, 24)

    inst.Transform:SetScale(1,1,1)
	inst.MiniMapEntity:SetIcon("pillar_tree.png")

    -- THIS WAS COMMENTED OUT BECAUSE THE ROC WAS BUMPING INTO IT. BUT I'M NOT SURE WHY IT WAS SET THAT WAY TO BEGIN WITH.
    --inst.Physics:SetCollisionGroup(COLLISION.GROUND)
    inst:AddTag("tree_pillar")

	inst.AnimState:SetBank("pillar_tree")
	inst.AnimState:SetBuild("pillar_tree")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst.SpawnCocoons = SpawnCocoons

    inst.glowflyspawner = TheWorld.components.glowflyspawner
    if inst.glowflyspawner ~= nil then
        TheWorld:ListenForEvent("spawncocoons", function()
            SpawnCocoons(inst)
        end)
    end

   return inst
end

return Prefab("tree_pillar", fn, assets, prefabs)
