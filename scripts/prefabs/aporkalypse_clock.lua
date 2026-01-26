local aporkalypse_clock_assets =
{
    Asset("ANIM", "anim/aporkalypse_totem.zip")
}

local aporkalypse_marker_assets =
{
    Asset("ANIM", "anim/aporkalypse_clock_marker.zip")
}

local clock_prefabs =
{
    "aporkalypse_clock1",
    "aporkalypse_clock2",
    "aporkalypse_clock3",
}

local plate_prefabs =
{
    ["aporkalypse_rewind_plate"] = {x = 6, z = 6},
    ["aporkalypse_fastforward_plate"] = {x = 6, z = -6},
}

local rotation_speeds = {1, 60, 2}  -- total rotations for each disc in a full aporkalypse cycle

local function set_rotation(inst, angle)
    inst.Transform:SetRotation(angle + 90)
end

local function PlayClockAnimation(inst, anim)
    for _, clock in ipairs(inst.clocks or {}) do
        clock.AnimState:PlayAnimation(anim .. "_shake", false)
        clock.AnimState:PushAnimation(anim .. "_idle")
    end
end

local function OnRewindMultChange(inst, rewind_mult)
    inst._rewind_mult:set(rewind_mult)
    if rewind_mult == 0 then  -- stop rewind
        inst.SoundEmitter:KillSound("rewind_sound")
        inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/base_LP", "base_sound")

        inst.rewind = false
    else  -- start rewind
        inst.SoundEmitter:KillSound("base_sound")

        if rewind_mult < 0 then
            inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/base_backwards_LP", "rewind_sound")
        elseif rewind_mult > 0 then
            inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/base_fast_LP", "rewind_sound")
        end

        inst.rewind = true
    end
end

local function OnAporkalypseClockTick(inst, data)
    if TheWorld.state.isaporkalypse and inst.rewind then
        TheWorld:PushEvent("ms_stopaporkalypse")
    end

    local timeuntilaporkalypse = math.max(data.timeuntilaporkalypse or 0, 0)
    inst._timeuntilaporkalypse:set(data.timeuntilaporkalypse)
    for i, clock in ipairs(inst.clocks) do
        local angle = timeuntilaporkalypse / TUNING.APORKALYPSE_PERIOD_LENGTH * 360 * rotation_speeds[i]
        set_rotation(clock, angle)
    end
end

local function OnStartAporkalypse(inst, data)
    inst:PlayClockAnimation("on")

    inst.SoundEmitter:KillSound("totem_sound")
    inst.SoundEmitter:KillSound("base_sound")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/stone_door/close")

    ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, .5, inst)

    inst.AnimState:PushAnimation("idle_pst", false)
    inst.AnimState:PushAnimation("idle_on")
end

local function OnStopAporkalypse(inst, data)
    inst:PlayClockAnimation("off")

    inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/totem_LP", "totem_sound")
    inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/base_LP", "base_sound")

    inst.AnimState:PushAnimation("idle_pre", false)
    inst.AnimState:PushAnimation("idle_loop")
end

local function OnRemoveEntity(inst)
    local aporkalypse_clock = inst.aporkalypse_clocks
    if not aporkalypse_clock then
        return
    end

    for i, clock in ipairs(aporkalypse_clock.clocks or {}) do
        if clock == inst then
            table.remove(aporkalypse_clock.clocks, i)
        end
    end

    for i, plate in ipairs(aporkalypse_clock.plates or {}) do
        if plate == inst then
            table.remove(aporkalypse_clock.clocks, i)
        end
    end
end

local function DoPostInit(inst)
    local marker = inst:SpawnChild("aporkalypse_marker")
    marker.aporkalypse_clock = inst
    marker.Transform:SetRotation(90)

    for _, v in ipairs(clock_prefabs) do
        local clock = inst:SpawnChild(v)
        clock.Transform:SetRotation(90)

        clock.aporkalypse_clock = inst
        clock.OnRemoveEntity = OnRemoveEntity

        table.insert(inst.clocks, clock)
    end

    for prefab, data in pairs(plate_prefabs) do
        local plate = inst:SpawnChild(prefab)
        plate.Transform:SetPosition(data.x, 0, data.z)

        plate.aporkalypse_clock = inst
        plate.OnRemoveEntity = OnRemoveEntity

        table.insert(inst.plates, plate)
    end

    if TheWorld.state.isaporkalypse then
        inst.SoundEmitter:KillSound("totem_sound")
        inst.SoundEmitter:KillSound("base_sound")

        inst.AnimState:PlayAnimation("idle_on")
        inst:PlayClockAnimation("on")
    else
        inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/totem_LP", "totem_sound")
        inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/base_LP", "base_sound")
    end

    inst._clock_spawndirty:push()
end

local function RegistClocks(inst)
    for i, v in ipairs(clock_prefabs) do
        local clock = TheSim:FindFirstEntityWithTag(v)
        if clock then
            inst._clocks[i] = clock
        end
    end
end

local function ClientUpdateRotation(inst, dt)
    if TheWorld.state.isaporkalypse then
        return
    end

    local clocks = inst.clocks or inst._clocks
    if inst.client_angle then
        for k, clock in pairs(clocks) do
            local angle = inst.client_angle / TUNING.APORKALYPSE_PERIOD_LENGTH * 360 * rotation_speeds[k]
            set_rotation(clock, angle)
        end
    end

    if inst.count_dt > 0 then
        if inst.client_angle then
            if inst.interpolation_dt > 0 then -- 先插值
                inst.interpolation_dt = inst.interpolation_dt - inst.count_dt
                inst.client_angle = inst.client_angle + inst.count_dt * inst.client_speed
            else -- 插值结束后, 如果没有收到新的服务器信息, 则进行预测
                local offset = - inst.count_dt - inst._rewind_mult:value() * 250 * inst.count_dt
                inst.client_angle = inst.client_angle + offset
            end

            if inst.client_angle > TUNING.APORKALYPSE_PERIOD_LENGTH then
                inst.client_angle = inst.client_angle - TUNING.APORKALYPSE_PERIOD_LENGTH
            elseif inst.client_angle < 0 then
                inst.client_angle = inst.client_angle + TUNING.APORKALYPSE_PERIOD_LENGTH
            end
        end
        inst.should_update_time = false
        inst.count_dt = 0
    end
end

local function aporkalypse_clock_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .45)

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("porkalypse_clock.tex")

    inst.AnimState:SetBank("totem")
    inst.AnimState:SetBuild("aporkalypse_totem")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst._rewind_mult = net_float(inst.GUID, "_rewind_mult", "rewind_mult_dirty")
    inst._clock_spawndirty = net_event(inst.GUID, "_clock_spawndirty")
    inst._timeuntilaporkalypse = net_float(inst.GUID, "_timeuntilaporkalypse")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst._clocks = {}
        inst:ListenForEvent("_clock_spawndirty", RegistClocks)
        inst:DoStaticTaskInTime(0, RegistClocks)

        inst.count_dt = 0
        inst.interpolation_dt = 0
        inst.client_speed = 0
        inst.last_sync_time = 0

        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnWallUpdateFn(function(inst, dt)

            if TheWorld.net.components.worldtimesync:IsCurrentFrameSynced()
                and inst.last_sync_time ~= TheWorld.net.components.worldtimesync:GetServerTime() then -- 说明此帧客户端已经使用了服务器的数据进行覆盖

                inst.last_sync_time = TheWorld.net.components.worldtimesync:GetServerTime()
                if not inst.client_angle then
                    inst.client_angle = inst._timeuntilaporkalypse:value()
                    inst.target_angle = inst._timeuntilaporkalypse:value()
                end
                inst.target_angle = inst._timeuntilaporkalypse:value()
                inst.interpolation_dt = math.min(FRAMES * 4 - TheWorld.net.components.worldtimesync:GetDeltaTime(), FRAMES * 2) -- 旋转插值的持续时间, 最多30个逻辑帧

                if inst.client_angle > 0.8 * TUNING.APORKALYPSE_PERIOD_LENGTH and
                    inst.target_angle < 0.2 * TUNING.APORKALYPSE_PERIOD_LENGTH then

                    inst.client_speed = (inst.target_angle - inst.client_angle + TUNING.APORKALYPSE_PERIOD_LENGTH)
                        / inst.interpolation_dt

                elseif inst.client_angle < 0.2 * TUNING.APORKALYPSE_PERIOD_LENGTH and
                    inst.target_angle > 0.8 * TUNING.APORKALYPSE_PERIOD_LENGTH then

                    inst.client_speed = (inst.target_angle - inst.client_angle - TUNING.APORKALYPSE_PERIOD_LENGTH)
                        / inst.interpolation_dt

                else
                    inst.client_speed = (inst.target_angle - inst.client_angle)
                        / inst.interpolation_dt
                end
            end

            print(inst.client_angle, inst.target_angle, inst.client_speed, inst.interpolation_dt)

            inst.count_dt = inst.count_dt + dt
            inst:RunOnPostUpdate(function() ClientUpdateRotation(inst, dt) end)
        end)

        return inst
    end

    inst.clocks = {}
    inst.plates = {}
    inst.rewind = false
    inst.PlayClockAnimation = PlayClockAnimation

    inst:AddComponent("inspectable")

    inst.OnRewindMultChange = OnRewindMultChange
    inst:ListenForEvent("rewindmultchange", function(src, rewind_mult) inst:OnRewindMultChange(rewind_mult) end, TheWorld)

    inst.OnAporkalypseClockTick = OnAporkalypseClockTick
    inst:ListenForEvent("aporkalypseclocktick", function(src, data) inst:OnAporkalypseClockTick(data) end, TheWorld)

    inst:WatchWorldState("startaporkalypse", OnStartAporkalypse)
    inst:WatchWorldState("stopaporkalypse", OnStopAporkalypse)

    inst:DoTaskInTime(0, DoPostInit)

    MakeHauntable(inst)

    return inst
end

local function aporkalypse_marker_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")

    inst.AnimState:SetBuild("aporkalypse_clock_marker")
    inst.AnimState:SetBank("clock_marker")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(0)

    inst.entity:SetPristine()

    inst.persists = false

    return inst
end

local function MakeClock(clock_num)
    local name = "aporkalypse_clock" .. clock_num
    local bank = "clock_0" .. clock_num
    local build = "aporkalypse_clock_0" .. clock_num
    local sort_order = clock_num

    local assets = {
        Asset("ANIM", "anim/".. build .. ".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("NOCLICK")
        inst:AddTag(name)

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("off_idle")

        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetFinalOffset(sort_order)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

        inst.entity:SetPristine()

        inst.persists = false

        return inst
    end

    return Prefab(name, fn, assets)
end

return Prefab("aporkalypse_clock", aporkalypse_clock_fn, aporkalypse_clock_assets),
    Prefab("aporkalypse_marker", aporkalypse_marker_fn, aporkalypse_marker_assets),
    MakeClock(1),
    MakeClock(2),
    MakeClock(3)
