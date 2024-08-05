local defs = require("main/interior_texture_defs")
local TEXTURE_DEF = defs.TEXTURE_DEF
local TEXTURE_DEF_INDEX = defs.TEXTURE_DEF_INDEX

local SURFACE = {
    WALL = "wall",
    FLOOR = "floor",
}

local WALL_TILE_SCALE = 5
local WALL_TILE_SHEAR = 0.91
local WALL_TILE_X_OFFSET = 0.21
local FLOOR_TILE_SCALE = 16

local function UpdateFx(inst)
    -- NOTE: a surface entity only support single texture
    local index = inst.texture_index:value()
    if TEXTURE_DEF[index] then
        local path = TEXTURE_DEF[index].path
        for k, v in pairs(inst.fx) do
            k:Remove()
        end
        inst.fx = {}
        if inst.interior_type == SURFACE.FLOOR then
            local w = inst.size_x:value()
            local h = inst.size_z:value()
            local mod = 1
            if path:find("noise_woodfloor") then
                mod = 7/8
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
                    inst.fx[fx] = true
                end
            end
        elseif inst.interior_type == SURFACE.WALL then
            local w = inst.size_x:value()
            local last_fx = nil
            local y = 0.5*WALL_TILE_SCALE*WALL_TILE_SHEAR
            local xoffset = 0.5*WALL_TILE_SCALE*WALL_TILE_X_OFFSET
            local mod = 1
            if path:find("wall_royal_high") then
                y = y * 2
                xoffset = xoffset * 2
            elseif path:find("batcave_wall_rock") then
                y = y * 1.8
                xoffset = xoffset * 1.8
                mod = 1.8
            end
            local WALL_TILE_SCALE = WALL_TILE_SCALE * mod
            for x = 0, w/WALL_TILE_SCALE do
                local fx = SpawnPrefab("interiorwall_fx")
                if inst.prefab:find("_x") then
                    fx.is_x = true
                    fx.Transform:SetPosition((x + 0.5) * WALL_TILE_SCALE - xoffset - y * 0.25, y, 0)
                else
                    fx.Transform:SetPosition( - y * 0.5, y, (x + 0.5) * WALL_TILE_SCALE)
                end
                fx.entity:SetParent(inst.entity)
                inst.fx[fx] = true
                last_fx = fx -- get last one by override
            end

            -- fix render of last wall tile
            if last_fx then
                local p = select(2, math.modf(w/WALL_TILE_SCALE))
                last_fx.w_percent = p
                local x, _, z = last_fx.Transform:GetLocalPosition()
                if inst.prefab:find("_x") then
                    last_fx.Transform:SetPosition(x - (1-p)*WALL_TILE_SCALE/2, y, 0)
                else
                    last_fx.Transform:SetPosition(- y * 0.5, y, z - (1-p)*WALL_TILE_SCALE/2)
                end
            end

            for fx in pairs(inst.fx)do
                fx:SetTexture(path)
            end
        end
    end
end

local function ClearFx(inst)
    for k, v in pairs(inst.fx)do
        inst.fx[k] = nil
        k:Remove()
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
    --UpdateFx(inst)
end

local function SetSizeXZ(inst, x, z)
    inst.size_x:set(x)
    inst.size_z:set(z)
    --UpdateFx(inst)
end

local function OnThePlayerNear(inst)
    UpdateFx(inst)
end

local function OnThePlayerFar(inst)
    ClearFx(inst)
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

    inst.OnThePlayerNear = OnThePlayerNear
    inst.OnThePlayerFar = OnThePlayerFar

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

    inst.interior_type = SURFACE.WALL

    inst.size_x = net_byte(inst.GUID, "size_x", "size")
    inst.size_x:set_local(1)

    inst.texture_name = nil
    inst.texture_path = nil
    inst.texture_index = net_byte(inst.GUID, "texture_index", "texture_index")
    inst.texture_index:set_local(0)

    inst:AddTag("NOBLOCK")
    inst.fx = {}

    inst.OnThePlayerNear = OnThePlayerNear
    inst.OnThePlayerFar = OnThePlayerFar

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
