local assets =
{
    Asset("ANIM", "anim/ant_cave_lantern.zip"),
}

local loot = {"honey", "honey", "honey"}

local aporkalypse = GetAporkalypse()

local function OnWorkCallback(inst, worker, workleft)
    local pt = Point(inst.Transform:GetWorldPosition())
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(pt)
        inst:Remove()
    else
        if workleft < TUNING.HONEY_LANTERN_MINE*(1/3) then
            inst.AnimState:PlayAnimation("break")
        elseif workleft < TUNING.HONEY_LANTERN_MINE*(2/3) then
            inst.AnimState:PlayAnimation("hit")
        else
            inst.AnimState:PlayAnimation("idle")
        end
    end
end

local function turnonlight(inst)
    inst.Light:Enable(false)
end

local function turnofflight(inst)
    inst.Light:Enable(true)
end

local function exitlimbo(inst)
    inst.Light:Enable(not (aporkalypse and aporkalypse:IsActive()))
end

local function fn()
	local inst  = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.Light:SetFalloff(0.4)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetRadius(2.5)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.Light:Enable(true)

	inst.MiniMapEntity:SetIcon("ant_cave_lantern.png")

	inst.AnimState:SetBank("ant_cave_lantern")
    inst.AnimState:SetBuild("ant_cave_lantern")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.HONEY_LANTERN_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorkCallback)

    inst:ListenForEvent("beginaporkalypse", turnonlight, TheWorld)
    inst:ListenForEvent("endaporkalypse", turnofflight, TheWorld)
    inst:ListenForEvent("exitlimbo", exitlimbo)

    inst.Light:Enable(not (aporkalypse and aporkalypse:IsActive()))

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

	return inst
end

return Prefab("ant_cave_lantern", fn, assets)
