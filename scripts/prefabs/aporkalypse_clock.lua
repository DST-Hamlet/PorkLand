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
    end

    inst._clock_spawndirty:push()
end

local function RegistClocks(inst)
    inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/totem_LP", "totem_sound")
    inst.SoundEmitter:PlaySound("porkland_soundpackage/common/objects/aporkalypse_clock/base_LP", "base_sound")

    for i, v in ipairs(clock_prefabs) do
        local clock = TheSim:FindFirstEntityWithTag(v)
        if clock then
            inst._clocks[i] = clock
        end
    end
end

local function ClientPerdictRotation(inst, dt)
    inst._timeuntilaporkalypse:set_local(inst._timeuntilaporkalypse:value() - dt - inst._rewind_mult:value() * 250 * dt)
    for k, clock in pairs(inst._clocks) do
        local angle = inst._timeuntilaporkalypse:value() / TUNING.APORKALYPSE_PERIOD_LENGTH * 360 * rotation_speeds[k]
        set_rotation(clock, angle)
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
    inst._clock_spawndirty = net_event(inst.GUID, "_clock_spawndirty", "clock_spawndirty")
    inst._timeuntilaporkalypse = net_float(inst.GUID, "_timeuntilaporkalypse")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst._clocks = {}
        inst:ListenForEvent("clock_spawndirty", RegistClocks)
        inst:DoTaskInTime(0, RegistClocks)

        inst.oldtimeuntilaporkalypse = 0
        inst:DoPeriodicTask(FRAMES, function(inst)
            if inst.oldtimeuntilaporkalypse == inst._timeuntilaporkalypse:value() then
                ClientPerdictRotation(inst, FRAMES, true)
            end
            inst.oldtimeuntilaporkalypse = inst._timeuntilaporkalypse:value()
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

    MakeHauntableWork(inst)

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
