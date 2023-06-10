local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function fn(inst)
    inst:AddTag("hayfeverimune")
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable()
    end
end

AddPrefabPostInit("wormwood", fn)
