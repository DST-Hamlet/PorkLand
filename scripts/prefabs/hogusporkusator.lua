require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/hogusporkusator.zip"),
}

local prefabs =
{
	"collapse_small",
}

local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		if inst.components.prototyper.on then
			inst.AnimState:PushAnimation("proximity_loop", true)
		else
			inst.AnimState:PushAnimation("idle", false)
		end
	end
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
		data.burnt = true
	end
end

local function onload(inst, data)
	if data ~= nil and data.burnt then
		inst.components.burnable.onburnt(inst)
	end
end

local function doonact(inst)
	if inst._activecount > 1 then
		inst._activecount = inst._activecount - 1
	else
		inst._activecount = 0
		inst.SoundEmitter:KillSound("sound")
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_ding")
end

local function onturnon(inst)
	if inst._activetask == nil and not inst:HasTag("burnt") then
		if inst.AnimState:IsCurrentAnimation("proximity_loop")
			or inst.AnimState:IsCurrentAnimation("place") then
			--NOTE: push again even if already playing, in case an idle was also pushed
			inst.AnimState:PushAnimation("proximity_loop", true)
		else
			inst.AnimState:PlayAnimation("proximity_loop", true)
		end
		if not inst.SoundEmitter:PlayingSound("idlesound") then
			inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_idle_LP", "idlesound")
		end
	end
end

local function onturnoff(inst)
	if inst._activetask == nil and not inst:HasTag("burnt") then 
		inst.AnimState:PushAnimation("idle", false)
		inst.SoundEmitter:KillSound("idlesound")
	end
end

local function doneact(inst)
	inst._activetask = nil
	if not inst:HasTag("burnt") then
		if inst.components.prototyper.on then
			onturnon(inst)
		else
			onturnoff(inst)
		end
	end
end

local function onactivate(inst)
	if not inst:HasTag("burnt") then 
		inst.AnimState:PlayAnimation("use")
		inst.AnimState:PushAnimation("idle", false)
		if not inst.SoundEmitter:PlayingSound("sound") then
			inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_run", "sound")
		end
		inst._activecount = inst._activecount + 1
		inst:DoTaskInTime(1.5, doonact)
		if inst._activetask ~= nil then
			inst._activetask:Cancel()
		end
		inst._activetask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, doneact)
	end
end

local function onbuilt(inst, data)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl4_place")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .4)

	inst.MiniMapEntity:SetPriority(5)
	inst.MiniMapEntity:SetIcon("hogusporkusator.tex")

	inst.AnimState:SetBank("hogusporkusator")
	inst.AnimState:SetBuild("hogusporkusator")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("structure")
	inst:AddTag("level4")

	--prototyper (from prototyper component) added to pristine state for optimization
	inst:AddTag("prototyper")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._activecount = 0
	inst._activetask = nil

	inst:AddComponent("inspectable")
	inst:AddComponent("prototyper")
	inst.components.prototyper.onturnon = onturnon
	inst.components.prototyper.onturnoff = onturnoff
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.PRESTIHATITATOR
	inst.components.prototyper.onactivate = onactivate

	inst:ListenForEvent("onbuilt", onbuilt)

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
	MakeSnowCovered(inst)

	MakeLargeBurnable(inst, nil, nil, true)
	MakeLargePropagator(inst)

	inst.OnSave = onsave
	inst.OnLoad = onload

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	return inst
end

return Prefab("hogusporkusator", fn, assets, prefabs),
	MakePlacer("hogusporkusator_placer", "hogusporkusator", "hogusporkusator", "idle")
