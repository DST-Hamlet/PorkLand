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
    if TheWorld and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(x, z, 0.01) then
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

local _CanEntitySeeTarget = CanEntitySeeTarget
function CanEntitySeeTarget(inst, target, ...)
    if inst and inst.player_classified then
        if target and target:IsValid() and inst.components.persistencevision and inst.components.persistencevision.persistence_ents[target] then
            return true
        end
        if target and target:IsValid() and inst.player_classified._last_work_target:value() == target then
            return true
        end
    end
    return _CanEntitySeeTarget(inst, target, ...)
end

local _OnEntitySleep = OnEntitySleep
function OnEntitySleep(guid, ...)
    _OnEntitySleep(guid, ...)
    local inst = Ents[guid]
    if inst then
        inst.sleeptested = true
    end
end

local _OnEntityWake = OnEntityWake
function OnEntityWake(guid, ...)
    _OnEntityWake(guid, ...)
    local inst = Ents[guid]
    if inst then
        inst.sleeptested = true
    end
end

NewFrameEnts = {}

local _SpawnPrefab = SpawnPrefab
function SpawnPrefab(...)
    local inst = _SpawnPrefab(...)
    if inst then
        NewFrameEnts[inst.GUID] = true
    end
    return inst
end

local _Update = Update
function Update(dt, ...)
    _Update(dt, ...)

    -- 警告：出于未知原因，在一帧新的加载范围中生成新生物会导致生物的OnEntityWake和OnEntitySleep都没有被执行
    -- 在原版世界c_gonext("wasphive")即可生成没有brain的杀人蜂(注意杀人蜂巢只会被不在上帝模式的玩家触发)
    for k, v in pairs(NewFrameEnts) do
        local inst = Ents[k]
        if inst then
            if not inst.sleeptested then
                if not inst:IsAsleep() then
                    OnEntityWake(k)
                else
                    OnEntitySleep(k)
                end
            end
        end
        NewFrameEnts[k] = nil
    end

    NewFrameEnts = {}
end

PostUpdateFunctionData = {}

local _PostUpdate = PostUpdate
function PostUpdate(dt, ...)
    _PostUpdate(dt, ...)

    for k, data in pairs(PostUpdateFunctionData) do

        if data.ent and data.ent:IsValid()
            and data.fn and type(data.fn) == "function" then

            data.fn(data.ent)
        end
        PostUpdateFunctionData[k] = nil
    end

    PostUpdateFunctionData = {}
end
