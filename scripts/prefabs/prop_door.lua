local assets =
{
    Asset("ANIM", "anim/pig_door_test.zip"),
    Asset("ANIM", "anim/pig_ruins_door.zip"),
    Asset("ANIM", "anim/pig_ruins_door_blue.zip"),
    Asset("ANIM", "anim/bat_cave_door.zip"),
    Asset("ANIM", "anim/ruins_stairs.zip"),
    Asset("ANIM", "anim/ant_cave_door.zip"),
    Asset("ANIM", "anim/pig_shop_doormats.zip"),
    Asset("ANIM", "anim/ant_hill_entrance.zip"),
    Asset("ANIM", "anim/ant_queen_entrance.zip"),

    Asset("ANIM", "anim/player_house_doors.zip"),
}

local lights =
{
    day  = {rad = 3, intensity = 0.75, falloff = 0.5, color = {1, 1, 1}},
    dusk = {rad = 2, intensity = 0.75, falloff = 0.5, color = {1 / 1.8, 1 / 1.8, 1 / 1.8}},
    full = {rad = 2, intensity = 0.75, falloff = 0.5, color = {0.8 / 1.8, 0.8 / 1.8, 1 / 1.8}}
}

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
end

local phase_functions = {
    day = function(inst)
        if inst:HasTag("timechange_anims") then
            inst.AnimState:PlayAnimation("to_day")
            inst.AnimState:PushAnimation("day_loop", true)
        end

        if not inst.Light then
            return
        end

        if not inst:IsInLimbo() then
            inst.Light:Enable(true)
        end

        inst.components.lighttweener:StartTween(nil, lights.day.rad, lights.day.intensity, lights.day.falloff,
            {lights.day.color[1], lights.day.color[2], lights.day.color[3]}, 2)
    end,

    dusk = function(inst)
        if inst:HasTag("timechange_anims") then
            inst.AnimState:PlayAnimation("to_dusk")
            inst.AnimState:PushAnimation("dusk_loop", true)
        end

        if not inst.Light then
            return
        end

        if not inst:IsInLimbo() then
            inst.Light:Enable(true)
        end

        inst.components.lighttweener:StartTween(nil, lights.dusk.rad, lights.dusk.intensity, lights.dusk.falloff,
            {lights.dusk.color[1], lights.dusk.color[2], lights.dusk.color[3]}, 2)
    end,

    night = function(inst)
        if inst:HasTag("timechange_anims") then
            inst.AnimState:PlayAnimation("to_night")
            inst.AnimState:PushAnimation("night_loop", true)
        end

        if not inst.Light then
            return
        end

        if TheWorld.state.moonphase == "full" then
            inst.components.lighttweener:StartTween(nil, lights.full.rad, lights.full.intensity, lights.full.falloff,
                {lights.full.color[1], lights.full.color[2], lights.full.color[3]}, 4)
        else
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0, 0, 0}, 6, turnoff)
        end
    end,
}

local function OnPhaseChange(inst, phase)
    phase_functions[phase](inst)
end

local function MakeTimeChanger(inst)
    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, lights.day.rad, lights.day.intensity, lights.day.falloff,
        {lights.day.color[1], lights.day.color[2], lights.day.color[3]}, 0)
    inst.Light:Enable(true)

    inst:WatchWorldState("phase", OnPhaseChange)
    OnPhaseChange(inst, TheWorld.state.phase)

    inst.timechanger = true
end

local function UpdateDoorLight(inst)
    if inst.components.door then
        local interior_spawner = TheWorld.components.interiorspawner
        local targetdoor = interior_spawner.doors[inst.components.door.target_door_id].inst
        local r, g, b, light = targetdoor:GetColourAndLight()
        if light > TUNING.DARK_CUTOFF then
            inst.Light:Enable(true)
            inst.Light:SetFalloff(0.8)
            inst.Light:SetIntensity(TUNING.DARK_CUTOFF + (light - TUNING.DARK_CUTOFF) / 2)
            inst.Light:SetRadius(3 + light)
            inst.Light:SetColour(r,g,b)
        else
            inst.Light:Enable(false)
        end
    end
end

local function StartDoorLightUpdate(inst)
    if not inst.doorlighttask then
        inst.doorlighttask = inst:DoPeriodicTask(0, UpdateDoorLight)
    end
end

local function StopDoorLightUpdate(inst)
    if inst.doorlighttask then
        inst.doorlighttask:Cancel()
        inst.doorlighttask = nil
        inst.Light:Enable(false)
    end
end

local function EnableDoorLightUpdate(inst, enable)
    inst.doorlightenable = enable
    if enable then
        if not inst:IsAsleep() then
            inst:StartDoorLightUpdate()
        end
    else
        inst:StopDoorLightUpdate()
    end
end

-- TODO: Combine these two and add a getter
local function SetMinimapIcon(inst, icon)
    inst.minimapicon = icon
    inst._minimap_name:set(icon)
end

local function InitInteriorPrefab(inst, doer, prefab_definition, interior_definition)
    --If we are spawned inside of a building, then update our door to point at our interior
    local door_definition =
    {
        my_interior_name = interior_definition.unique_name,
        my_door_id = prefab_definition.my_door_id,
        target_door_id = prefab_definition.target_door_id,
        target_interior = prefab_definition.target_interior,
    }

    if prefab_definition.is_exit then
        door_definition.target_interior = "EXTERIOR"
        door_definition.target_exterior = prefab_definition.target_exterior
    end

    TheWorld.components.interiorspawner:AddDoor(inst, door_definition)

    if prefab_definition.scale then
        inst.Transform:SetScale(prefab_definition.scale, prefab_definition.scale, prefab_definition.scale)
    end

    if prefab_definition.make_obstacle then
        -- TODO: 测试一下这个是否可以在服务器生效
        MakeObstaclePhysics(inst, prefab_definition.obstacle_scale)
        inst.Physics:SetActive(true)
    end

    if inst.components.door then
        inst.components.door:UpdateDoorVis()
    end

    local animdata = prefab_definition.animdata

    if not animdata then
        print("prefab_definition passed to InitInteriorPrefab is a nil value!", inst)
        return
    end

    inst.components.rotatingbillboard:SetAnimation_Server(animdata)

    inst.AnimState:SetBank(animdata.bank)
    inst.door_data_bank = animdata.bank

    inst.AnimState:SetBuild(animdata.build)
    inst.door_data_build = animdata.build

    inst.AnimState:PlayAnimation(animdata.anim, true)
    inst.door_data_animstate = animdata.anim
    -- this is for finding the right open and closed door animation.
    inst.baseanimname = inst.door_data_animstate

    if animdata.background then
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        --inst.Transform:SetTwoFaced()
        -- inst.Transform:SetRotation(90)

        inst.door_data_background = animdata.background
    end

    if animdata.light then
        MakeTimeChanger(inst)
    else
        EnableDoorLightUpdate(inst, true)
    end

    if animdata.minimapicon then
        local minimap = inst.entity:AddMiniMapEntity()
        minimap:SetIcon(animdata.minimapicon)

        inst:SetMinimapIcon(animdata.minimapicon)
    end
end

local function InitHouseDoor(inst, dir)
    inst.door_data_animstate = dir
    inst.baseanimname = dir
    inst.AnimState:PlayAnimation(dir .. "_open")
    inst.AnimState:PushAnimation(dir, true)
end

local function OnSave(inst, data)
    local scale_x, scale_y, scale_z = inst.Transform:GetScale()
    data.scalex = scale_x
    data.scaley = scale_y
    data.scalez = scale_z

    data.baseanimname = inst.baseanimname
    data.door_data_animstate = inst.door_data_animstate
    data.door_data_background = inst.door_data_background
    data.door_data_bank = inst.door_data_bank
    data.door_data_build = inst.door_data_build
    data.dooranimclosed = inst.dooranimclosed
    data.flipped = inst.flipped
    data.minimapicon = inst.minimapicon
    data.rotation = inst.Transform:GetRotation()
    data.sg_name = inst.sg_name
    data.startstate = inst.startstate
    data.timechanger = inst.timechanger
    data.usesounds = inst.usesounds

    data.anthill_inside = inst:HasTag("anthill_inside")
    data.guard_entrance = inst:HasTag("guard_entrance")
    data.lockable_door = inst:HasTag("lockable_door")
    data.roc_cave_delete_me = inst:HasTag("roc_cave_delete_me")
    data.ruins_exit = inst:HasTag("ruins_exit")
    data.secret = inst:HasTag("secret")
    data.shop_music = inst:HasTag("shop_music")
    data.timechange_anims = inst:HasTag("timechange_anims")

    if inst.opentask then
        data.opentimeleft = inst:TimeRemainingInTask(inst.opentaskinfo)
    end
end

local function OnLoad(inst, data)
    if data.door_data_bank then
        inst.AnimState:SetBank(data.door_data_bank)
        inst.door_data_bank = data.door_data_bank
    end
    if data.door_data_build then
        inst.AnimState:SetBuild(data.door_data_build)
        inst.door_data_build = data.door_data_build
    end
    if data.door_data_animstate then
        inst.AnimState:PlayAnimation(data.door_data_animstate, true)
        inst.door_data_animstate = data.door_data_animstate
    end
    inst.components.rotatingbillboard:SetAnimation_Server({
        bank = data.door_data_bank,
        build = data.door_data_build,
        anim = data.door_data_animstate,
    })
    if data.rotation and inst.components.rotatingbillboard == nil then
        inst.Transform:SetRotation(data.rotation)
    end
    if data.door_data_background
        or (data.door_data_animstate and data.door_data_animstate == "day_loop") then -- 第二个条件用于旧存档兼容

        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.door_data_background = data.door_data_background
    end
    if data.scalex  then
        inst.Transform:SetScale(data.scalex, data.scaley, data.scalez)
    end
    if data.timechanger then
        MakeTimeChanger(inst)
    else
        EnableDoorLightUpdate(inst, true)
    end
    if data.timechange_anims then
        inst:AddTag("timechange_anims")
        OnPhaseChange(inst, TheWorld.state.phase)
    end
    if data.baseanimname then
        inst.baseanimname = data.baseanimname
    end
    if data.lockable_door then
        inst:AddTag("lockable_door")
    end
    if data.secret then
        inst:AddTag("secret")
    end
    if data.dooranimclosed then
        inst.AnimState:PushAnimation(inst.baseanimname.."_closed")
    end
    if data.minimapicon then
        inst:SetMinimapIcon(data.minimapicon)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(inst.minimapicon)
    end

    if data.guard_entrance then
        inst:AddTag("guard_entrance")
    end
    if data.ruins_exit then
        inst:AddTag("ruins_exit")
    end
    if data.shop_music then
        inst:AddTag("shop_music")
    end
    if data.anthill_inside then
        inst:AddTag("anthill_inside")
    end
    if data.roc_cave_delete_me then
        inst:AddTag("roc_cave_delete_me")
    end

    if data.startstate then
        inst.startstate = data.startstate
    end

    if data.sg_name then
        inst.sg_name = data.sg_name
        inst:SetStateGraph(inst.sg_name)
        if inst.startstate then
            inst.sg:GoToState(inst.startstate)
        end
    end

    if data.usesounds then
        inst.usesounds = data.usesounds
    end

    if data.opentimeleft then
        if inst.opentask then
            inst.opentask:Cancel()
            inst.opentask = nil
        end
        inst.opentask, inst.opentaskinfo = inst:ResumeTask(data.opentimeleft, function() inst:PushEvent("open") end)
    end

    if inst.components.door then -- 针对旧存档的兼容
        inst.components.door:UpdateDoorVis()
        local shadow = inst.components.door:GetShadow()
        if shadow then
            shadow.door_data_bank = inst.door_data_bank
            shadow.door_data_build = inst.door_data_build
            shadow.door_data_animstate = "south_floor"
        end
    end
end

local function DisableDoor(inst, setting, cause)
    assert(cause, "needs a cause")

    local door = inst.components.door
    door:SetDoorDisabled(setting, cause)
end

local function UseDoor(inst,data)
    if inst.usesounds then
        if data and data.doer and data.doer.SoundEmitter then
            for _, sound in ipairs(inst.usesounds) do
                data.doer:DoTaskInTime(FRAMES * 2, function()
                    data.doer.SoundEmitter:PlaySound(sound)
                end)
            end
        end
    end
end

local function OpenDoor(inst, nospread)
    if inst.opentask then
        inst.opentask:Cancel()
        inst.opentask = nil
    end
    if inst.baseanimname and inst.components.door.disable_causes and inst.components.door.disable_causes["door"] then
        if not inst:IsAsleep() then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/stone_door/slide")
            inst.AnimState:PlayAnimation(inst.baseanimname .. "_open")
            inst.AnimState:PushAnimation(inst.baseanimname)
        else
            inst.AnimState:PlayAnimation(inst.baseanimname)
        end

        DisableDoor(inst, nil, "door")
        inst.dooranimclosed = nil

        local interior_spawner = TheWorld.components.interiorspawner
        if interior_spawner.doors[inst.components.door.target_door_id] then
            local targetdoor = interior_spawner.doors[inst.components.door.target_door_id].inst
            if targetdoor and not nospread then
                targetdoor:opendoor(true)
            end
        end
    end
end

local function CloseDoor(inst, nospread)
    if inst.opentask then
        inst.opentask:Cancel()
        inst.opentask = nil
    end
    inst.opentask, inst.opentaskinfo = inst:ResumeTask(30, function() inst:PushEvent("open") end)
    -- once the player has used a door, the doors should freeze open
    if inst.components.door.disabled and inst.components.door.disable_causes and inst.components.door.disable_causes["door"] == true then
        return
    end

    if not inst.baseanimname or (inst.components.door.disable_causes and inst.components.door.disable_causes["door"]) then
        return
    end

    if not inst:IsAsleep() then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/stone_door/close")
        inst.AnimState:PlayAnimation(inst.baseanimname .. "_shut")
        inst.AnimState:PushAnimation(inst.baseanimname .. "_closed")
        inst:DoTaskInTime(7 / 30, function()
            ShakeAllCamerasInRoom(inst:GetCurrentInteriorID(), CAMERASHAKE.FULL, 0.7, 0.02, 0.5, inst, 40)
        end)
    else
        inst.AnimState:PlayAnimation(inst.baseanimname .. "_closed")
    end

    DisableDoor(inst, true, "door")
    inst.dooranimclosed = true

    local interior_spawner = TheWorld.components.interiorspawner
    if interior_spawner.doors[inst.components.door.target_door_id] then
        local targetdoor = interior_spawner.doors[inst.components.door.target_door_id].inst
        if targetdoor and not nospread then
            targetdoor:closedoor(true)
        end
    end
end

local function GetMinimapIcon(inst)
    return inst._minimap_name:value()
end

local function OnEntitySleep(inst)
    if inst.sg and 
        (inst.sg:HasStateTag("moving") or inst.sg:HasStateTag("shut")) then

        door.sg:GoToState("idle")
    end
    
    inst:StopDoorLightUpdate()
end

local function OnEntityWake(inst)
    if inst.sg and 
        (inst.sg:HasStateTag("moving") or inst.sg:HasStateTag("shut")) then

        door.sg:GoToState("idle")
    end
    
    if inst.doorlightenable then
        inst:StartDoorLightUpdate()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.75)

    inst.AnimState:SetSortOrder(4)

    inst.Light:Enable(false)

    inst:AddTag("interior_door")
    inst:AddTag("client_forward_action_target") -- 为了能被键盘操作交互检测
    inst:AddTag("NOBLOCK")

    inst:DoTaskInTime(0, function() inst.Physics:SetActive(false) end)

    inst.Transform:SetRotation(-90)
    inst:AddComponent("rotatingbillboard")

    inst._minimap_name = net_string(inst.GUID, "prop_door._minimap_name")
    inst._minimap_name:set_local("")

    -- Used by scripts/prefabs/interiorworkblank.lua
    inst.GetMinimapIcon = GetMinimapIcon

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetMinimapIcon = SetMinimapIcon

    inst:AddComponent("door")

    inst:AddComponent("vineable")

    inst.initInteriorPrefab = InitInteriorPrefab

    inst.opendoor = OpenDoor
    inst.closedoor = CloseDoor
    inst.disableDoor = DisableDoor

    inst:ListenForEvent("open", OpenDoor)
    inst:ListenForEvent("close", CloseDoor)
    inst:ListenForEvent("usedoor", UseDoor)

    inst.StartDoorLightUpdate = StartDoorLightUpdate
    inst.StopDoorLightUpdate = StopDoorLightUpdate

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    return inst
end

local function InitInteriorPrefab_shadow(inst, doer, prefab_definition, interior_definition)
    --If we are spawned inside of a building, then update our door to point at our interior

    if not prefab_definition then
        return
    end

    if prefab_definition.animdata then
        if prefab_definition.animdata.bank then
            inst.AnimState:SetBank(prefab_definition.animdata.bank)
            inst.door_data_bank = prefab_definition.animdata.bank
        end
        if prefab_definition.animdata.build then
            inst.AnimState:SetBuild(prefab_definition.animdata.build)
            inst.door_data_build = prefab_definition.animdata.build
        end
        if prefab_definition.animdata.anim then
            inst.AnimState:PlayAnimation(prefab_definition.animdata.anim, true)
            inst.door_data_animstate = prefab_definition.animdata.anim
            -- this is for finding the right open and closed door animation.
            inst.baseanimname = inst.door_data_animstate
        end
    end
end

local function ShadowOnSave(inst, data)
    data.animdata =
    {
        bank = inst.door_data_bank,
        build = inst.door_data_build,
        anim = inst.door_data_animstate,
    }
end

local function ShadowOnLoad(inst, data)
    InitInteriorPrefab_shadow(inst, nil, data, nil)
end

local function shadowfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("doorway_ruins")
    inst.AnimState:SetBuild("pig_ruins_door")
    inst.AnimState:PlayAnimation("south_floor")

    inst:AddTag("NOCLICK")  -- Note for future self: Was commented out, but not sure why.. if it's not there, the shadow eats the click on the door.
    inst:AddTag("NOBLOCK")
    inst:AddTag("door_shadow")
    inst.initInteriorPrefab = InitInteriorPrefab_shadow

    inst:AddTag("SELECT_ME")

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.OnSave = ShadowOnSave
    inst.OnLoad = ShadowOnLoad
    return inst
end


return Prefab("prop_door", fn, assets),
       Prefab("prop_door_shadow", shadowfn, assets)
