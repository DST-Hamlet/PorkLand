local assets =
{
	Asset("ANIM", "anim/sprinkler_fx.zip")
}

local prefabs =
{
}

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	anim:SetBank("sprinkler_fx")
	anim:SetBuild("sprinkler_fx")
	anim:PlayAnimation("spray_loop", true)

    inst.persists = false

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	return inst
end

return Prefab("water_spray", fn, assets, prefabs)
