local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local function OnDeath(inst, data)
    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable()
    end
end

local function OnRespawnFromGhost(inst, data)
    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Enable()
    end
end

PLENV.AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("hayfever")

        inst:ListenForEvent("death", OnDeath)
        inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
    end
end)
