local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function OnDeath(inst, data)
    if inst.components.poisonable ~= nil then
        inst.components.poisonable:SetBlockAll(true)
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:Disable()
    end
end

local function OnRespawnFromGhost(inst, data)
    if inst.components.poisonable ~= nil and not inst:HasTag("beaver") then
        inst.components.poisonable:SetBlockAll(false)
    end

    if inst.components.hayfever ~= nil then
        inst.components.hayfever:OnHayFever(TheWorld.state.ishayfever)
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if not inst.components.hayfever then
        inst:AddComponent("hayfever")
    end


    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
end)
