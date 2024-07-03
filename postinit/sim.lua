GLOBAL.setfenv(1, GLOBAL)

local function GetLight(light, dist)
    -- thanks to HalfEnder776
    local A = math.log(light:GetIntensity())
    local B = -(light:GetFalloff() / A)
    local C = (dist / light:GetRadius()) ^ B
    local D = math.exp(A * C)
    local r, g, b = light:GetColour()
    local E = 0.2126 * r + 0.7152 * g + 0.0722 * b

    if A <= 0 then
        D = 1
    end

    return D * E
end

local Sim = getmetatable(TheSim).__index
local old_GetLightAtPoint = Sim.GetLightAtPoint
Sim.GetLightAtPoint = function(sim, x, y, z, light_threshold)
    if TheWorld and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z) then
        -- ignore ambient light, only check lighters
        local center = TheWorld.components.interiorspawner:GetInteriorCenterAt_Generic(x, z)
        if center then
            local sum = 0
            local pos = center:GetPosition()
            for _,v in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"}))do
                if v.Light and v.Light:IsEnabled() then
                    local light = GetLight(v.Light, math.sqrt(v:GetPosition():DistSq(Point(x, y, z))))
                    sum = sum + light
                    if sum > (light_threshold or math.huge) then
                        return sum
                    end
                end
            end
            return sum
        end
    end
    return old_GetLightAtPoint(sim, x, y, z, light_threshold)
end
