local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function RegisterNetListeners(inst)
    if TheWorld.ismastersim then
    else
    end
end

AddPrefabPostInit("player_classified", function(inst)
    inst:DoTaskInTime(0, RegisterNetListeners)
end)
