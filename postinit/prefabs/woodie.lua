local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function StartWerePlayer(inst, data)
    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable()
    end
    if inst.components.poisonable ~= nil then
        inst.components.poisonable:SetBlockAll(true)
    end
end

local function StopWerePlayer(inst, data)
    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Enable()
    end
    if inst.components.poisonable ~= nil and not inst:HasTag("playerghost") then
        inst.components.poisonable:SetBlockAll(false)
    end
end

AddPrefabPostInit("woodie", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("startwereplayer", StartWerePlayer)
    inst:ListenForEvent("stopwereplayer", StopWerePlayer)
end)
