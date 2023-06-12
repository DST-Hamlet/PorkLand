local assets =
{
	Asset("ANIM", "anim/sprinkler_pipes.zip")
}

local prefabs =
{
}

local function HideLayers(anim)
    local rays = {1, 2, 3}
    for i = 1, #rays, 1 do
        anim:Hide("joint"..i)
        anim:Hide("pipe"..i)
    end
end

local function ShowRandomLayers(inst, anim)
	if not inst.jointLayerShown then
		inst.jointLayerShown = "joint"..math.random(1, 3)
	end

	if not inst.pipeLayerShown then
		inst.pipeLayerShown = "pipe"..math.random(1, 3)
	end

	anim:Show(inst.jointLayerShown)
	anim:Show(inst.pipeLayerShown)
end

local function OnSave(inst, data)
	data.jointLayerShown = inst.jointLayerShown
	data.pipeLayerShown = inst.pipeLayerShown
end

local function OnLoad(inst, data)
	inst.jointLayerShown = data.jointLayerShown
	inst.pipeLayerShown = data.pipeLayerShown

	HideLayers(inst.AnimState)
	inst.AnimState:Show(inst.jointLayerShown)
	inst.AnimState:Show(inst.pipeLayerShown)
end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	anim:SetBank("sprinkler_pipes")
	anim:SetBuild("sprinkler_pipes")
	anim:PlayAnimation("place")

	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK")

	anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	anim:SetLayer(LAYER_BACKGROUND)
	anim:SetSortOrder(3)

	inst.OnSave = OnSave
    inst.OnLoad = OnLoad

	HideLayers(anim)
	ShowRandomLayers(inst, anim)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst.Transform:SetScale(1.5, 1.5, 1.5)
	inst:SetStateGraph("SGwater_pipe")

	return inst
end

return Prefab("water_pipe", fn, assets, prefabs)
