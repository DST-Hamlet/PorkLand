local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function startwereplayer(inst, data)
	if inst.components.poisonable then
		inst.components.poisonable:SetBlockAll(true)
	end
end

local function stopwereplayer(inst, data)
	if inst.components.poisonable and not inst:HasTag("playerghost") then
		inst.components.poisonable:SetBlockAll(false)
	end
end

AddPrefabPostInit("woodie", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("startwereplayer", startwereplayer)
	inst:ListenForEvent("stopwereplayer", stopwereplayer)
end)
