require "prefabutil"
require "recipes"

local assets =
{
	Asset("ANIM", "anim/ant_house.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
	"antman",
    "antlarva",
}

local loot = {"honey","honey","honey","honeycomb"}

local aporkalypse = GetAporkalypse()

local function LaunchProjectile(inst, targetpos)
    --if not inst.canFire then return end
    local antlarva = SpawnPrefab("antlarva")
    antlarva.owner = inst
    antlarva.Transform:SetPosition(inst:GetPosition():Get())
    antlarva.components.complexprojectile:Launch(targetpos)
    --inst.canFire = false
    --inst.components.timer:StartTimer("Reload", TUNING.FIRESUPPRESSOR_RELOAD_TIME)
end

local function getstatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst.components.spawner and inst.components.spawner:IsOccupied() then
        if inst.lightson then
            return "FULL"
        else
            return "LIGHTSOUT"
        end
    end
end

local function onhammered(inst, worker)

    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end

    if inst.components.spawner then
        inst.components.spawner:ReleaseChild()
    end

    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_big")
    local pos = inst.Transform:GetWorldPosition()
	fx.Transform:SetPosition(pos)
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()

end

local function ongusthammerfn(inst)
    onhammered(inst, nil)
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
    	inst.AnimState:PlayAnimation("hit")
    	inst.AnimState:PushAnimation("idle")
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function maintainantpop(inst)
    if not inst:HasTag("INTERIOR_LIMBO") and not inst:HasTag("burnt") then
        local pt = inst:GetPosition()
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 40, {"antman"}, {"INTERIOR_LIMBO"})
        if #ents < TUNING.ANTMAN_MIN then
            local theta = math.random() * 2 * PI
            local radius = math.random() * 4 + 4
            local pt = inst:GetPosition()
            local offset = FindWalkableOffset(pt, theta, math.random() * radius, 12, true) --12
            LaunchProjectile(inst, pt + offset)
        end
    end
end

local function burntup(inst)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
end

local function onignite(inst)
    if inst.components.spawner then
        inst.components.spawner:ReleaseChild()
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
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetIcon( "ant_house.png" )

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(true)
    inst.Light:SetColour(185/255, 185/255, 20/255)
    inst.lightson = true

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("ant_house")
    inst.AnimState:SetBuild("ant_house")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")

    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	MakeSnowCovered(inst, .01)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst:ListenForEvent("burntup", burntup)
    inst:ListenForEvent("onignite", onignite)
    inst:ListenForEvent("beginaporkalypse", turnonlight, TheWorld)
    inst:ListenForEvent("endaporkalypse", turnofflight, TheWorld)
    inst:ListenForEvent("exitlimbo", exitlimbo)
    inst.Light:Enable(not (aporkalypse and aporkalypse:IsActive()))

    inst:DoPeriodicTask(30, function(inst) maintainantpop(inst) end )

    return inst
end

return Prefab("antcombhome", fn, assets, prefabs),
	   MakePlacer("antcombhome_placer", "ant_house", "ant_house", "idle")
