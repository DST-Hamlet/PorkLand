local AddSimPostInit = AddSimPostInit
GLOBAL.setfenv(1, GLOBAL)

local function is_valid_teleport_target(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.components.pickable ~= nil and not v.components.pickable.caninteractwith then
            return false
        end
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return false
    end
    return true
end

local function sim_postinit()
    local TELEBASES = ToolUtil.GetUpvalue(FindNearestActiveTelebase, "TELEBASES")

    function FindNearestActiveTelebase(x, y, z, range, min_range)
        range = (range == nil and math.huge) or (range > 0 and range * range) or 0
        min_range = math.min(range, min_range ~= nil and min_range > 0 and min_range * min_range or 0)
        if min_range < range then
            local min_distsq = math.huge
            local nearest = nil
            for k, v in pairs(TELEBASES) do
                if is_valid_teleport_target(k) then
                    local distsq = k:GetDistanceSqToPoint(x, y, z)
                    if distsq < min_distsq and distsq >= min_range and distsq < range then
                        min_distsq = distsq
                        nearest = k
                    end
                end
            end
            return nearest
        end
    end
end

AddSimPostInit(sim_postinit)
