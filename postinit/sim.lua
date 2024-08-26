GLOBAL.setfenv(1, GLOBAL)

local function GetLight(light, dist)
    -- thanks to HalfEnder776
    local A = math.log(light:GetIntensity())
    local B
    local C
    local D
    local r, g, b = light:GetColour()
    local E = 0.2126 * r + 0.7152 * g + 0.0722 * b

    if A == 0 then
        if dist > light:GetRadius() then
            D = 0
        else
            D = 1
        end
    elseif A < 0 then
        B = -(light:GetFalloff() / A)
        C = (dist / light:GetRadius()) ^ B
        D = math.exp(A * C)
    else -- A > 0
        D = 0
    end

    return D * E
end

local Sim = getmetatable(TheSim).__index
local old_GetLightAtPoint = Sim.GetLightAtPoint
Sim.GetLightAtPoint = function(sim, x, y, z, light_threshold)
    if TheWorld and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z) then
        -- ignore ambient light, only check lighters
        local position = Vector3(x, y, z)
        local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
        if center then
            local sum = 0
            local center_position = center:GetPosition()
            for _, v in ipairs(TheSim:FindEntities(center_position.x, 0, center_position.z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"})) do
                if v.Light and v.Light:IsEnabled() then
                    local light = GetLight(v.Light, math.sqrt(v:GetPosition():DistSq(position)))
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
