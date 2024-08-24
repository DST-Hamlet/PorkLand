local assets =
{
    Asset("ANIM", "anim/ro_bin_gem.zip"),
}

local SPAWN_DIST = 30

local function GetSpawnPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = SPAWN_DIST

	local offset = FindWalkableOffset(pt, theta, radius, 12, true)
	if offset then
		return pt+offset
	end
end

local function SpawnRoBin(inst, spawn_pt, spawnevent)
    local pt = Vector3(inst.Transform:GetWorldPosition())

    if not spawn_pt then
        spawn_pt = GetSpawnPoint(pt)
    end

    if spawn_pt then
        local ro_bin = SpawnPrefab("ro_bin")
        if ro_bin then
            ro_bin.Physics:Teleport(spawn_pt:Get())
            ro_bin:FacePoint(pt.x, pt.y, pt.z)

            if spawnevent then
                ro_bin:PushEvent("spawnin")
            end

            return ro_bin
        end
    end
end

local function StopRespawn(inst)
    if inst.respawntask then
        inst.respawntask:Cancel()
        inst.respawntask = nil
        inst.respawntime = nil
    end
end

local function RebindRoBin(inst, ro_bin)
    ro_bin = ro_bin or TheSim:FindFirstEntityWithTag("ro_bin")
    if ro_bin then
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.components.inventoryitem:ChangeImageName(inst.openEye)
        inst:ListenForEvent("death", function() inst:OnRoBinDeath() end, ro_bin)

        if ro_bin.components.follower.leader ~= inst then
            ro_bin.components.follower:SetLeader(inst)
        end
        return true
    end
end

local function RespawnRoBin(inst)
    StopRespawn(inst)

    local ro_bin = TheSim:FindFirstEntityWithTag("ro_bin")
    if not ro_bin then
        ro_bin = SpawnRoBin(inst)
    end
    RebindRoBin(inst, ro_bin)
end

local function StartRespawn(inst, time)
    StopRespawn(inst)

    local respawntime = time or 0
    if respawntime then
        inst.respawntask = inst:DoTaskInTime(respawntime, function() RespawnRoBin(inst) end)
        inst.respawntime = GetTime() + respawntime
        inst.AnimState:PlayAnimation("dead", true)
        inst.components.inventoryitem:ChangeImageName(inst.closedEye)
    end
end

local function OnRoBinDeath(inst)
    StartRespawn(inst, TUNING.CHESTER_RESPAWN_TIME)
end

local function FixRoBin(inst)
	inst.fixtask = nil
	--take an existing ro_bin if there is one
	if not RebindRoBin(inst) then
        inst.AnimState:PlayAnimation("dead", true)
        inst.components.inventoryitem:ChangeImageName(inst.closedEye)

		if inst.components.inventoryitem.owner then
			local time_remaining = 0
			local time = GetTime()
			if inst.respawntime and inst.respawntime > time then
				time_remaining = inst.respawntime - time
			end
			StartRespawn(inst, time_remaining)
		end
	end
end

local function OnPutInInventory(inst)
	if not inst.fixtask then
		inst.fixtask = inst:DoTaskInTime(1, function() FixRoBin(inst) end)
	end
end

local function OnSave(inst, data)
    local time = GetTime()
    if inst.respawntime and inst.respawntime > time then
        data.respawntimeremaining = inst.respawntime - time
    end
    if inst.robinspawned then
        data.robinspawned = true
    end
end

local function OnLoad(inst, data)
    if data and data.respawntimeremaining then
		inst.respawntime = data.respawntimeremaining + GetTime()
	end
    if data and data.robinspawned then
        inst.robinspawned = data.robinspawned
    end
end

local function GetStatus(inst)
    if inst.respawntask then
        return "WAITING"
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ro_bin_gem")
    inst.AnimState:SetBuild("ro_bin_gem")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("ro_bin_gizzard_stone")
    inst:AddTag("irreplaceable")
	inst:AddTag("nonpotatable")
    inst:AddTag("follower_leash")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.openEye = "ro_bin_gem"
    inst.closedEye = "ro_bin_gem_closed"

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:ChangeImageName(inst.openEye)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
	inst.components.inspectable:RecordViews()

    inst:AddComponent("leader")

    MakeHauntableLaunch(inst)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnRoBinDeath = OnRoBinDeath

	inst.fixtask = inst:DoTaskInTime(1, function() FixRoBin(inst) end)

    return inst
end

return Prefab("ro_bin_gizzard_stone", fn, assets)
