local defs = require("main/interior_texture_defs")
local TEXTURE_DEF = defs.TEXTURE_DEF
local TEXTURE_DEF_INDEX = defs.TEXTURE_DEF_INDEX

local SURFACE = {
    WALL = "wall",
    FLOOR = "floor",
}

-- 特殊情况：
--     蝙蝠洞：墙的纹理都是默认尺寸的2倍，地皮的纹理都是默认尺寸的1.8倍
--     蚂蚁洞：墙的纹理都是默认尺寸的2倍，地皮的纹理都是默认尺寸的1.8倍
--     皇宫：墙的高度是默认尺寸的1.2倍，宽度是2倍
--     木地板：纹理缩放倍率是默认的7/5，因为这样视觉效果更好

local WALL_TILE_SCALE = 6.25 -- 5/8
local WALL_TILE_SHEAR = 0
local WALL_TILE_X_OFFSET = 0
local FLOOR_TILE_SCALE = 16

local function ClearFx(inst)
    for k, v in pairs(inst.fx) do
        v:Remove()
        inst.fx[k] = nil
    end
end

local function UpdateFx(inst)
    if not ThePlayer then
        return
    end

    -- NOTE: a surface entity only support single texture
    local index = inst.texture_index:value()
    local texture = TEXTURE_DEF[index]
    if not texture then
        return
    end

    local path = texture.path
    ClearFx(inst)
    if inst.fx == nil then
        inst.fx = {}
    end
    if inst.interior_type == SURFACE.FLOOR then
        local w = inst.size_x:value()
        local h = inst.size_z:value()
        local mod = 1
        if path:find("noise_woodfloor") then -- 特殊情况
            mod = 7/8
        elseif path:find("batcave_floor") or path:find("ground_ruins_slab") or path:find("antcave_floor") then
            mod = 9/8
        elseif path:find("floor") then
            mod = 5/8
        end
        local FLOOR_TILE_SCALE = FLOOR_TILE_SCALE * mod
        for x = 0, w/FLOOR_TILE_SCALE do
            local x_left = w/FLOOR_TILE_SCALE - x
            local x_offset = x_left < 1 and (1 - x_left) * FLOOR_TILE_SCALE / 2 or 0
            for z = 0, h / FLOOR_TILE_SCALE do
                local z_left = h / FLOOR_TILE_SCALE - z
                local z_offset = z_left < 1 and (1-z_left)*FLOOR_TILE_SCALE/2 or 0
                local fx = SpawnPrefab("interiorfloor_fx")
                fx.Transform:SetPosition((x + 0.5) * FLOOR_TILE_SCALE - x_offset, 0, (z + 0.5) * FLOOR_TILE_SCALE - z_offset)
                fx.h_percent = x_left < 1 and x_left or nil
                fx.w_percent = z_left < 1 and z_left or nil
                fx:SetTexture(path)
                fx.entity:SetParent(inst.entity)
                table.insert(inst.fx, fx)
            end
        end
    elseif inst.interior_type == SURFACE.WALL then
        local w = inst.size_x:value()
        local last_fx = nil
        local y = 2.2360679775 * 1.08 -- sqr(5)
        local mod = 0.8
        if path:find("wall_royal_high") then
            y = y * 2.2
            mod = mod * 2
        elseif path:find("batcave_wall_rock") then
            y = y * 2
            mod = mod * 2
        elseif path:find("antcave_wall_rock") then
            y = y * 1.25
            mod = mod * 1.5
        end
        local WALL_TILE_SCALE = WALL_TILE_SCALE * mod
        for x = 0, w/WALL_TILE_SCALE do
            local fx = SpawnPrefab("interiorwall_fx")
            table.insert(inst.fx, fx)
            if inst.prefab:find("_x") then
                fx.is_x = true
                fx.Transform:SetPosition((x + 0.5) * WALL_TILE_SCALE - y * 0.5, y, 0)
            else
                fx.Transform:SetPosition( - y * 0.5, y, (x + 0.5) * WALL_TILE_SCALE)
            end
            fx.entity:SetParent(inst.entity)
            last_fx = fx -- get last one by override
        end

        -- fix render of last wall tile
        if last_fx then
            local p = w/WALL_TILE_SCALE - math.floor(w/WALL_TILE_SCALE)
            last_fx.w_percent = p
            local x, _, z = last_fx.Transform:GetLocalPosition()
            if inst.prefab:find("_x") then
                last_fx.Transform:SetPosition(x - (1-p)*WALL_TILE_SCALE/2, y, 0)
            else
                last_fx.Transform:SetPosition(- y * 0.5, y, z - (1-p)*WALL_TILE_SCALE/2)
            end
        end

        for k, fx in pairs(inst.fx) do
            fx:SetTexture(path)
        end
    end
end

local function SetTextureIndex(inst, index)
    assert(TEXTURE_DEF[index])
    inst:SetTexture(TEXTURE_DEF[index].name)
end

local function SetTexture(inst, texture)
    local index = assert(TEXTURE_DEF_INDEX[texture], "interior texture not defined: "..texture)
    inst.texture_name = texture
    inst.texture_index:set(index)
    inst.texture_path = TEXTURE_DEF[index].path

    if not TheNet:IsDedicated() then
        UpdateFx(inst)
    end
end

local function SetSizeXZ(inst, x, z)
    inst.size_x:set(x)
    inst.size_z:set(z)

    if not TheNet:IsDedicated() then
        UpdateFx(inst)
    end
end

local function SetSizeX(inst, x)
    inst.size_x:set(x)
end

local function OnSave(inst, data)
    data.texture_name = inst.texture_name
end

local function OnLoad(inst, data)
    if data.texture_name and TEXTURE_DEF_INDEX[data.texture_name] ~= nil then
        inst:SetTexture(data.texture_name)
    end
end

local function floor_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.persists = false

    inst.interior_type = SURFACE.FLOOR

    inst.size_x = net_byte(inst.GUID, "size_x", "size")
    inst.size_x:set_local(1)
    inst.size_z = net_byte(inst.GUID, "size_z", "size")
    inst.size_z:set_local(1)

    inst.texture_name = nil
    inst.texture_path = nil
    inst.texture_index = net_byte(inst.GUID, "texture_index", "texture_index")
    inst.texture_index:set_local(0)

    inst:AddTag("NOBLOCK")
    inst.fx = {}

    if not TheNet:IsDedicated() then
        inst.OnEntityWake = UpdateFx
        inst.OnEntitySleep = ClearFx
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("texture_index", UpdateFx)
        inst:ListenForEvent("size", UpdateFx)
        return inst
    end

    inst.SetSize = SetSizeXZ
    inst.SetTexture = SetTexture
    inst.SetTextureIndex = SetTextureIndex -- for debug
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    return inst
end

local function wall_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.persists = false

    inst.interior_type = SURFACE.WALL

    inst.size_x = net_byte(inst.GUID, "size_x", "size")
    inst.size_x:set_local(1)

    inst.texture_name = nil
    inst.texture_path = nil
    inst.texture_index = net_byte(inst.GUID, "texture_index", "texture_index")
    inst.texture_index:set_local(0)

    inst:AddTag("NOBLOCK")
    inst.fx = {}

    if not TheNet:IsDedicated() then
        inst.OnEntityWake = UpdateFx
        inst.OnEntitySleep = ClearFx
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("texture_index", UpdateFx)
        inst:ListenForEvent("size", UpdateFx)
        return inst
    end

    inst.SetSize = SetSizeX
    inst.SetTexture = SetTexture
    inst.SetTextureIndex = SetTextureIndex -- for debug
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("interiorfloor", floor_fn),
       Prefab("interiorwall_x", wall_fn),
       Prefab("interiorwall_z", wall_fn)
