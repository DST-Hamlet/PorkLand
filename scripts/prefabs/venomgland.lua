local assets=
{
  Asset("ANIM", "anim/venom_gland.zip"),
}

local function OnCure(inst, target)
  if target.components.health then
    local currenthealth = target.components.health.currenthealth
    local damage = math.clamp( currenthealth - TUNING.VENOM_GLAND_MIN_HEALTH, 0, TUNING.VENOM_GLAND_DAMAGE )
    target.components.health:DoPoisonDamage(damage)
    target:PushEvent("poisondamage", {damage=damage})
  end
end

local function fn()
  local inst = CreateEntity()
  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst:AddTag("cattoy")
  inst:AddTag("venomgland")

  inst.AnimState:SetBank("venom_gland")
  inst.AnimState:SetBuild("venom_gland")
  inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst)
	inst.components.floater:UpdateAnimations("idle_water", "idle")
	
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

  inst:AddComponent("stackable")

  MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
  MakeSmallPropagator(inst)

  inst:AddComponent("inspectable")    
  -- MakeInvItemIA(inst) Fix

  inst:AddComponent("tradable")

  -- inst:AddComponent("poisonhealer") TODO FIx
  -- inst.components.poisonhealer.oncure = OnCure

  MakeHauntableLaunch(inst)

  return inst
end

return Prefab( "venomgland", fn, assets)
