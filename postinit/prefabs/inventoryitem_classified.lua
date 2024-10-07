local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------
local function SerializeInvSpace(inst, percent)
    inst.invspace:set((percent or 0) * 63)
end

local function DeserializeInvSpace(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("invspacechange", {percent = inst.invspace:value() / 63})
    end
end

local function SerializeFuse(inst, time)
    inst.fuse:set(time or 0)
end

local function DeserializeFuse(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("fusechange", {time = inst.fuse:value()})
    end
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("invspacedirty", DeserializeInvSpace)
    inst:ListenForEvent("fusedirty", DeserializeFuse)
end

----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

AddPrefabPostInit("inventoryitem_classified", function(inst)
    inst.invspace = net_smallbyte(inst.GUID, "inventory.invspace", "invspacedirty")
    inst.fuse = net_smallbyte(inst.GUID, "fuse.fuse", "fusedirty")

    inst.fuse:set(0)

    if not TheWorld.ismastersim then

        inst.DeserializeInvSpace = DeserializeInvSpace
        inst.DeserializeFuse = DeserializeFuse

        --Delay net listeners until after initial values are deserialized
        inst:DoTaskInTime(0, RegisterNetListeners)
        return

    end

    inst.SerializeInvSpace = SerializeInvSpace
    inst.SerializeFuse = SerializeFuse
end)
