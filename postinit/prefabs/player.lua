local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnDeath(inst, data)
    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable()
    end
end

local function OnRespawnFromGhost(inst, data)
    if inst.components.hayfever ~= nil and not inst:HasTag("hayfeverimune") then
        inst.components.hayfever:Enable()
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("hayfever")

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
end)
