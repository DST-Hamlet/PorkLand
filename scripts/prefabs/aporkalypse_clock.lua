local aporkalypse_clock_assets =
{
    Asset("ANIM", "anim/porkalypse_totem.zip")
}

local aporkalypse_marker_assets =
{
    Asset("ANIM", "anim/porkalypse_clock_marker.zip")
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

local function StartRewind(inst)
    if inst.rewind then
        return
    end

    inst.SoundEmitter:KillSound("base_sound")

    if inst.rewind_mult < 0 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_backwards_LP", "rewind_sound")
    else
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_fast_LP", "rewind_sound")
    end

    inst.rewind = true
end

local function StopRewind(inst)
    if not inst.rewind then
        return
    end

    inst.SoundEmitter:KillSound("rewind_sound")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_LP", "base_sound")

    inst.rewind = false
end

local function PlayClockAnimation(inst, anim)
    for _, clock in ipairs(inst.clocks or {}) do
        clock.AnimState:PlayAnimation(anim .. "_shake", false)
        clock.AnimState:PushAnimation(anim .. "_idle")
    end
end

local function OnClockTick(inst, data)
    local time_utill_aporkalypse = 0
    local aporkalypse = TheWorld.net and TheWorld.net.components.aporkalypse

    if aporkalypse then
        time_utill_aporkalypse = math.max(aporkalypse:GetTimeUntilAporkalypse(), 0)

        if inst.rewind then
            -- if aporkalypse:IsActive() then
            --     aporkalypse:EndAporkalypse()
            -- end

            -- I'd like to use dt but update for season-switch can mess with it bigtime
            -- local dt = math.clamp(data.dt, 0, 2 * TheSim:GetTickTime())
            -- time_utill_aporkalypse = time_utill_aporkalypse - inst.rewind_mult * dt * 250
            -- aporkalypse:ScheduleAporkalypse(GetClock():GetTotalTime() + time_utill_aporkalypse)
        end
    end

    for i, clock in ipairs(inst.clocks) do
        local angle = time_utill_aporkalypse / TUNING.APORKALYPSE_PERIOD_LENGTH * 360 * rotation_speeds[i]
        set_rotation(clock, angle)
    end
end

local function OnBeginAporkalypse(inst, data)
    inst:PlayClockAnimation("on")

    inst.SoundEmitter:KillSound("totem_sound")
    inst.SoundEmitter:KillSound("base_sound")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/stone_door/close")

    ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, .5, inst)

    inst.AnimState:PushAnimation("idle_pst", false)
    inst.AnimState:PushAnimation("idle_on")
end

local function OnEndAporkalypse(inst, data)
    inst:PlayClockAnimation("off")

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/totem_LP", "totem_sound")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_LP", "base_sound")

    inst.AnimState:PushAnimation("idle_pre", false)
    inst.AnimState:PushAnimation("idle_loop")
end

local function OnRemoveEntity(inst)
    if not inst.aporkalypse_clock then
        return
    end

    for i, clock in ipairs(inst.aporkalypse_clockclocks.clocks or {}) do
        if clock == inst then
            table.remove(inst.clocks, i)
        end
    end

    for i, plate in ipairs(inst.aporkalypse_clock.plates or {}) do
        if plate == inst then
            table.remove(inst.clocks, i)
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

    local isaporkalypse = TheWorld.net and TheWorld.net.components.aporkalypse and TheWorld.net.components.aporkalypse:IsActive()
    if isaporkalypse then
        inst.AnimState:PlayAnimation("idle_on")
        inst:playclockanimation("on")
    end
end

local function aporkalypse_clock_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("porkalypse_clock.tex")

    inst.AnimState:SetBank("totem")
    inst.AnimState:SetBuild("porkalypse_totem")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/totem_LP", "totem_sound")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_LP", "base_sound")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.clocks = {}
    inst.plates = {}
    inst.StartRewind = StartRewind
    inst.StopRewind = StopRewind
    inst.PlayClockAnimation = PlayClockAnimation

    inst:AddComponent("inspectable")

    inst.OnClockTick = OnClockTick
    inst:ListenForEvent("clocktick", function(src, data) inst:OnClockTick(data) end, TheWorld)

    inst.OnBeginAporkalypse = OnBeginAporkalypse
    inst:ListenForEvent("beginaporkalypse", function(src, data) inst:OnBeginAporkalypse(data) end, TheWorld)

    inst.OnEndAporkalypse = OnEndAporkalypse
    inst:ListenForEvent("endaporkalypse", function(src, data) inst:OnEndAporkalypse(data) end, TheWorld)

    inst:DoTaskInTime(0, DoPostInit)

    return inst
end

local function aporkalypse_marker_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
	inst.entity:AddAnimState()

    inst.AnimState:SetBuild("porkalypse_clock_marker")
	inst.AnimState:SetBank("clock_marker")
	inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(0)

    inst.persists = false

    return inst
end

local function OnNear(inst)
    if not inst.down then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/pressure_plate/hit")
        inst.AnimState:PlayAnimation("popdown")
        inst.AnimState:PushAnimation("down_idle")
        inst.down = true

        if inst.aporkalypse_clock then
            inst.aporkalypse_clock.rewind_mult = 1
            inst.aporkalypse_clock:StartRewind()
        end
    end
end

local function OnFar(inst)
    if inst.down then
        inst.AnimState:PlayAnimation("popup")
        inst.AnimState:PushAnimation("up_idle")
        inst.down = false

        if inst.aporkalypse_clock then
            inst.aporkalypse_clock:StopRewind()
        end
    end
end

local function FindTest(fined, inst)
    return not fined:HasTag("flying")
end

local function Makeplate(name, build)
    local assets =
    {
        Asset("ANIM", "anim/pressure_plate.zip"),
        Asset("ANIM", "anim/".. build .. ".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()

        inst.AnimState:SetBank("pressure_plate")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("up_idle")

        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst:AddTag("structure")
        inst:AddTag("weighdownable")  -- ?

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst.down = false

        inst:AddComponent("creatureprox")
        inst.components.creatureprox.inventorytrigger = true
        inst.components.creatureprox:SetDist(0.8, 0.9)
        inst.components.creatureprox:SetOnNear(OnNear)
        inst.components.creatureprox:SetOnFar(OnFar)
        inst.components.creatureprox:SetFindTestFn(FindTest)

        return inst
    end

    return Prefab("common/objects/" .. name, fn, assets)
end

local function MakeClock(clock_num)
    local name = "aporkalypse_clock" .. clock_num
    local bank = "clock_0" .. clock_num
    local build = "porkalypse_clock_0" .. clock_num
    local sort_order = clock_num

    local assets = {
        Asset("ANIM", "anim/".. build .. ".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst:AddTag("OnFloor")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("off_idle")

        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetFinalOffset(sort_order)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

        inst.persists = false

        return inst
    end

    return Prefab("common/objects/" .. name, fn, assets)
end

return Prefab("common/objects/aporkalypse_clock", aporkalypse_clock_fn, aporkalypse_clock_assets),
    Prefab("common/objects/aporkalypse_marker", aporkalypse_marker_fn, aporkalypse_marker_assets),
    Makeplate("aporkalypse_rewind_plate", "pressure_plate_forwards_build"),
    Makeplate("aporkalypse_fastforward_plate", "pressure_plate_backwards_build"),
    MakeClock(1),
    MakeClock(2),
    MakeClock(3)
