GLOBAL.setfenv(1, GLOBAL)

function CalculateLight(light, dist)
    if dist > light:GetCalculatedRadius() then
        return 0, 0, 0
    end
    if light:GetRadius() == 0 then
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

local REGISTERED_LIGHT_TAGS = TheSim:RegisterFindTags({"lightsource"}, {"INLIMBO"})
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
            for _, v in ipairs(TheSim:FindEntities_Registered(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, REGISTERED_LIGHT_TAGS)) do
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

local sim_visualambientcolour = nil

local old_SetVisualAmbientColour = Sim.SetVisualAmbientColour
Sim.SetVisualAmbientColour = function(sim, r, g, b, ...)
    if r and g and b then
        sim_visualambientcolour = {r * 255, g * 255, b * 255}
    else
        sim_visualambientcolour = nil
    end
    return old_SetVisualAmbientColour(sim, r, g, b, ...)
end

Sim.GetVisualAmbientColour = function(sim)
    if sim_visualambientcolour then
        return unpack(sim_visualambientcolour)
    end
    return Sim.GetAmbientColour(sim)
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

local mousetest_rotatingbillboard = {}

function SetRotatingBillBoardTest(entity, active) -- 会造成额外的性能开销
    mousetest_rotatingbillboard[entity] = active
end

local _GetEntitiesAtScreenPoint = Sim.GetEntitiesAtScreenPoint
Sim.GetEntitiesAtScreenPoint = function(sim, screen_x, screen_y, dont_ignore_ui, ...)
    local entities = _GetEntitiesAtScreenPoint(sim, screen_x, screen_y, dont_ignore_ui, ...)
    if entities[1] and entities[1].UITransform then
        -- Do Nothing
    elseif next(mousetest_rotatingbillboard) then
        for i = #entities, 1, -1 do
            if entities[i] and mousetest_rotatingbillboard[entities[i]] then
                table.remove(entities,i)
            end
        end

        local rb_entities = {}

        local origin_pos = Vector3(TheSim:ProjectScreenPos(screen_x, screen_y))
        local plane_pos
        local plane_normal = Vector3(2, 1, 0)
        local camera_pos = TheCamera:GetRealPos()
        local mouse_dir = (origin_pos - camera_pos):Normalize()
        local fake_pos
        for entity in pairs(mousetest_rotatingbillboard) do
            if entity == nil or not entity:IsValid() then
                mousetest_rotatingbillboard[entity] = nil
            else
                plane_pos = entity:GetPosition()
                if plane_pos and plane_pos:DistSq(origin_pos) < PLAYER_CAMERA_SEE_DISTANCE * PLAYER_CAMERA_SEE_DISTANCE then
                    fake_pos = PlaneLineIntersection(plane_pos, plane_normal, camera_pos, mouse_dir)

                    fake_pos = fake_pos + Vector3(- fake_pos.y * 0.03, fake_pos.y * 0.06, 0)
                    fake_pos = fake_pos + Vector3(- fake_pos.y * 0.5, - fake_pos.y, 0)

                    local angle = 90 * DEGREES
                    local d_pos = fake_pos - plane_pos
                    if entity.Transform:GetRotation() < 0 or entity.Transform:GetRotation() > 180 then -- 由于目前平面法线向量是固定的, 因此需要这么做
                        d_pos.z = - d_pos.z
                    end
                    d_pos = Vector3(d_pos.x * math.cos(angle) - d_pos.z * math.sin(angle), d_pos.y, d_pos.x * math.sin(angle) + d_pos.z * math.cos(angle))
                    fake_pos = plane_pos + d_pos

                    local fakse_screen_x, fakse_screen_y = TheSim:GetScreenPos(fake_pos:Get())

                    local entities_fake = _GetEntitiesAtScreenPoint(sim, fakse_screen_x, fakse_screen_y, false, ...)
                    for i, v in ipairs(entities_fake) do
                        if v == entity then
                            table.insert(rb_entities, entity)
                            break
                        end
                    end
                end
            end
        end

        for k, v in pairs(rb_entities) do
            for i = 1, #entities + 1 do
                if entities[i] == nil then
                    table.insert(entities, i, v)
                    break
                end
                if entities[i].Transform and TheCamera:GetPosDepth(v:GetPosition()) < TheCamera:GetPosDepth(entities[i]:GetPosition()) then
                    table.insert(entities, i, v)
                    break
                end
            end
        end
    end

    for i = #entities, 1, -1 do
        if entities[i] and entities[i].MouseTest and not entities[i]:MouseTest() then
            table.remove(entities,i)
        end
    end

    return entities
end


-------------------------------------------------

------------ EntitySleep and Update -------------

-------------------------------------------------


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

scheduled_prefabs = {}
scheduler_hooked = false

local _Update = Update
function Update(dt, ...)
    -- if not scheduler_hooked then
    --     local Scheduler = getmetatable(scheduler).__index
    --     local _ExecutePeriodic = Scheduler.ExecutePeriodic
    --     function Scheduler:ExecutePeriodic(period, fn, limit, initialdelay, id, ...)
    --         local hooked_fn = function(...)
    --             if id and Ents[id] and Ents[id].prefab then
    --                 scheduled_prefabs[Ents[id].prefab] = scheduled_prefabs[Ents[id].prefab] and scheduled_prefabs[Ents[id].prefab] + 1 or 1
    --             end
    --             return fn(...)
    --         end
    --         return _ExecutePeriodic(self, period, hooked_fn, limit, initialdelay, id, ...)
    --     end
    --     scheduler_hooked = true
    -- end
    -- scheduled_prefabs = {}

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

    -- local count_s = 0
    -- for k, v in pairs(scheduled_prefabs) do
    --     count_s = count_s + v
    --     print(k, v)
    -- end
    -- print("------------------------")
    -- print("count", count_s)
    -- print("------------------------")
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
