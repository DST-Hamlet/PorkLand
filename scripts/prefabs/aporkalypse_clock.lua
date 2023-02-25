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

local function SetRewindMult(inst, rewind_mult)
    inst.rewind_mult = rewind_mult

    if inst.rewind_mult == 0 then  -- stop rewind
        inst.SoundEmitter:KillSound("rewind_sound")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_LP", "base_sound")

        inst.rewind = false
    else  -- start rewind
        inst.SoundEmitter:KillSound("base_sound")

        if inst.rewind_mult < 0 then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_backwards_LP", "rewind_sound")
        elseif inst.rewind_mult > 0 then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_fast_LP", "rewind_sound")
        end

        inst.rewind = true
    end
end

local function PlayClockAnimation(inst, anim)
    for _, clock in ipairs(inst.clocks or {}) do
        clock.AnimState:PlayAnimation(anim .. "_shake", false)
        clock.AnimState:PushAnimation(anim .. "_idle")
    end
end

local function OnAporkalypseClockTick(inst, data)
    local time_until_aporkalypse = math.max(data.time_until_aporkalypse or 0, 0)
    local aporkalypse = TheWorld.net and TheWorld.net.components.aporkalypse

    if aporkalypse then
        if inst.rewind then
            if aporkalypse:IsActive() then
                aporkalypse:EndAporkalypse()
            end

            -- local dt = math.clamp(data.dt, 0, 2 * TheSim:GetTickTime())
            time_until_aporkalypse = time_until_aporkalypse - inst.rewind_mult * data.dt * 250
            aporkalypse:ScheduleAporkalypse(time_until_aporkalypse)
        end
    end

    for i, clock in ipairs(inst.clocks) do
        local angle = time_until_aporkalypse / TUNING.APORKALYPSE_PERIOD_LENGTH * 360 * rotation_speeds[i]
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

    local isaporkalypse = TheWorld.net and TheWorld.net.components.aporkalypse and TheWorld.net.components.aporkalypse:IsActive()
    if isaporkalypse then
        inst.SoundEmitter:KillSound("totem_sound")
        inst.SoundEmitter:KillSound("base_sound")

        inst.AnimState:PlayAnimation("idle_on")
        inst:PlayClockAnimation("on")
    end
end

local function aporkalypse_clock_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("aporkalypse_clock.tex")

    inst.AnimState:SetBank("totem")
    inst.AnimState:SetBuild("aporkalypse_totem")
    inst.AnimState:PlayAnimation("idle_loop", true)

    if not TheNet:IsDedicated() then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/totem_LP", "totem_sound")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/aporkalypse_clock/base_LP", "base_sound")
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.clocks = {}
    inst.plates = {}
    inst.rewind_mult = 0
    inst.SetRewindMult = SetRewindMult
    inst.PlayClockAnimation = PlayClockAnimation

    inst:AddComponent("inspectable")

    inst.OnAporkalypseClockTick = OnAporkalypseClockTick
    inst:ListenForEvent("aporkalypseclocktick", function(src, data) inst:OnAporkalypseClockTick(data) end, TheWorld)

    inst.OnBeginAporkalypse = OnBeginAporkalypse
    inst:ListenForEvent("beginaporkalypse", function(src, data) inst:OnBeginAporkalypse(data) end, TheWorld)

    inst.OnEndAporkalypse = OnEndAporkalypse
    inst:ListenForEvent("endaporkalypse", function(src, data) inst:OnEndAporkalypse(data) end, TheWorld)

    inst:DoTaskInTime(0, DoPostInit)

    MakeHauntableWork(inst)

    return inst
end

local function aporkalypse_marker_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

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

local function SetOnPlayerNear(inst)
    if not inst.down then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/items/pressure_plate/hit")
        inst.AnimState:PlayAnimation("popdown")
        inst.AnimState:PushAnimation("down_idle")
        inst.down = true

        local aporkalypse_clock = inst.aporkalypse_clock
        if aporkalypse_clock then
            aporkalypse_clock:SetRewindMult((aporkalypse_clock.rewind_mult or 0) + inst.rewind_mult)  -- to fix trigger two plate at the same time
        end
    end
end

local function SetOnPlayerFar(inst)
    if inst.down then
        inst.AnimState:PlayAnimation("popup")
        inst.AnimState:PushAnimation("up_idle")
        inst.down = false

        local aporkalypse_clock = inst.aporkalypse_clock
        if aporkalypse_clock then
            local rewind_mult = 0

            for _, plate in ipairs(aporkalypse_clock.plates or {}) do  -- to fix trigger two plate at the same time
                if plate ~= inst and plate.down then
                    rewind_mult = rewind_mult + plate.rewind_mult
                end
            end

            aporkalypse_clock:SetRewindMult(rewind_mult)
        end
    end
end

local function Makeplate(name, build, rewind_mult)
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
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("pressure_plate")
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("up_idle")

        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst:AddTag("structure")
        inst:AddTag("weighdownable")  -- ?

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst.rewind_mult = rewind_mult
        inst.down = false

        inst:AddComponent("playerprox")
        inst.components.playerprox.alivemode = true
        inst.components.playerprox:SetDist(0.8, 0.9)
        inst.components.playerprox:SetOnPlayerNear(SetOnPlayerNear)
        inst.components.playerprox:SetOnPlayerFar(SetOnPlayerFar)

        return inst
    end

    return Prefab("common/objects/" .. name, fn, assets)
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

        inst:AddTag("OnFloor")

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

    return Prefab("common/objects/" .. name, fn, assets)
end

return Prefab("common/objects/aporkalypse_clock", aporkalypse_clock_fn, aporkalypse_clock_assets),
    Prefab("common/objects/aporkalypse_marker", aporkalypse_marker_fn, aporkalypse_marker_assets),
    Makeplate("aporkalypse_rewind_plate", "pressure_plate_forwards_build", -1),
    Makeplate("aporkalypse_fastforward_plate", "pressure_plate_backwards_build", 1),
    MakeClock(1),
    MakeClock(2),
    MakeClock(3)
