local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

PLENV.AddPrefabPostInit("trident", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _DoWaterExplosionEffect = inst.DoWaterExplosionEffect
    function inst.DoWaterExplosionEffect(inst, affected_entity, owner, position)
        _DoWaterExplosionEffect(inst, affected_entity, owner, position)

        if affected_entity.components.sinkable ~= nil then
            affected_entity.components.sinkable:OnRetrieved()
        end
    end
end)
