require "prefabutil"
-- require "stategraphs/SGanthilldoor_north"
-- require "stategraphs/SGanthilldoor_south"
-- require "stategraphs/SGanthilldoor_east"
-- require "stategraphs/SGanthilldoor_west"

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
    day = {rad=3,intensity=0.75,falloff=0.5,color={1,1,1}},
    dusk = {rad=2,intensity=0.75,falloff=0.5,color={1/1.8,1/1.8,1/1.8}},
    full = {rad=2,intensity=0.75,falloff=0.5,color={0.8/1.8,0.8/1.8,1/1.8}}
}

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
end

local phasefunctions =
{
    day = function(inst)
        if not inst:IsInLimbo() then inst.Light:Enable(true) end
        inst.components.lighttweener:StartTween(nil, lights.day.rad, lights.day.intensity, lights.day.falloff, {lights.day.color[1],lights.day.color[2],lights.day.color[3]}, 2)
    end,

    dusk = function(inst)
        if not inst:IsInLimbo() then inst.Light:Enable(true) end
        inst.components.lighttweener:StartTween(nil, lights.dusk.rad, lights.dusk.intensity, lights.dusk.falloff, {lights.dusk.color[1],lights.dusk.color[2],lights.dusk.color[3]}, 2)
    end,

    night = function(inst)
        if TheWorld.state.moonphase == "full" then
            inst.components.lighttweener:StartTween(nil, lights.full.rad, lights.full.intensity, lights.full.falloff, {lights.full.color[1],lights.full.color[2],lights.full.color[3]}, 4)
        else
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, {0,0,0}, 6, turnoff)
        end
    end,
}

local function timechange(inst)
    if TheWorld.state.isday then

        if inst:HasTag("timechange_anims") then
            inst.AnimState:PlayAnimation("to_day")
               inst.AnimState:PushAnimation("day_loop", true)
        end

        if inst.Light then
            phasefunctions["day"](inst)
        end
    elseif TheWorld.state.isnight then

        if inst:HasTag("timechange_anims") then
               inst.AnimState:PlayAnimation("to_night")
            inst.AnimState:PushAnimation("night_loop", true)
        end

        if inst.Light then
            phasefunctions["night"](inst)
        end
    elseif TheWorld.state.isdusk then

        if inst:HasTag("timechange_anims") then
            inst.AnimState:PlayAnimation("to_dusk")
            inst.AnimState:PushAnimation("dusk_loop", true)
        end

        if inst.Light then
            phasefunctions["dusk"](inst)
        end
    end
end

local function settimechange(inst)
    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, lights.day.rad, lights.day.intensity, lights.day.falloff, {lights.day.color[1],lights.day.color[2],lights.day.color[3]}, 0)
    inst.Light:Enable(true)

    inst:WatchWorldState("isday", function() timechange(inst) end)
    inst:WatchWorldState("isdusk", function() timechange(inst) end)
    inst:WatchWorldState("isnight", function() timechange(inst) end)

    inst.timechanger = true
    timechange(inst)
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
            settimechange(inst)
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

local function onsave(inst, data)

    local pt = Vector3(inst.Transform:GetScale())
    data.scalex = pt.x
    data.scaley = pt.y
    data.scalez = pt.z

    if inst.baseanimname then
        data.baseanimname = inst.baseanimname
    end

    if inst.door_data_animstate then
        data.door_data_animstate = inst.door_data_animstate
    end

    if inst.door_data_bank then
        data.door_data_bank = inst.door_data_bank
    end

    if inst.door_data_build then
        data.door_data_build = inst.door_data_build
    end

    if inst.door_data_background then
        data.door_data_background = inst.door_data_background
    end
    if inst.timechanger then
        data.timechanger = true
    end
    data.rotation = inst.Transform:GetRotation()
    if inst.flipped then
        data.flipped = inst.flipped
    end
    if inst:HasTag("timechange_anims") then
        data.timechange_anims = true
    end
    if inst:HasTag("lockable_door") then
        data.lockable_door = true
    end
    if inst:HasTag("secret") then
        data.secret = true
    end

    if inst.dooranimclosed then
        data.dooranimclosed = true
    end

    if inst.minimapicon then
        data.minimapicon = inst.minimapicon
    end

    if inst:HasTag("guard_entrance") then
        data.guard_entrance = true
    end
    if inst:HasTag("ruins_entrance")then
        data.ruins_entrance = true
    end
    if inst:HasTag("shop_entrance")then
        data.shop_entrance = true
    end
    if inst:HasTag("roc_cave_delete_me")then
        data.roc_cave_delete_me = true
    end

    if inst:HasTag("anthill_inside") then
        data.anthill_inside = true
    end
    if inst.startstate then
        data.startstate = inst.startstate
    end
    if inst.sg_name then
        data.sg_name = inst.sg_name
    end

    if inst.usesounds then
        data.usesounds = inst.usesounds
    end
end

local function onload(inst, data)
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
    if data.rotation then
        -- inst:DoTaskInTime(0, function()
            inst.Transform:SetRotation(data.rotation)
        -- end)
    end
    if data.door_data_background then
        inst.AnimState:SetLayer( LAYER_BACKGROUND )
        inst.AnimState:SetSortOrder( 3 )
        inst.door_data_background = data.door_data_background
    end
    if data.scalex  then
        inst.Transform:SetScale( data.scalex, data.scaley, data.scalez)
    end
    if data.timechanger then
        settimechange(inst)
    end
    if data.timechange_anims then
        inst:AddTag("timechange_anims")
        timechange(inst)
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
        local minimap = inst.entity:AddMiniMapEntity()
        minimap:SetIcon(inst.minimapicon)
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

local function disableDoor(inst, setting, cause)
    assert(cause,"needs a cause")

    local door = inst.components.door
    door:checkDisableDoor(setting, cause)

    -- deal with connecting doors.
    local interior_spawner = GetWorld().components.interiorspawner
    if interior_spawner.doors[door.target_door_id] then
        -- THIS DOORS OPPOSITE DOOR HAS BEEN VISITED BEFORE
        local targetdoor = interior_spawner.doors[door.target_door_id].inst
        if targetdoor then
            if setting == true then
                if cause == "door" then
                    targetdoor.closedoor(targetdoor, true)
                end
                if cause == "vines" then
                    targetdoor.components.vineable:dissabledoorvis()
                end
            else
                if cause == "door" then
                    targetdoor.opendoor(targetdoor, true)
                end
                if cause == "vines" then
                    targetdoor.components.vineable:enabledoorvis()
                end
            end
            targetdoor.components.door:checkDisableDoor(setting, cause)
        end

    else
        -- THIS DOORS OPPOSITE DOOR MAY EXIST BUT NOT VISITED YET..
        local interior = interior_spawner:GetInteriorByIndex(door.target_interior)
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

local function usedoor(inst,data)
    if inst.usesounds then
        if data and data.doer and data.doer.SoundEmitter then
            for i,sound in ipairs(inst.usesounds)do
                data.doer.SoundEmitter:PlaySound(sound)
            end
        end
    end
end

local function opendoor(inst, instant)
    if inst.baseanimname and inst.components.door.disabledcauses and inst.components.door.disabledcauses["door"] then
        --print("OPENING")
        if not instant then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/stone_door/slide")
            inst.AnimState:PlayAnimation(inst.baseanimname.."_open")
            inst.AnimState:PushAnimation(inst.baseanimname)
        else
            inst.AnimState:PlayAnimation(inst.baseanimname)
        end

        disableDoor(inst,nil,"door")

        inst.dooranimclosed = nil
    end
end

local function closedoor(inst, instant)
    -- once the player has used a door, the doors should freeze open
    if not GetWorld().doorfreeze  then
        if inst.baseanimname and (not inst.components.door.disabledcauses or not inst.components.door.disabledcauses["door"])  then
            --print("CLOSING")
            if not instant then
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/objects/stone_door/close")
                inst.AnimState:PlayAnimation(inst.baseanimname.."_shut")
                inst.AnimState:PushAnimation(inst.baseanimname.."_closed")
                inst:DoTaskInTime(1/30*7,function() TheCamera:Shake("FULL", 0.7, 0.02, .5, 40) end)
            else
                inst.AnimState:PlayAnimation(inst.baseanimname.."_closed")
            end
            disableDoor(inst, true,"door")
            inst.dooranimclosed = true
        end
    end
end

local function testPlayerHouseDoor(inst)
    local door = inst.components.door
    if door then
        local interior = TheWorld.components.interiorspawner:GetInteriorByName(door.interior_name)
        if interior and interior.playerroom then
            local minimap = inst.entity:AddMiniMapEntity()
            minimap:SetIcon( "player_frontdoor.png" )
            minimap:SetIconOffset(4,0)
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:Enable(false)

    inst.AnimState:SetBank("acorn")
    inst.AnimState:SetBuild("acorn")
    inst.AnimState:PlayAnimation("idle")
    -- inst.AnimState:SetSortOrder(SORTORDER_MAX)

    --inst.Transform:SetTwoFaced()

    MakeObstaclePhysics(inst, 1)
    inst:DoTaskInTime(0, function() inst.Physics:SetActive(false) end)

    inst:DoTaskInTime(0, testPlayerHouseDoor)

    inst:AddTag("interior_door")
    inst:AddTag("NOBLOCK")

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

    inst.opendoor = opendoor
    inst.closedoor = closedoor
    inst.disableDoor = disableDoor

    inst:ListenForEvent("open", function(inst, data) opendoor(inst, data and data.instant) end)
    inst:ListenForEvent("close", function(inst, data) closedoor(inst, data and data.instant) end)

    inst:ListenForEvent("usedoor", function(inst,data) usedoor(inst,data) end)

    inst.OnSave = onsave
    inst.OnLoad = onload

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
