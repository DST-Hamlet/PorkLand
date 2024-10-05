local assets =
{
	Asset("ANIM", "anim/bubbles_sunk.zip"),
}

local function ontimerdone(inst, data)
	if data.name == "destroy" then
		inst:Remove()
	end
end

local function dobubblefx(inst)
	inst.AnimState:PlayAnimation("bubble_pre")
	inst.AnimState:PushAnimation("bubble_loop")
	inst.AnimState:PushAnimation("bubble_pst", false)
	inst:DoTaskInTime((math.random() * 15 + 15), dobubblefx)
end

local function init(inst, item)
	if not item then
        inst:Remove()
        return
    end

	inst.Transform:SetPosition(item.Transform:GetWorldPosition())

    if item and (item.components.health or item.components.murderable) then
        if item.components.lootdropper then
            local stacksize = item.components.stackable and item.components.stackable:StackSize() or 1
            for i = 1, stacksize do
                local loots = item.components.lootdropper:GenerateLoot()
                for k, v in pairs(loots) do
                    local loot = SpawnPrefab(v)
                    if loot then
                        if not inst.components.container:GiveItem(loot, nil, nil, false) then
                            loot:Remove()
                        end
                    end
                end
            end
        end
        item:Remove()
    else
        if not inst.components.container:GiveItem(item, nil, nil, false) then
            item:Remove()
        end
    end

    inst.components.timer:StartTimer("destroy", TUNING.SUNKENPREFAB_REMOVE_TIME)
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("bubbles_sunk")
	inst.AnimState:SetBuild("bubbles_sunk")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("sunkenprefab")
    inst.components.container.canbeopened = false

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)

	inst:DoTaskInTime((math.random() * 15 + 15), dobubblefx)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.Initialize = init

	return inst
end

return Prefab("sunkenprefab", fn, assets)
