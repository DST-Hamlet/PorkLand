AddLocation({
    location = "porkland",
    version = 2,
    overrides = {
        start_location = "PorkLandStart",
        task_set = "porkland",
        season_start = "default",
        world_size = "default",
        layout_mode = "RestrictNodesByKey",  -- don't use this, but it cant be nil
        wormhole_prefab = "wormhole",
        roads = "never",
        keep_disconnected_tiles = true,
        no_wormholes_to_disconnected_tiles = true,
        no_joining_islands = true,
        has_ocean = false,
    },
    required_prefabs = {
        "multiplayer_portal",
    },
})
