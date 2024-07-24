local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function poop_manager_pickup(inst, owner)
    if inst.cityID then
        TheWorld.components.periodicpoopmanager:OnPickedUp(inst.cityID, inst, owner)
        inst.cityID = nil
    end
end

local function on_pickup(inst, data)
    poop_manager_pickup(inst, data.owner)
end

local function on_put_in_inventory(inst, owner)
    poop_manager_pickup(inst, owner)
end

AddPrefabPostInit("poop", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("onpickup", on_pickup)
    inst:ListenForEvent("onputininventory", on_put_in_inventory)
end)
