local assets =
{
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"),
    --Asset("ANIM", "anim/pig_ruins_door_blue.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins_cracks.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins_cracks_fake.zip"),
}

local prefabs =
{
}

local function SetCrack(inst, door)
    inst.Transform:SetPosition(door.Transform:GetWorldPosition())

    inst.baseanimname = door.baseanimname

    inst.AnimState:SetBuild("interior_wall_decals_ruins_cracks")

    inst.door = door
    door.crack = inst
    inst.AnimState:PlayAnimation(inst.baseanimname .. "_closed")

    if not door:HasTag("secret") then
        inst:Reveal()
    end
end

local function OnSave(inst, data)
    data.baseanimname = inst.baseanimname
    if inst.door then
        data.door_guid = inst.door.GUID
        return {data.door_guid}
    end
    if inst.revealed then
        data.revealed = true
    end
end

local function OnLoadPostPass(inst, ents, data)
    if not data then
        return
    end

    if data.baseanimname then
        inst.baseanimname = data.baseanimname
        inst.AnimState:PlayAnimation(inst.baseanimname .. "_closed")
    end

    if data.door_guid then
        SetCrack(inst, ents[data.door_guid].entity)
    end
    if data.revealed then
        inst.AnimState:PushAnimation(inst.baseanimname)
    end
end

local function Reveal(inst, nochain)
    if inst.door then
        inst.door.components.door:SetHidden(false)
        inst.door.components.door:UpdateDoorVis()

        if not inst.door:IsAsleep() then
            inst.door.AnimState:PlayAnimation(inst.baseanimname .. "_open")
        else
            inst.door.AnimState:PlayAnimation(inst.baseanimname)
        end
        inst.door:RemoveTag("secret")

        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
        -- TODO make this client side
        inst:Play2DSoundOutSide("dontstarve_DLC003/music/secret_found", "crack", 40)

        -- The rest of the function unlocks the equivalent door within the secret room
        local interior_spawner = TheWorld.components.interiorspawner
        local target_door_id = inst.door.components.door.target_door_id
        local room = interior_spawner:GetInteriorByIndex(inst.door.components.door.target_interior)
        local dest_door = room:GetDoorById(target_door_id)

        -- If the player has been to the secret room before we remove the tag from the instance manually
        if dest_door and dest_door:HasTag("secret") then
            if dest_door.crack and not nochain then
                dest_door.crack:Reveal(true)
            end
        end

        inst:Remove()
    else
        inst.revealed = true
        inst.AnimState:PlayAnimation(inst.baseanimname .. "_open")
        inst.AnimState:PushAnimation(inst.baseanimname)
    end
end

local function InitInteriorPrefab(inst, doer, prefab_definition, interior_definition)
    if prefab_definition.animdata and prefab_definition.animdata.anim then
        inst.baseanimname = prefab_definition.animdata.anim
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("interior_wall_decals_ruins_fake")
    inst.AnimState:SetBuild("interior_wall_decals_ruins_cracks_fake")

    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("secret_room")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("mystery_door")

    inst:AddComponent("inspectable")

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass
    inst.SetCrack = SetCrack
    inst.Reveal = Reveal
    inst.initInteriorPrefab = InitInteriorPrefab

    inst:ListenForEvent("interior_endquake", function(scr, data)
        local interiorID = data.interiorID
        if not interiorID then
            return
        end
        local current_interiorID = inst:GetCurrentInteriorID()
        if current_interiorID and interiorID == current_interiorID then
            inst:Reveal()
        end
    end, TheWorld)

    return inst
end

return Prefab("wallcrack_ruins", fn, assets, prefabs)
