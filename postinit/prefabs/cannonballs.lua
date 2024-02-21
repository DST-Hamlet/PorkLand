local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

PLENV.AddPrefabPostInit("cannonball_rock", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnHit = inst.components.complexprojectile.onhitfn
    function inst.components.complexprojectile.onhitfn(inst, attacker, target)
        local ONHIT_EXCLUDE_TAGS = ToolUtil.GetUpvalue(_OnHit, "ONHIT_EXCLUDE_TAGS")
        local ONHIT_MUST_ONE_OF_TAGS = ToolUtil.GetUpvalue(_OnHit, "ONHIT_MUST_ONE_OF_TAGS")
        local x, y, z = inst.Transform:GetWorldPosition()
        local affected_entities = TheSim:FindEntities(x, 0, z, TUNING.CANNONBALL_SPLASH_RADIUS, nil, ONHIT_EXCLUDE_TAGS, ONHIT_MUST_ONE_OF_TAGS)
        for i, affected_entity in ipairs(affected_entities) do
            if affected_entity.components.sinkable ~= nil then
                affected_entity.components.sinkable:OnRetrieved()
            end
        end
        _OnHit(inst, attacker, target)
    end
end)
