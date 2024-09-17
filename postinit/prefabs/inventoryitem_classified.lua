local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------

local function SerializeFuse(inst, time)
    inst.fuse:set(time or 0)
end

local function DeserializeFuse(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("fusechange", {time = inst.fuse:value()})
    end
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("fusedirty", DeserializeFuse)
end

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

AddPrefabPostInit("inventoryitem_classified", function(inst)
    inst.fuse = net_smallbyte(inst.GUID, "fuse.fuse", "fusedirty")

    inst.fuse:set(0)

    if not TheWorld.ismastersim then

        inst.DeserializeFuse = DeserializeFuse

        --Delay net listeners until after initial values are deserialized
        inst:DoTaskInTime(0, RegisterNetListeners)
        return

    end

    inst.SerializeFuse = SerializeFuse
end)
