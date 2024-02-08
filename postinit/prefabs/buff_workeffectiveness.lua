local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("buff_workeffectiveness", function(inst)
    local _onattachedfn = inst.components.debuff.onattachedfn
    inst.components.debuff.onattachedfn = function(_inst, target, ...)
        _onattachedfn(_inst, target, ...)

        if target.components.workmultiplier ~= nil then
            target.components.workmultiplier:AddMultiplier(ACTIONS.HACK, TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
            target.components.workmultiplier:AddMultiplier(ACTIONS.SHEAR, TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
            target.components.workmultiplier:AddMultiplier(ACTIONS.DISLODGE, TUNING.BUFF_WORKEFFECTIVENESS_MODIFIER, inst)
        end
    end

    local _ondetachedfn = inst.components.debuff.ondetachedfn
    inst.components.debuff.ondetachedfn = function(_inst, target, ...)
        _ondetachedfn(_inst, target, ...)

        if target.components.workmultiplier ~= nil then
            target.components.workmultiplier:RemoveMultiplier(ACTIONS.HACK, inst)
            target.components.workmultiplier:RemoveMultiplier(ACTIONS.SHEAR, inst)
            target.components.workmultiplier:RemoveMultiplier(ACTIONS.DISLODGE, inst)
        end
    end
end)
