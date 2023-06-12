local function MakePlant(name, bank, build, anim)
	local assets =
	{
		Asset("ANIM", "anim/"..name..".zip"),
	}

	local prefabs =
	{
		name,
	}

	local function fn()
		
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		if name == "asparagus" then
			inst.Transform:SetScale(1.3, 1.3, 1.3)
		end

		inst.AnimState:SetBank(bank or name)
		inst.AnimState:SetBuild(build or name)
		inst.AnimState:PlayAnimation("planted")
		inst.AnimState:SetRayTestOnBB(true)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
		inst.components.pickable:SetUp(name, 10)
		inst.components.pickable.remove_when_picked = true
		inst.components.pickable.quickpick = true

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		AddToRegrowthManager(inst)

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

		return inst
	end
	return Prefab(name.."_planted", fn, assets, prefabs)
end

return MakePlant("asparagus"),
MakePlant("aloe"),
MakePlant("radish")
