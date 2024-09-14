local assets =
{
    Asset("INV_IMAGE", "interior_floor_marble"),
    Asset("INV_IMAGE", "interior_floor_check"),
    Asset("INV_IMAGE", "interior_floor_plaid_tile"),
    Asset("INV_IMAGE", "interior_floor_sheet_metal"),
    Asset("INV_IMAGE", "interior_floor_wood"),
    Asset("INV_IMAGE", "interior_wall_wood"),
    Asset("INV_IMAGE", "interior_wall_checkered"),
    Asset("INV_IMAGE", "interior_wall_floral"),
    Asset("INV_IMAGE", "interior_wall_sunflower"),
    Asset("INV_IMAGE", "interior_wall_harlequin"),
}

local FACE = {
    WALL = 1,
    FLOOR = 2,
}

local function OnBuilt(inst)
    local room = TheWorld.components.interiorspawner:GetInteriorCenter(inst:GetPosition())
    if room then
        if inst.face == FACE.FLOOR then
            room:SetInteriorFloorTexture(inst.texture)
            room:SetFloorMinimapTex(inst.minimap_texture)
        elseif inst.face == FACE.WALL then
            room:SetInteriorWallsTexture(inst.texture)
        end
    end
    inst:Remove()
end

local function material(name, face, texture, minimap_texture)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()

        if not TheWorld.ismastersim then
            return
        end

        inst.face = face
        inst.texture = texture
        inst.minimap_texture = minimap_texture or "levels/textures/map_interior/mini_floor_wood.tex"

        inst:ListenForEvent("onbuilt", OnBuilt)
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end
    return Prefab(name, fn, assets)
end

return  material("interior_floor_marble", FACE.FLOOR, "levels/textures/interiors/shop_floor_marble.tex"),
        material("interior_floor_check", FACE.FLOOR, "levels/textures/interiors/shop_floor_checker.tex"),
        material("interior_floor_check2", FACE.FLOOR, "levels/textures/interiors/shop_floor_checkered.tex"),
        material("interior_floor_plaid_tile", FACE.FLOOR, "levels/textures/interiors/floor_cityhall.tex"),
        material("interior_floor_sheet_metal", FACE.FLOOR, "levels/textures/interiors/shop_floor_sheetmetal.tex"),
        material("interior_floor_wood", FACE.FLOOR, "levels/textures/noise_woodfloor.tex"),

        material("interior_wall_wood", FACE.WALL, "levels/textures/interiors/shop_wall_woodwall.tex"),
        material("interior_wall_checkered", FACE.WALL, "levels/textures/interiors/shop_wall_checkered_metal.tex"),
        material("interior_wall_floral", FACE.WALL, "levels/textures/interiors/shop_wall_floraltrim2.tex"),
        material("interior_wall_sunflower", FACE.WALL, "levels/textures/interiors/shop_wall_sunflower.tex"),
        material("interior_wall_harlequin", FACE.WALL, "levels/textures/interiors/harlequin_panel.tex"),
--
        material("interior_floor_gardenstone", FACE.FLOOR, "levels/textures/interiors/floor_gardenstone.tex"),
        material("interior_floor_geometrictiles", FACE.FLOOR, "levels/textures/interiors/floor_geometrictiles.tex"),
        material("interior_floor_shag_carpet", FACE.FLOOR, "levels/textures/interiors/floor_shag_carpet.tex"),
        material("interior_floor_transitional", FACE.FLOOR, "levels/textures/interiors/floor_transitional.tex"),
        material("interior_floor_woodpanels", FACE.FLOOR, "levels/textures/interiors/floor_woodpanels.tex", "levels/textures/map_interior/mini_floor_woodpanels.tex"),
        material("interior_floor_herringbone", FACE.FLOOR, "levels/textures/interiors/shop_floor_herringbone.tex"),
        material("interior_floor_hexagon", FACE.FLOOR, "levels/textures/interiors/shop_floor_hexagon.tex"),
        material("interior_floor_hoof_curvy", FACE.FLOOR, "levels/textures/interiors/shop_floor_hoof_curvy.tex"),
        material("interior_floor_octagon", FACE.FLOOR, "levels/textures/interiors/shop_floor_octagon.tex"),

        material("interior_wall_peagawk", FACE.WALL, "levels/textures/interiors/wall_peagawk.tex"),
        material("interior_wall_plain_ds", FACE.WALL, "levels/textures/interiors/wall_plain_DS.tex"),
        material("interior_wall_plain_rog", FACE.WALL, "levels/textures/interiors/wall_plain_RoG.tex"),
        material("interior_wall_rope", FACE.WALL, "levels/textures/interiors/wall_rope.tex"),
        material("interior_wall_circles", FACE.WALL, "levels/textures/interiors/shop_wall_circles.tex"),
        material("interior_wall_marble", FACE.WALL, "levels/textures/interiors/shop_wall_marble.tex"),
        material("interior_wall_mayorsoffice", FACE.WALL, "levels/textures/interiors/wall_mayorsoffice_whispy.tex"),
        material("interior_wall_fullwall_moulding", FACE.WALL, "levels/textures/interiors/shop_wall_fullwall_moulding.tex"),
        material("interior_wall_upholstered", FACE.WALL, "levels/textures/interiors/shop_wall_upholstered.tex")
