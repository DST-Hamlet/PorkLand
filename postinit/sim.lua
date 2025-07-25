GLOBAL.setfenv(1, GLOBAL)

function CalculateLight(light, dist)
    if dist > light:GetCalculatedRadius() then
        return 0, 0, 0
    end
    -- thanks to HalfEnder776
    local A = math.log(light:GetIntensity())
    local B
    local C
    local D
    local r, g, b = light:GetColour()

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

    return D * r, D * g, D * b
end

local Sim = getmetatable(TheSim).__index
local old_GetLightAtPoint = Sim.GetLightAtPoint
Sim.GetLightAtPoint = function(sim, x, y, z, light_threshold, ...) -- 和原版GetLightAtPoint的算法还是存在差别
    if TheWorld and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        -- 无视全局光，仅计算点光源
        local position = Vector3(x, y, z)
        local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
        if center then
            local sum = 0
            local center_position = center:GetPosition()
            for _, v in ipairs(TheSim:FindEntities(center_position.x, 0, center_position.z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"})) do
                if v.Light and v.Light:IsEnabled() then
                    local _r, _g, _b = CalculateLight(v.Light, math.sqrt(v:GetPosition():DistSq(position)))
                    sum = sum + 0.2126 * _r + 0.7152 * _g + 0.0722 * _b
                    if light_threshold and (sum >= light_threshold) then
                        return sum
                    end
                end
            end
            return sum
        end
    end
    return old_GetLightAtPoint(sim, x, y, z, light_threshold, ...)
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

pl_ProfilerPop = false

local update_start_time = os.clock()

local _Update = Update
function Update(dt, ...)
    if pl_ProfilerPop then
        print("--------------START UPDATE--------------")
        update_start_time = os.clock()
    end
    
    _Update(dt, ...)

    -- 警告：出于未知原因，在一帧新的加载范围中生成新生物会导致生物的OnEntityWake和OnEntitySleep都没有被执行
    -- 在原版世界c_gonext("wasphive")即可生成没有brain的杀人蜂(注意杀人蜂巢只会被不在上帝模式的玩家触发)
    for k, v in pairs(NewFrameEnts) do
        local inst = Ents[k]
        if inst and inst:IsValid() then
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

    if pl_ProfilerPop then
        print("Update Spend Time:", os.clock() - update_start_time)
        print("--------------STOP UPDATE--------------")
    end
end

local _WallUpdate = WallUpdate
function WallUpdate(dt, ...)
    if pl_ProfilerPop then
        print("--------------START WALLUPDATE--------------")
        update_start_time = os.clock()
    end

    _WallUpdate(dt, ...)

    if pl_ProfilerPop then
        print("WallUpdate Spend Time:", os.clock() - update_start_time)
        print("--------------STOP WALLUPDATE--------------")
    end
end

local scheduled_post_update_functions = {}

local post_update = PostUpdate
function PostUpdate(dt, ...)
    post_update(dt, ...)

    for _, fn in ipairs(scheduled_post_update_functions) do
        fn()
    end
    scheduled_post_update_functions = {}
end

function RunOnPostUpdate(fn)
    table.insert(scheduled_post_update_functions, fn)
end

local last_profiler_time = os.clock()
local last_profiler_name = "default"

local _ProfilerPush = Sim.ProfilerPush
function Sim.ProfilerPush(sim, name, ...)
    last_profiler_time = os.clock()
    last_profiler_name = name
    return _ProfilerPush(sim, name, ...)
end

local _ProfilerPop = Sim.ProfilerPop
function Sim.ProfilerPop(sim, ...)
    if pl_ProfilerPop then
        local spend_time = os.clock() - last_profiler_time
        print("ProfilerPop", last_profiler_name, spend_time)
    end
    return _ProfilerPop(sim, ...)
end