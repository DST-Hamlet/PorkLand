local assets =
{
    Asset("ANIM", "anim/pig_door_test.zip"),
    Asset("ANIM", "anim/pig_ruins_door.zip"),
    Asset("ANIM", "anim/pig_ruins_door_blue.zip"),
    Asset("ANIM", "anim/bat_cave_door.zip"),
    Asset("ANIM", "anim/ruins_stairs.zip"),
    Asset("ANIM", "anim/ant_cave_door.zip"),
    Asset("ANIM", "anim/acorn.zip"),
    Asset("ANIM", "anim/pig_shop_doormats.zip"),
    Asset("ANIM", "anim/ant_hill_entrance.zip"),
    Asset("ANIM", "anim/ant_queen_entrance.zip"),

    Asset("ANIM", "anim/player_house_doors.zip"),
}

local prefabs =
{
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

    if prefab_definition.animdata then
        inst.Transform:SetRotation(-90)

        inst:AddComponent("rotatingbillboard")
        inst.components.rotatingbillboard.animdata = prefab_definition.animdata

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

        if prefab_definition.animdata.background then
            inst.AnimState:SetLayer( LAYER_BACKGROUND )
            inst.AnimState:SetSortOrder( 3 )
            --inst.Transform:SetTwoFaced()
            -- inst.Transform:SetRotation(90)

            inst.door_data_background = prefab_definition.animdata.background
        end

        if prefab_definition.animdata.light then
            MakeTimeChanger(inst)
        end

        if prefab_definition.animdata.minimapicon then
            local minimap = inst.entity:AddMiniMapEntity()
            minimap:SetIcon(prefab_definition.animdata.minimapicon)

            inst.minimapicon = prefab_definition.animdata.minimapicon
        end
    end

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
end

local function InitHouseDoor(inst, dir)
    inst.door_data_animstate = dir
    inst.baseanimname = dir
    inst.AnimState:PlayAnimation(dir .. "_open")
    inst.AnimState:PushAnimation(dir, true)
end

local function SaveInteriorData(inst, save_data)
end

local function InitFromInteriorSave(inst, save_data)
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
    data.ruins_entrance = inst:HasTag("ruins_entrance")
    data.secret = inst:HasTag("secret")
    data.shop_entrance = inst:HasTag("shop_entrance")
    data.timechange_anims = inst:HasTag("timechange_anims")
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
    if data.rotation and inst.components.rotatingbillboard == nil then
        inst.Transform:SetRotation(data.rotation)
    end
    inst:AddComponent("rotatingbillboard")
    inst.components.rotatingbillboard.animdata = {
        bank = data.door_data_bank,
        build = data.door_data_build,
        animation = data.door_data_animstate,
    }
    if data.door_data_background then
        inst.AnimState:SetLayer( LAYER_BACKGROUND )
        inst.AnimState:SetSortOrder( 3 )
        inst.door_data_background = data.door_data_background
    end
    if data.scalex  then
        inst.Transform:SetScale( data.scalex, data.scaley, data.scalez)
    end
    if data.timechanger then
        MakeTimeChanger(inst)
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
        inst.minimapicon = data.minimapicon
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(inst.minimapicon)
    end

    if data.guard_entrance then
        inst:AddTag("guard_entrance")
    end
    if data.ruins_entrance then
        inst:AddTag("ruins_entrance")
    end
    if data.shop_entrance then
        inst:AddTag("shop_entrance")
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
end

local function DisableDoor(inst, setting, cause)
    assert(cause,"needs a cause")

    local door = inst.components.door
    door:SetDoorDisabled(setting, cause)

    -- deal with connecting doors.
    local interior_spawner = TheWorld.components.interiorspawner
    if interior_spawner.doors[door.target_door_id] then
        -- THIS DOORS OPPOSITE DOOR HAS BEEN VISITED BEFORE
        local targetdoor = interior_spawner.doors[door.target_door_id].inst
        if targetdoor then
            if setting == true then
                if cause == "door" then
                    targetdoor.closedoor(targetdoor)
                end
            else
                if cause == "door" then
                    targetdoor.opendoor(targetdoor)
                end
            end
            targetdoor.components.door:SetDoorDisabled(setting, cause)
        end

    else
        -- THIS DOORS OPPOSITE DOOR MAY EXIST BUT NOT VISITED YET..
        local interior = door.target_interior and interior_spawner:GetInteriorByIndex(door.target_interior)
        if interior then
            if interior.prefabs then
                for k, prefab in ipairs(interior.prefabs) do
                    if prefab.my_door_id and prefab.my_door_id == door.target_door_id then

                        if not prefab.door_closed then
                            prefab.door_closed = {}
                        end

                        prefab.door_closed[cause] = setting

                        break
                    end
                end
            end
        else
            print("INTERIOR WAS NOT FOUND")
        end
    end
end

local function UseDoor(inst,data)
    if inst.usesounds then
        if data and data.doer and data.doer.SoundEmitter then
            for i,sound in ipairs(inst.usesounds)do
                data.doer.SoundEmitter:PlaySound(sound)
            end
        end
    end
end

local function OpenDoor(inst, instant)
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
    end
end

local function CloseDoor(inst, instant)
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
end

local function testPlayerHouseDoor(inst)
    local door = inst.components.door
    if door then
        local interior = TheWorld.components.interiorspawner:GetInteriorByName(door.interior_name)
        if interior and interior.playerroom then
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon("player_frontdoor.tex")
            inst.MiniMapEntity:SetIconOffset(4, 0)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("acorn")
    inst.AnimState:SetBuild("acorn")
    inst.AnimState:PlayAnimation("idle")

    inst.Light:Enable(false)

    inst:AddTag("interior_door")
    inst:AddTag("NOBLOCK")

    inst:DoTaskInTime(0, function() inst.Physics:SetActive(false) end)

    inst:DoTaskInTime(0, testPlayerHouseDoor)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("door")

    inst:AddComponent("vineable")

    inst.initInteriorPrefab = InitInteriorPrefab
    inst.saveInteriorData = SaveInteriorData
    inst.initFromInteriorSave = InitFromInteriorSave

    MakeHauntableDoor(inst)

    inst.opendoor = OpenDoor
    inst.closedoor = CloseDoor
    inst.disableDoor = DisableDoor

    inst:ListenForEvent("open", OpenDoor)
    inst:ListenForEvent("close", CloseDoor)
    inst:ListenForEvent("usedoor", UseDoor)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function InitInteriorPrefab_shadow(inst, doer, prefab_definition, interior_definition)
    --If we are spawned inside of a building, then update our door to point at our interior

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

local function shadowfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("doorway_ruins")
    inst.AnimState:SetBuild("pig_ruins_door")
    inst.AnimState:PlayAnimation("south_floor")

    inst:AddTag("NOCLICK")  -- Note for future self: Was commented out, but not sure why.. if it's not there, the shadow eats the click on the door.
    inst:AddTag("NOBLOCK")
    inst.initInteriorPrefab = InitInteriorPrefab_shadow

    inst:AddTag("SELECT_ME")

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    return inst
end


return Prefab("prop_door", fn, assets, prefabs),
       Prefab("prop_door_shadow", shadowfn, assets, prefabs)
