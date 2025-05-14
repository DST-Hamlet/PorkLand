local assets =
{
    Asset("ANIM", "anim/interior_unique.zip"),
    Asset("ANIM", "anim/interior_sconce.zip"),
    Asset("ANIM", "anim/interior_defect.zip"),
    Asset("ANIM", "anim/interior_decor.zip"),
    Asset("ANIM", "anim/interior_pillar.zip"),
    Asset("ANIM", "anim/ceiling_lights.zip"),
    Asset("ANIM", "anim/containers.zip"),
    Asset("ANIM", "anim/interior_floor_decor.zip"),
    Asset("ANIM", "anim/interior_window.zip"),
    Asset("ANIM", "anim/interior_window_burlap.zip"),
    Asset("ANIM", "anim/interior_window_lightfx.zip"),
    Asset("ANIM", "anim/window_arcane_build.zip"),

    Asset("ANIM", "anim/interior_wall_decals.zip"),
    Asset("ANIM", "anim/interior_wall_decals_hoofspa.zip"),
    Asset("ANIM", "anim/interior_wall_mirror.zip"),
    Asset("ANIM", "anim/interior_chair.zip"),

    Asset("ANIM", "anim/interior_wall_decals_antcave.zip"),
    Asset("ANIM", "anim/interior_wall_decals_antiquities.zip"),
    Asset("ANIM", "anim/interior_wall_decals_arcane.zip"),
    Asset("ANIM", "anim/interior_wall_decals_batcave.zip"),
    Asset("ANIM", "anim/interior_wall_decals_batcave_2.zip"),
    Asset("ANIM", "anim/interior_wall_decals_deli.zip"),
    Asset("ANIM", "anim/interior_wall_decals_florist.zip"),
    Asset("ANIM", "anim/interior_wall_decals_mayorsoffice.zip"),
    Asset("ANIM", "anim/interior_wall_decals_palace.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins_blue.zip"),
    Asset("ANIM", "anim/interior_wall_decals_accademia.zip"),
    Asset("ANIM", "anim/interior_wall_decals_millinery.zip"),
    Asset("ANIM", "anim/interior_wall_decals_weapons.zip"),

    Asset("ANIM", "anim/interior_wallornament.zip"),

    Asset("ANIM", "anim/window_mayorsoffice.zip"),
    Asset("ANIM", "anim/window_palace.zip"),
    Asset("ANIM", "anim/window_palace_stainglass.zip"),

    Asset("ANIM", "anim/interior_plant.zip"),
    Asset("ANIM", "anim/interior_table.zip"),
    Asset("ANIM", "anim/interior_floorlamp.zip"),

    Asset("ANIM", "anim/interior_window_small.zip"),
    Asset("ANIM", "anim/interior_window_large.zip"),
    Asset("ANIM", "anim/interior_window_tall.zip"),
    Asset("ANIM", "anim/interior_window_greenhouse.zip"),
    Asset("ANIM", "anim/interior_window_greenhouse_build.zip"),

    Asset("ANIM", "anim/window_weapons_build.zip"),

    Asset("ANIM", "anim/pig_ruins_well.zip"),
    Asset("ANIM", "anim/ceiling_decor.zip"),
    Asset("ANIM", "anim/light_dust_fx.zip"),
}

local prefabs =
{
    "swinglightobject",
    "deco_roomglow",
    "deco_wood_cornerbeam_placer",
}

local function smash(inst)
    if inst.components.lootdropper then
        local room = TheWorld.components.interiorspawner:GetInteriorCenter(inst:GetPosition())
        if room then
            inst.components.lootdropper:SetFlingTarget(room:GetPosition())
        end
        inst.components.lootdropper:DropLoot()
    end

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function SetPlayerUncraftable(inst)
    inst.entity:AddSoundEmitter()

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(smash)
    inst:RemoveTag("NOCLICK")
end

local function OnBuilt(inst)
    SetPlayerUncraftable(inst)
    inst.onbuilt = true

    local x, y, z = inst.Transform:GetWorldPosition()
    if inst:HasTag("cornerpost") then
        local ents = TheSim:FindEntities(x, y, z, 1, {"cornerpost"})
        for _, ent in pairs(ents) do
            if ent ~= inst then
                smash(ent)
            end
        end
    end

    if inst:HasTag("centerlight") then
        local ents = TheSim:FindEntities(x, y, z, 1, {"centerlight"})
        for _, ent in pairs(ents) do
            if ent ~= inst then
               smash(ent)
            end
        end
    end

    if inst:HasTag("wallsection") then
        local ents = TheSim:FindEntities(x, y, z, 1, {"wallsection"})
        for _, ent in pairs(ents) do
            if ent ~= inst and not (ent:HasTag("interior_door") and not ent:DoorCanBeRemoved()) then
               smash(ent)
            end
        end
    end

    if inst.on_built_fn then
        inst.on_built_fn(inst)
    end
end

local function UpdateArtWorkable(inst, instant)
    local work_left = inst.components.workable.workleft
    local anim_level = work_left / TUNING.DECO_RUINS_BEAM_WORK
    if anim_level <= 0 then
        if not instant then
            inst.AnimState:PlayAnimation("pillar_front_crumble")
            inst.AnimState:PushAnimation("pillar_front_crumble_idle")
            if inst.components.rotatingbillboard then
                inst.components.rotatingbillboard.animdata.anim = "pillar_front_crumble_idle"
            end
        else
            inst.AnimState:PlayAnimation("pillar_front_crumble_idle")
            if inst.components.rotatingbillboard then
                inst.components.rotatingbillboard.animdata.anim = "pillar_front_crumble_idle"
            end
        end
    elseif anim_level < 1 / 3 then
        inst.AnimState:PlayAnimation("pillar_front_break_2")
        if inst.components.rotatingbillboard then
            inst.components.rotatingbillboard.animdata.anim = "pillar_front_break_2"
        end
    elseif anim_level < 2 / 3 then
        inst.AnimState:PlayAnimation("pillar_front_break_1")
        if inst.components.rotatingbillboard then
            inst.components.rotatingbillboard.animdata.anim = "pillar_front_break_1"
        end
    end
    if work_left <= 0 then
        inst.components.workable:SetWorkable(false)
    end
    if inst.components.rotatingbillboard then
        inst.components.rotatingbillboard:SyncMaskAnimation()
    end
end

local function OnSave(inst, data)
    local references = {}
    data.rotation = inst.Transform:GetRotation()
    local pt = Vector3(inst.Transform:GetScale())
    data.scalex = pt.x
    data.scaley = pt.y
    data.scalez = pt.z

    if inst.sunraysspawned then
        data.sunraysspawned = inst.sunraysspawned
    end

    if inst.childrenspawned then
        data.childrenspawned = inst.childrenspawned
    end

    --if inst.flipped then
        --data.flipped = inst.flipped
    --end
    if inst.setbackground then
        data.setbackground = inst.setbackground
    end
    if inst:HasTag("dartthrower") then
        data.dartthrower = true
    end
    if inst:HasTag("dartthrower_right") then
        data.dartthrower_right = true
    end
    if inst:HasTag("dartthrower_left") then
        data.dartthrower_left = true
    end
    if inst:HasTag("playercrafted") then
        data.playercrafted = true
    end

    data.children = {}
    if inst.decochildrenToRemove then
        for i, child in ipairs(inst.decochildrenToRemove) do
            table.insert(data.children, child.GUID)
            table.insert(references, child.GUID)
        end
    end

    if inst.dust then
        data.dust = inst.dust.GUID
        table.insert(references, data.dust)
    end

    -- if inst.swinglight then
    --     data.swinglight = inst.swinglight.GUID
    --     table.insert(references, data.swinglight)
    -- end

    if inst.animdata then
        data.animdata = inst.animdata
    end
    if inst.has_curtain then
        data.has_curtain = inst.has_curtain
    end

    if inst.onbuilt then
        data.onbuilt = inst.onbuilt
    end
    if inst.recipeproxy then
        data.recipeproxy = inst.recipeproxy
    end

    if inst:HasTag("roc_cave_delete_me")then
        data.roc_cave_delete_me = true
    end

    if inst.children_to_spawn then
        data.children_to_spawn = inst.children_to_spawn
    end

    if inst.rotate_flip_fixed then
        data.rotate_flip_fixed = true
    end

    return references
end

local function OnLoad(inst, data)
    if data.rotation then
        if inst.components.rotatingbillboard == nil then
            -- this component handle rotation save/load itself
            inst.Transform:SetRotation(data.rotation)
        end
    end
    if data.scalex then
        inst.Transform:SetScale(data.scalex, data.scaley, data.scalez)
    end
    if data.sunraysspawned then
        inst.sunraysspawned = data.sunraysspawned
    end
    if data.childrenspawned then
        inst.childrenspawned = data.childrenspawned
    end
    --if data.flipped then
    --    inst.flipped = data.flipped
    --end
    if data.dartthrower then
       inst:AddTag("dartthrower")
    end
    if data.dartthrower_right then
        inst:AddTag("dartthrower_right")
    end
    if  data.dartthrower_left then
        inst:AddTag("dartthrower_left")
    end
    if data.playercrafted then
        inst:AddTag("playercrafted")
    end
    if data.setbackground then
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(data.setbackground)
        inst.setbackground = data.setbackground
    end
    if data.animdata then
        inst.animdata = data.animdata
        if inst.animdata.build then
            inst.AnimState:SetBuild(inst.animdata.build)
        end
        if inst.animdata.bank then
            inst.AnimState:SetBank(inst.animdata.bank)
        end
        if inst.animdata.anim then
            inst.AnimState:PlayAnimation(inst.animdata.anim, inst.animdata.animloop)
        end
        if inst.components.rotatingbillboard then
            inst.components.rotatingbillboard:SetAnimation_Server(shallowcopy(inst.animdata, inst.components.rotatingbillboard.anim))
        end
    end
    if data.has_curtain then
        inst.AnimState:Show("curtain")
    end

    if data.onbuilt then
        SetPlayerUncraftable(inst)
        inst.onbuilt = data.onbuilt
    end

    if data.recipeproxy then
        inst.recipeproxy = data.recipeproxy
    end

    if data.roc_cave_delete_me then
        inst:AddTag("roc_cave_delete_me")
    end

    if data.children_to_spawn then
        inst.children_to_spawn = data.children_to_spawn
    end

    if data.rotate_flip_fixed then
        inst.rotate_flip_fixed = data.rotate_flip_fixed
    end
end

local function OnLoadPostPass(inst,ents, data)
    if data then
        -- if data.swinglight then
        --     local swinglight = ents[data.swinglight]
        --     if swinglight then
        --         inst.swinglight = swinglight.entity
        --     end
        -- end
        if data.dust then
            local dust = ents[data.dust]
            if dust then
                inst.dust = dust.entity
            end
        end

        inst.decochildrenToRemove = {}
        if data.children then
            for i,child in ipairs(data.children) do
                local childent = ents[child]
                if childent then
                    table.insert(inst.decochildrenToRemove, childent.entity)
                    if inst.components.rotatingbillboard then
                        childent.entity.AnimState:SetScale(inst.Transform:GetScale())
                    end
                end
            end
        end
    end
    if inst.updateworkableart then
        UpdateArtWorkable(inst,true)
    end

    -- 修复罕见的右侧柱翻转问题
    if inst.decal and inst.components.rotatingbillboard and not inst.rotate_flip_fixed then
        inst.rotate_flip_fixed = true
        local position = inst:GetPosition()
        local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(position)
        if current_interior then
            local originpt = current_interior:GetPosition()
            if position.z >= originpt.z then
                inst.Transform:SetRotation(90)
            end
        end
    end
end

local function OnRemove(inst)
    if inst.decochildrenToRemove then
        for _, child in pairs(inst.decochildrenToRemove) do
            child:Remove()
        end
    end

    if inst.swinglight then
        inst.swinglight:Remove()
    end
    if inst.dust then
        inst.dust:Remove()
    end
end

local phase_anims ={
    day = {
        enter = "to_day",
        loop = "day_loop",
    },
    dusk = {
        enter = "to_dusk",
        loop = "dusk_loop",
    },
    night = {
        enter = "to_night",
        loop = "night_loop",
    },
}

local function OnPhaseChange(inst, phase)
    inst.AnimState:PlayAnimation(phase_anims[phase].enter)
    inst.AnimState:PushAnimation(phase_anims[phase].loop, true)
end

local function mirror_blink_idle(inst)
    if inst.is_near then
        inst.AnimState:PlayAnimation("shadow_blink")
        inst.AnimState:PushAnimation("shadow_idle", true)
    end
    inst.blink_task = inst:DoTaskInTime(10 + math.random() * 50, mirror_blink_idle)
end

local function MirrorOnNear(inst)
    inst.AnimState:PlayAnimation("shadow_in")
    inst.AnimState:PushAnimation("shadow_idle", true)

    inst.blink_task = inst:DoTaskInTime(10 + math.random() * 50, mirror_blink_idle)
    inst.is_near = true
end

local function MirrorOnFar(inst)
    if inst.is_near then
        inst.AnimState:PlayAnimation("shadow_out")
        inst.AnimState:PushAnimation("idle", true)
        inst.is_near = nil
        inst.blink_task:Cancel()
        inst.blink_task = nil
    end
end

local function OnWorkCallBack(inst, worker, work_left)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")

    UpdateArtWorkable(inst)

    TheWorld:PushEvent("interior_startquake", {
        interiorID = inst:GetCurrentInteriorID(),
        quake_level = work_left <= 0 and INTERIOR_QUAKE_LEVELS.PILLAR_DESTROYED or INTERIOR_QUAKE_LEVELS.PILLAR_WORKED,
    })
end

local function swapColor(inst, light)
    if inst.iswhite then
        inst.iswhite = false
        inst.isred = true
        inst.components.lighttweener:StartTween(light, Lerp(0, 3, 1), nil, nil, {240/255, 100/255, 100/255}, 0.2, swapColor)
    elseif inst.isred then
        inst.isred = false
        inst.isgreen = true
        inst.components.lighttweener:StartTween(light, Lerp(0, 3, 1), nil, nil, {240/255, 230/255, 100/255}, 0.2, swapColor)
    else
        inst.isgreen = false
        inst.iswhite =true
        inst.components.lighttweener:StartTween(light, Lerp(0, 3, 1), nil, nil, {100/255, 240/255, 100/255}, 0.2, swapColor)
    end
end

local function MakeDeco(build, bank, animframe, data, name)
    if not data then
        data = {}
    end

    local loopanim = data.loopanim
    local decal = data.decal
    local background = data.background
    local finaloffset = data.finaloffset
    local light = data.light
    local followlight = data.followlight
    local scale = data.scale
    local mirror = data.mirror
    local physics = data.physics
    local windowlight = data.windowlight
    local workable = data.workable
    local prefabname = data.prefabname
    local minimapicon = data.minimapicon
    local tags = data.tags or {}
    local name_override = data.recipeproxy or data.name_override

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild(build)
        inst.bank = bank -- Used in wall ornaments and window's on_built_fn
        inst.AnimState:SetBank(bank)
        inst.AnimState:PlayAnimation(animframe, loopanim)
        if scale then
            inst.AnimState:SetScale(scale.x, scale.y, scale.z)
        end
        if background then
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
            inst.AnimState:SetSortOrder(background)
            inst.setbackground = background
        end
        if finaloffset then
            inst.AnimState:SetFinalOffset(finaloffset)
        end
        if loopanim then
            inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())
        end
        if not data.curtains then
            inst.AnimState:Hide("curtain")
        end
        if data.bloom then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
        if name == "deco_palace_beam_room_tall_corner" then
            -- fix layer
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        end
        if data.adjustanim then
            if false then
                inst.AnimState:PlayAnimation(animframe .. "_front")
            else
                inst.AnimState:PlayAnimation(animframe .. "_side")
            end
        end

        if light then
            if followlight then
                inst:DoTaskInTime(0, function()
                    if not TheWorld.ismastersim then
                        return
                    end
                    -- if inst.sunraysspawned then
                    --     return
                    -- end
                    -- inst.sunraysspawned = true

                    inst.swinglight = SpawnPrefab("swinglightobject")
                    inst.swinglight.setLightType(inst.swinglight, followlight)
                    inst.swinglight.persists = false
                    if windowlight then
                        inst.swinglight.setListenEvents(inst.swinglight)
                    end
                    -- NOTE: set arbitrary light position here
                    if inst.components.rotatingbillboard then
                        local offset = TUNING.PL_MANUAL_LIGHT_OFFSET[name:upper()] or TUNING.PL_MANUAL_LIGHT_OFFSET.DEFAULT
                        inst.swinglight.entity:SetParent(inst.entity)
                        inst.swinglight.offset = Vector3(0.01, offset[1], offset[2])
                        inst.components.rotatingbillboard:UpdateLightPosition()
                    else
                        inst.swinglight.entity:SetParent(inst.entity)
                        local follower = inst.swinglight.Follower
                        follower:FollowSymbol(inst.GUID, "light_circle", 0, 0, 0)
                        inst.swinglight.followobject = {GUID = inst.GUID, symbol = "light_circle", x = 0, y = 0, z = 0}
                    end
                end)
            else
                inst.entity:AddLight()
                inst.Light:SetIntensity(light.intensity)
                inst.Light:SetColour(light.color[1], light.color[2], light.color[3])
                inst.Light:SetFalloff(light.falloff)
                inst.Light:SetRadius(light.radius)
                inst.Light:Enable(true)

                inst:AddComponent("fader")
            end

            if data.blink then
                inst:AddComponent("lighttweener")
                swapColor(inst, inst.Light)
            end
        end

        if minimapicon then
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon(minimapicon)
        end

        if physics then
            if physics == "sofa_physics" then
                MakeInteriorPhysics(inst, 1.3, 1, 0.2)
            elseif physics == "sofa_physics_vert" then
                MakeInteriorPhysics(inst, 0.2, 1, 1.3)
            elseif physics == "chair_physics_small" then
                MakeObstaclePhysics(inst, 0.5)
            elseif physics == "chair_physics" then
                MakeInteriorPhysics(inst, 1, 1, 1)
            elseif physics == "desk_physics" then
                MakeInteriorPhysics(inst, 2, 1, 1)
            elseif physics == "tree_physics" then
                inst:AddTag("blocker")
                inst.entity:AddPhysics()
                inst.Physics:SetMass(0)
                inst.Physics:SetCapsule(4.7, 1)
                inst:SetDeployExtraSpacing(5)
                inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.ITEMS)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            elseif physics == "pond_physics" then
                inst:AddTag("blocker")
                inst.entity:AddPhysics()
                inst.Physics:SetMass(0)
                inst.Physics:SetCapsule(1.6, 1)
                inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.ITEMS)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            elseif physics == "big_post_physics" then
                MakeObstaclePhysics(inst, 0.75)
            elseif physics == "post_physics" then
                MakeObstaclePhysics(inst, 0.25)
            end
        end

        inst.Transform:SetRotation(-90)
        if decal then
            inst.decal = true
            -- NOTE: only apply billborad render behavior on beam/pillar
            if name:find("_corner")
                or name:find("_beam")
                or name:find("_pillar")
                or (bank and bank:find("wall_decals"))
                or data.rotatingbillboard then

                inst:AddComponent("rotatingbillboard")

                inst.components.rotatingbillboard.animdata = {
                    bank = bank,
                    build = build,
                    anim = animframe,
                }
            else
                inst.Transform:SetTwoFaced()
            end
        else
            if data.rotatingbillboard then
                inst:AddComponent("rotatingbillboard")

                inst.components.rotatingbillboard.animdata = {
                    bank = bank,
                    build = build,
                    anim = animframe,
                }
            else
                inst.Transform:SetTwoFaced()
            end
        end
        
        if name_override then
            inst.name = STRINGS.NAMES[name_override:upper()]
            inst:SetPrefabNameOverride(name_override)
        end

        if TheWorld.ismastersim then
            if STRINGS.NAMES[string.upper(name)] then
                inst:AddComponent("inspectable")
            end

            if name_override then
                if not inst.components.inspectable then
                    inst:AddComponent("inspectable")
                end
                -- this way the backwall windows will show the right prefab name (with controller)
                inst.components.inspectable.nameoverride = name_override
            end
        end

        for _, tag in pairs(tags) do
            inst:AddTag(tag)
        end

        if prefabname then
            if TheWorld.ismastersim and not inst.components.inspectable then
                inst:AddComponent("inspectable")
            end

            inst:SetPrefabName(prefabname)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        if data.children then
            inst.children_to_spawn = data.children -- Can be overriden in onbuilt
            inst:DoTaskInTime(0, function()
                -- don't spawn child in client
                if inst.childrenspawned then
                    return
                end

                for _, child in pairs(inst.children_to_spawn) do
                    local child_prop = SpawnPrefab(child)
                    local x, y, z = inst.Transform:GetWorldPosition()
                    child_prop.Transform:SetPosition(x, y, z)
                    if inst.components.rotatingbillboard and inst.components.rotatingbillboard.rotation_set then -- rotation_set属性用于判断rotatingbillboard组件是否完成初始化
                        child_prop.Transform:SetRotation(inst.components.rotatingbillboard:GetRotation())
                    else
                        child_prop.Transform:SetRotation(inst.Transform:GetRotation())
                    end
                    if not inst.decochildrenToRemove then
                        inst.decochildrenToRemove = {}
                    end
                    inst.decochildrenToRemove[#inst.decochildrenToRemove + 1] = child_prop
                end
                inst.childrenspawned = true
           end)
        end

        if mirror then
            inst:AddComponent("playerprox")
            inst.components.playerprox:SetOnPlayerNear(MirrorOnNear)
            inst.components.playerprox:SetOnPlayerFar(MirrorOnFar)
            inst.components.playerprox:SetDist(2, 2.1)
        end

        if workable then
            if not inst.components.inspectable then
                inst:AddComponent("inspectable")
            end

            inst.entity:AddSoundEmitter()

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.MINE)
            inst.components.workable:SetWorkLeft(TUNING.DECO_RUINS_BEAM_WORK)
            inst.components.workable:SetMaxWork(TUNING.DECO_RUINS_BEAM_WORK)
            inst.components.workable.savestate = true
            inst.components.workable:SetOnWorkCallback(OnWorkCallBack)
            inst.updateworkableart = true
        end

        if data.cansit then
            inst:AddComponent("sittable")
            if not finaloffset then
                inst.AnimState:SetFinalOffset(-1)
            end
        end

        if prefabname == "pig_latin_1" then
            inst:AddTag("pig_writing_1")
            inst:ListenForEvent("entitywake", function(inst, data)
                inst:DoTaskInTime(1, function()
                    local should_close_doors = false

                    local x, y, z = inst.Transform:GetWorldPosition()
                    local torches = TheSim:FindEntities(x, y, z, 50, {"wall_torch"})

                    for _, torch in pairs(torches) do
                        if not torch.components.cooker then
                            should_close_doors = true
                        end
                    end

                    if not should_close_doors then
                        return
                    end

                    local ents = TheSim:FindEntities(x, y, z, 50, {"lockable_door"})
                    for _, ent in pairs(ents) do
                        if ent ~= data.door then
                            ent:PushEvent("close")
                        end
                    end
                end)
            end)

            inst:ListenForEvent("fire_lit", function()
                local should_open_doors = true

                local x, y, z = inst.Transform:GetWorldPosition()
                local torches = TheSim:FindEntities(x, y, z, 50, {"wall_torch"})

                for _, torch in pairs(torches) do
                    if not torch.components.cooker then
                        should_open_doors = false
                    end
                end

                if not should_open_doors then
                    return
                end

                local ents = TheSim:FindEntities(x, y, z, 50, {"lockable_door"})
                for _, ent in pairs(ents) do
                    ent:PushEvent("open")
                end
            end)
        end

        if inst.components.inspectable then
            inst:AddComponent("hauntable")
        end

        inst:ListenForEvent("onremove", OnRemove)
        if data.onbuilt then
            inst.on_built_fn = data.on_built_fn
            inst:ListenForEvent("onbuilt", OnBuilt)
        end
        if data.dayevents then
            inst:WatchWorldState("phase", OnPhaseChange)
            OnPhaseChange(inst, TheWorld.state.phase)
            inst.AnimState:FastForward(10)
        end

        inst:DoTaskInTime(0, function()
            if inst:HasTag("playercrafted") then
                SetPlayerUncraftable(inst)
            end
        end)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.LoadPostPass = OnLoadPostPass

        if data.recipeproxy then
            inst.recipeproxy = data.recipeproxy
        end

        return inst
    end
    return fn
end


local LIGHTS =
{
    SUNBEAM =
    {
        intensity = 0.9,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.5,
        radius    = 2,
    },

    SMALL =
    {
        intensity = 0.75,
        color     = {97/255, 197/255, 50/255},
        falloff   = 0.7,
        radius    = 1,
    },

    MED =
    {
        intensity = 0.9,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.5,
        radius    = 3,
    },

    SMALL_YELLOW =
    {
        intensity = 0.75,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.7,
        radius    = 1,
    },
    FESTIVETREE =
    {
        intensity = 0.9,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.5,
        radius    = 3,
    },

}

local DecoCreator = Class(function(self)

end)

function DecoCreator:Create(name, build, bank, anim, data)
    return Prefab(name, MakeDeco(build, bank, anim, data, name), assets, prefabs)
end

function DecoCreator:GetLights()
    return LIGHTS
end

function DecoCreator:IsBuiltOnBackWall(inst)
    local position = inst:GetPosition()
    local current_interior = TheWorld.components.interiorspawner:GetInteriorCenter(position)
    if current_interior then
        local room_center = current_interior:GetPosition()
        local width, depth = current_interior:GetSize()

        local dist = 2
        local backdiff =  position.x < (room_center.x - depth/2 + dist)
        -- local frontdiff = position.x > (room_center.x + depth/2 - dist)
        local rightdiff = position.z > (room_center.z + width/2 - dist)
        local leftdiff =  position.z < (room_center.z - width/2 + dist)

        local is_backwall = backdiff and not rightdiff and not leftdiff
        return is_backwall
    end
    return false
end

return DecoCreator
