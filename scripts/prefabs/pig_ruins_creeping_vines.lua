local assets =
{
    Asset("ANIM", "anim/pig_ruins_vines_door.zip"),
    Asset("ANIM", "anim/pig_ruins_vines_build.zip"),
}

local assets_wall =
{
    Asset("ANIM", "anim/pig_ruins_vines_wall.zip"),
    Asset("ANIM", "anim/pig_ruins_vines_build.zip"),
}

local prefabs =
{

}

local function GetAnimName(inst)

    local stage_string = "_closed"

    if inst.stage == 1 then
        stage_string = "_med"
    elseif inst.stage == 0 then
        stage_string = "_open"
    end

    return inst.facing .. stage_string
end

local function BlockDoor(inst)
    -- send event to dissable the door.  the listener will respond if it's the door OR the target door
    if inst.door then
        inst.door.components.vineable:SetDoorDisabled(true)
    end
end

local function ClearDoor(inst)
    -- send event to enable the door. the listener will respond if it's the door OR the target door
    if inst.door then
        inst.door.components.vineable:SetDoorDisabled(false)
    end
end

local function Regrow(inst)
    -- this is just for viuals, it doesn't actually lock the assotiated door.
    if inst.stage ~= 2 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/vine_grow")
        inst.stage = 2
        inst.components.workable:SetWorkLeft(TUNING.RUINS_DOOR_VINES_HACKS)
        inst.components.shearable:SetCanShear(true)
        inst:RemoveTag("NOCLICK")
        inst.AnimState:PlayAnimation(GetAnimName(inst) .. "_pre", true)
        inst.AnimState:PushAnimation(GetAnimName(inst), true)
        inst.components.rotatingbillboard:SyncMaskAnimation()
    end
end

local function hackedopen(inst)
    -- this is just for viuals, it doesn't actually open the assotiated door.
    inst.stage = 0
    inst.components.workable:SetWorkable(false)
    inst.components.shearable:SetCanShear(false)
    inst:AddTag("NOCLICK")
    inst.AnimState:PlayAnimation(GetAnimName(inst), true)
    inst.components.rotatingbillboard:SyncMaskAnimation()
end

local function OnHacked(inst, hacker, hacksleft)
    if hacksleft <= 0 then
        if inst.stage > 0 then
            inst.stage = inst.stage -1

            if inst.stage == 0 then
                ClearDoor(inst)
                if inst.door then
                   inst.door.components.vineable:BeginRegrow()
                end
            else
                inst.AnimState:PlayAnimation(GetAnimName(inst) .. "_hit")
                inst.AnimState:PushAnimation(GetAnimName(inst), true)
                inst.components.workable:SetWorkLeft(TUNING.RUINS_DOOR_VINES_HACKS)
            end
        end
    else
        inst.AnimState:PlayAnimation(GetAnimName(inst) .. "_hit")
        inst.AnimState:PushAnimation(GetAnimName(inst), true)
    end

    local fx = SpawnPrefab("hacking_fx")
    local x, y, z= inst.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x,y + math.random()*2,z)
    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/vine_hack")
end

local function SetUp(inst)
    BlockDoor(inst)

    if inst.door:HasTag("door_north") then
        inst.facing = "north"
    elseif inst.door:HasTag("door_south") then
        inst.facing = "south"
    elseif inst.door:HasTag("door_east") then
        inst.facing = "east"
    elseif inst.door:HasTag("door_west") then
        inst.facing = "west"
    end

    if inst.facing ~= "south" then
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(4)
    end

    inst.AnimState:PlayAnimation(GetAnimName(inst), true)
end

local function makefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local anim_data = {
        bank = "pig_ruins_vines_door",
        build = "pig_ruins_vines_build",
        animation = "north_closed"
    }

    inst.AnimState:SetBank(anim_data.bank)
    inst.AnimState:SetBuild(anim_data.build)
    inst.AnimState:PlayAnimation(anim_data.animation, true)

    inst.Transform:SetRotation(-90) -- 使得rotatingbillboard默认正对室内摄像机显示

    inst:AddComponent("rotatingbillboard")
    inst.components.rotatingbillboard.animdata = anim_data

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HACK)
    inst.components.workable:SetWorkLeft(TUNING.RUINS_DOOR_VINES_HACKS)
    inst.components.workable:SetOnWorkCallback(OnHacked)

    inst:AddComponent("hackable")

    inst:AddComponent("shearable")

    inst:AddComponent("inspectable")

    MakeHauntableVineDoor(inst)

    inst.facing = "north"
    inst.stage = 2

    inst.setup = SetUp
    inst.regrow = Regrow
    inst.hackedopen = hackedopen

    return inst
end

local function makewallfn(facing)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        local anim_data = {
            bank = "pig_ruins_vines_wall",
            build = "pig_ruins_vines_build",
            animation = facing .. math.random(1, 15)
        }

        inst.AnimState:SetBank(anim_data.bank)
        inst.AnimState:SetBuild(anim_data.build)
        inst.AnimState:PlayAnimation(anim_data.animation, true)
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst.Transform:SetRotation(-90)

        inst:AddComponent("rotatingbillboard")
        inst.components.rotatingbillboard.animdata = anim_data

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.facing = facing

        return inst
    end

    return fn
end

return Prefab("pig_ruins_creeping_vines", makefn, assets, prefabs),
       Prefab("pig_ruins_wall_vines_north", makewallfn("north_"), assets_wall, prefabs),
       Prefab("pig_ruins_wall_vines_east", makewallfn("east_"), assets_wall, prefabs),
       Prefab("pig_ruins_wall_vines_west", makewallfn("west_"), assets_wall, prefabs)
