require("stategraphs/SGglowflycocoon")

local assets = {
	Asset("ANIM", "anim/lantern_fly.zip"),
}

local prefabs = {
    "glowfly"
}

local function OnNear(inst)
	if inst:HasTag("readytohatch") then
		inst:DoTaskInTime(5 + math.random() * 3, function()
            inst:PushEvent("hatch")
        end)
	end
end

local function SpawnRabidBeetle(inst)
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local rabid_beetle = SpawnPrefab("rabid_beetle")
    if rabid_beetle then
        rabid_beetle.Transform:SetPosition(pos.x,pos.y,pos.z)
        rabid_beetle.sg:GoToState("hatch")
    end
end

local function OnChangeSeason(inst, season)
    if season ~= SEASONS.HUMID then
        inst.expiretask, inst.expiretaskinfo = inst:ResumeTask(2 * TUNING.SEG_TIME + math.random() * 3, function()
            inst.sg:GoToState("cocoon_expire")
        end)
    else
        inst:AddTag("readytohatch")
    end
end

local function OnFinishCallback(inst, worker)
	if worker.components.inventory ~= nil then
        worker.components.inventory:GiveItem("lightbulb", nil, inst:GetPosition())
    else
		inst:Remove()
	end
end

local function OnSave(inst, data)

    if inst:HasTag("readytohatch") then
        data.readytohatch = true
    end

    if inst.expiretaskinfo ~= nil then
		data.expiretasktime = inst:TimeRemainingInTask(inst.expiretaskinfo)
	end
end

local function OnLoad(inst, data)

    if data.readytohatch then
        inst:AddTag("readytohatch")
    end

    if data.expiretasktime ~= nil then
        inst.expiretask, inst.expiretaskinfo = inst:ResumeTask(data.expiretasktime, function()
            inst.sg:GoToState("cocoon_expire")
        end)
    end
end

local function mainfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(0.6,0.6,0.6)

    MakeCocoonPhysics(inst)

    inst:AddTag("insect")
	inst:AddTag("animal")
	inst:AddTag("smallcreature")
	inst:AddTag("cocoon")

	inst.AnimState:SetBank("lantern_fly")
	inst.AnimState:SetBuild("lantern_fly")
	inst.AnimState:PlayAnimation("cocoon_idle_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('glowfly')

    inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.GLOWFLY_COCOON_HEALTH)

    inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "body"

    inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.NET)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(OnFinishCallback)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(30,31)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    inst:SetStateGraph("SGglowflycocoon")

    inst:WatchWorldState("season", OnChangeSeason)

    inst.SpawnRabidBeetle = SpawnRabidBeetle

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntablePanic(inst)
    MakePoisonableCharacter(inst)
	MakeSmallBurnableCharacter(inst, "upper_body", Vector3(0, -1, 1))

    return inst
end

return Prefab("glowfly_cocoon", mainfn, assets, prefabs)
