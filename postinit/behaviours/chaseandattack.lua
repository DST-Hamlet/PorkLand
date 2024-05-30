local AddGlobalClassPostConstruct = AddGlobalClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

require("behaviours/chaseandattack")

local OUTSIDE_CATAPULT_RANGE = TUNING.WINONA_CATAPULT_MAX_RANGE + TUNING.WINONA_CATAPULT_KEEP_TARGET_BUFFER + TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 1
AddGlobalClassPostConstruct("behaviours/chaseandattack", "ChaseAndAttack", function(self)
    if self.distance_from_ocean_target == nil then
        if self.inst.components.amphibiouscreature == nil and not self.inst:HasTag("flying") and not self.inst:HasTag("shadow") then
            self.distance_from_ocean_target = function(inst, target)
                local attackrange = inst.components.combat.attackrange or 1
                return CanProbablyReachTargetFromShore(inst, target, attackrange - 0.75)
		        and attackrange - 0.75
		        or OUTSIDE_CATAPULT_RANGE
            end
        end
    end
end)
