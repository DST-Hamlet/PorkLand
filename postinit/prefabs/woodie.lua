local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function StartWerePlayer(inst, data)
    if inst.components.hayfever then
        inst.components.hayfever.imune = true
    end
end

local function StopWerePlayer(inst, data)
    if inst.components.hayfever then
        inst.components.hayfever.imune = false
    end
end

AddPrefabPostInit("woodie", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("startwereplayer", StartWerePlayer)
    inst:ListenForEvent("stopwereplayer", StopWerePlayer)
end)
