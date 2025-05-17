local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function MakeBaby(inst)
    local angle = (inst.Transform:GetRotation() + 180) * DEGREES

    local prefab = "spider"
    if inst.components.combat:HasTarget() and math.random() < 0.45 then
        prefab = "spider_warrior" -- removed spider_healer here
    end

    local spider = inst.components.lootdropper:SpawnLootPrefab(prefab)
    if spider ~= nil then
        local rad = spider:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + .25
        local x, y, z = inst.Transform:GetWorldPosition()
        spider.Transform:SetPosition(x + rad * math.cos(angle), 0, z - rad * math.sin(angle))
        spider.sg:GoToState("taunt")
        inst.components.leader:AddFollower(spider)
        if inst.components.combat.target ~= nil then
            spider.components.combat:SetTarget(inst.components.combat.target)
        end
    end
end

local function spiderqueen_postinit(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.incrementalproducer.producefn = MakeBaby
end

AddPrefabPostInit("spiderqueen", spiderqueen_postinit)