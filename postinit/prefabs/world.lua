local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("world", function(inst)
	local _tile_physics_init = inst.tile_physics_init
	inst.tile_physics_init = function(inst, ...)
        print("new_tile_physics_init", inst:HasTag("forest"))

        if inst:HasTag("forest") then
            --a slightly modified version of the forest map's primary collider.
            inst.Map:AddTileCollisionSet(
                COLLISION.LAND_OCEAN_LIMITS,
                TileGroups.TransparentOceanTiles, true,
                TileGroups.LandTiles, true,
                0.25, 64
            )
            --IA's ocean collider
            inst.Map:AddTileCollisionSet(
                COLLISION.LAND_OCEAN_LIMITS,
                TileGroups.LandTiles, true,
                TileGroups.PLOceanTiles, true,
                0.25, 64
            )
            --standard impassable collider
            inst.Map:AddTileCollisionSet(
                COLLISION.LAND_OCEAN_LIMITS,
                TileGroups.ImpassableTiles, true,
                TileGroups.ImpassableTiles, false,
                0.25, 128
            )
            return
        end
        return _tile_physics_init ~= nil and _tile_physics_init(inst, ...)
    end

end)
