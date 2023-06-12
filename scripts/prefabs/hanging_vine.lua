
local assets=
{
	Asset("ANIM", "anim/cave_exit_rope.zip"),
	Asset("ANIM", "anim/vine01_build.zip"),
	Asset("ANIM", "anim/vine02_build.zip"),
	Asset("SOUND", "sound/frog.fsb"),
}

local prefabs =
{
	"grabbing_vine",
}

local function onnear(inst)
	inst.AnimState:PlayAnimation("down")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/grabbing_vine/drop")
    inst.shadow:SetSize(1.5, .75)
end

local function onfar(inst)
    inst.AnimState:PlayAnimation("up")
    inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
    inst.shadow:SetSize(0,0)
end

local function round(x)
  x = x *10
  local num = x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  return num/10
end

local function placegoffgrids(inst, radiusMax, prefab,tags)
    local x,y,z = inst.Transform:GetWorldPosition()
    local offgrid = false
    local inc = 1
    while offgrid == false do

        if not radiusMax then
        	radiusMax = 12
        end
        local rad = math.random()*radiusMax
        local xdiff = math.random()*rad
        local ydiff = math.sqrt( (rad*rad) - (xdiff*xdiff))

        if math.random() > 0.5 then
        	xdiff= -xdiff
        end

        if math.random() > 0.5 then
        	ydiff= -ydiff
        end
        x = x+ xdiff
        z = z+ ydiff

        local ents = TheSim:FindEntities(x,y,z, 1, tags)
        local test = true
        for i,ent in ipairs(ents) do
            local entx,enty,entz = ent.Transform:GetWorldPosition()
           -- print("checing round x:",round(x),round(entx),"z:", round(z), round(entz),"diff:",round(math.abs(entx-x)),round( math.abs(entz-z)) )
            if round(x) == round(entx) or round(z) == round(entz) or ( math.abs(round(entx-x)) == math.abs(round(entz-z)) )  then
                test = false
         --       print("test fail")
                break
            end
        end

        offgrid = test
        inc = inc +1
    end

    local tile = TheWorld.Map:GetTileAtPoint(x,y,z)
    if  tile == WORLD_TILES.DEEPRAINFOREST then
    	local plant = SpawnPrefab(prefab)
    	plant.Transform:SetPosition(x,y,z)
    	plant.spawnpatch = inst
    	return true
	end
	return false
end

local function spawnitem(inst, prefab)
    --if TheWorld:IsWorldGenOptionNever(prefab) then--世界设置相关，该部分未完成
        --return
    --end

    local rad = prefab == "grabbing_vine" and 12 or 14

    placegoffgrids(inst, rad, prefab, {"hangingvine"})
end

local function spawnvines(inst)
	inst.spawnedchildren = true
    for i=1, math.random(TUNING.HANGING_VINE_SPAWN_MIN, TUNING.HANGING_VINE_SPAWN_MAX), 1 do
        spawnitem(inst, "hanging_vine")
    end

    for i=1, math.random(TUNING.GRABBING_VINE_SPAWN_MIN, TUNING.GRABBING_VINE_SPAWN_MAX), 1 do
    	spawnitem(inst, "grabbing_vine")
    end
end

local function spawnNewVine(inst,prefab)
	if not inst.spawntasks then
		inst.spawntasks = {}
	end
	local spawntime = TUNING.TOTAL_DAY_TIME*2 + (TUNING.TOTAL_DAY_TIME*math.random())
	local newtask = {}
    inst.spawntasks[newtask] = newtask
	newtask.prefab = prefab
    newtask.task, newtask.taskinfo = inst:ResumeTask(spawntime,
        function()
            spawnitem(inst,newtask.prefab)
            inst.spawntasks[newtask] = nil
        end)
    inst.spawntasks[newtask] = newtask
end

local function onsave(inst, data)
    data.spawnedchildren = inst.spawnedchildren
    if inst.spawntasks then
    	data.spawntasks= {}
    	for i,oldtask in pairs(inst.spawntasks)do
            --local test = inst:DoTaskInTime(5,function()end)
            --dumptable(test,1,1)

    		local newtask = {}
    		newtask.prefab = oldtask.prefab
    		newtask.time = inst:TimeRemainingInTask(oldtask.taskinfo)
            table.insert(data.spawntasks,newtask)
    	end
    end
end

local function onload(inst, data)
    if data then
        if data.spawnedchildren then
        	inst.spawnedchildren = true
        end
        if data.spawntasks then
        	inst.spawntasks = {}
        	for i,oldtask in ipairs(data.spawntasks)do
        		local newtask = {}
                inst.spawntasks[newtask] = newtask
        		newtask.prefab = oldtask.prefab
                newtask.task, newtask.taskinfo = inst:ResumeTask(oldtask.time,
					function()
						spawnitem(inst,oldtask.prefab)
                        inst.spawntasks[newtask] = nil
					end)
        	end
        end
    end
end

local function patchfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst:DoTaskInTime(0,function() if not inst.spawnedchildren then spawnvines(inst) end end)
    --inst:DoTaskInTime(0, function() inst:Remove() end)
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.spawnNewVine = spawnNewVine
	return inst
end

local function onshearfn (inst)
    if inst.spawnpatch then
        inst.spawnpatch.spawnNewVine(inst.spawnpatch, inst.prefab)
    end

    inst:Remove()
end

local function commonfn(Sim)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
	inst.shadow = inst.entity:AddDynamicShadow()
	inst.shadow:SetSize(1.5, .75)

	inst.AnimState:SetBank("exitrope")
	inst:AddTag("hangingvine")

	if math.random() < 0.5 then
		inst.AnimState:SetBuild("vine01_build")
	else
		inst.AnimState:SetBuild("vine02_build")
	end

	inst.AnimState:PlayAnimation("idle_loop",true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	--MakeCharacterPhysics(inst, 1, .3)

	--inst:AddComponent("health")
	--inst.components.health:SetMaxHealth(TUNING.FROG_HEALTH)

	--inst:AddComponent("lootdropper")
	--inst.components.lootdropper:SetLoot({"froglegs"})
--[[
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.FROG_DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.FROG_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, retargetfn)

	inst.components.combat.onhitotherfn = function(inst, other, damage) inst.components.thief:StealItem(other) end
]]

	--MakeTinyFreezableCharacter(inst, "frogsack")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst.components.playerprox:SetDist(10,16)

	inst:AddComponent("inspectable")

    inst:AddComponent("shearable")
    inst.components.shearable:SetProduct("rope", 1)
	inst.components.shearable:SetOnShearFn(onshearfn)
	inst.components.shearable.canshaveable = true

--[[
    inst:AddComponent("distancefade")
    inst.components.distancefade:Setup(25,15)
]]
    inst.placegoffgrids = placegoffgrids

--	inst:ListenForEvent("attacked", OnAttacked)
--	inst:ListenForEvent("goinghome", OnGoingHome)

	return inst
end

return Prefab("hanging_vine", commonfn, assets, prefabs),
	   Prefab("hanging_vine_patch", patchfn, assets, prefabs)
