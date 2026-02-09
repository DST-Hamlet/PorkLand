local assets =
{
    -- porkland colourcube
    Asset("IMAGE", "images/colour_cubes/pork_temperate_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_temperate_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_temperate_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_temperate_fullmoon_cc.tex"),
    -- Asset("IMAGE", "images/colour_cubes/pork_temperate_bloodmoon_cc.tex"),

    Asset("IMAGE", "images/colour_cubes/pork_cold_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_cold_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_cold_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_cold_fullmoon_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_cold_bloodmoon_cc.tex"),

    -- Asset("IMAGE", "images/colour_cubes/pork_warm_day_cc.tex"),
    -- Asset("IMAGE", "images/colour_cubes/pork_warm_dusk_cc.tex"),
    -- Asset("IMAGE", "images/colour_cubes/pork_warm_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_warm_fullmoon_cc.tex"),
    -- Asset("IMAGE", "images/colour_cubes/pork_warm_bloodmoon_cc.tex"),

    Asset("IMAGE", "images/colour_cubes/pork_lush_dusk_test.tex"),
    Asset("IMAGE", "images/colour_cubes/pork_lush_day_test.tex"),

    Asset("IMAGE", "images/cloud/fog_cloud.tex"),
    Asset("IMAGE", "images/cloud/fog_cloud_interior.tex"),
}

local prefabs =
{
    "porkland_network",
}

for _, asset in pairs(Prefabs["forest"].assets) do
    table.insert(assets, asset)
end

for _, prefab in pairs(Prefabs["forest"].deps) do
    table.insert(prefabs, prefab)
end

local ex_fns = require("prefabs/player_common_extensions")

-- https://forums.kleientertainment.com/forums/topic/140904-tiles-changes-and-more/
local function tile_physics_init(inst, ...)
    -- PL's ocean collider
    inst.Map:AddTileCollisionSet(
        COLLISION.LAND_OCEAN_LIMITS,
        TileGroups.PlOceanTiles, false,
        TileGroups.PlOceanTiles, true,
        0.25, 128 -- 亚丹: 最后一个参数是在C层切分的碰撞体的大小, 值越小碰撞体重建越快, 但是不重建时的性能越差
    )
    -- standard impassable collider
    inst.Map:AddTileCollisionSet(
        COLLISION.VOID_LIMITS,
        TileGroups.ImpassableTiles, true,
        TileGroups.ImpassableTiles, false,
        0.25, 128
    )
end


local function OnNewPlayerSpawned(src, player)
    ex_fns.GivePlayerStartingItems(player, { "machete" })
end

local TileManager = require "tilemanager"
local GroundTiles = require "worldtiledefs"

local function common_preinit(inst)
    mod_protect_TileManager = false
    for k, v in pairs(GroundTiles.falloff) do
        GroundTiles.falloff[k] = nil
    end
    mod_protect_TileManager = true
end

local function common_postinit(inst)
    inst.has_pl_ocean = true
    inst.items_pass_ground = true

    -- Add waves
    -- inst.entity:AddWaveComponent()
    -- inst.WaveComponent:SetWaveParams(13.5, 2.5, -1)  -- wave texture u repeat, forward distance between waves
    -- inst.WaveComponent:SetWaveSize(80, 3.5)  -- wave mesh width and height
    -- inst.WaveComponent:SetWaveMotion(0.3, 0.5, 0.25)
    -- inst.WaveComponent:SetWaveTexture(resolvefilepath("images/cloud/fog_cloud.tex"))
    -- See source\game\components\WaveRegion.h
    -- inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")

    -- Initialize lua components
    inst:AddComponent("ambientlighting")

    -- Dedicated server does not require these components
    -- NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        inst:AddComponent("pl_dynamicmusic")
        inst:AddComponent("pl_ambientsound")
        inst:AddComponent("dsp")
        inst:AddComponent("colourcube")
        inst:AddComponent("hallucinations")
        inst:AddComponent("wavemanager")
        inst:AddComponent("canopymanager")
        local rainforest_shade = {spawn = SpawnRainforestCanopy, despawn = DespawnRainforestCanopy}
        inst.components.canopymanager:AddShadeTile(WORLD_TILES.DEEPRAINFOREST, rainforest_shade)
        inst.components.canopymanager:AddShadeTile(WORLD_TILES.GASJUNGLE, rainforest_shade)
        inst:AddComponent("pl_waterfallsoundcontroller")
        inst:AddComponent("cloudmanager")
        inst.components.cloudmanager:Init()

        inst.Map:SetUndergroundFadeHeight(0)
        inst.Map:AlwaysDrawWaves(true)
    end

    inst:AddComponent("interiorspawner")
    inst:AddComponent("worldpathfindermanager")
    inst:AddComponent("worldsoundmanager")
    inst:AddComponent("clientundertile")
    inst:AddComponent("interiormaprevealer")
end

local function master_postinit(inst)
    -- Spawners
    inst:AddReplaceComponent("pl_birdspawner", "birdspawner")
    inst:AddComponent("butterflyspawner")
    inst:AddComponent("glowflyspawner")
    inst:AddComponent("hippospawner")
    inst:AddComponent("spidermonkeyherd")
    inst:AddComponent("batted")
    inst:AddComponent("bramblemanager")
    inst:AddComponent("banditmanager")
    inst:AddComponent("rainforestflowerregrowth")
    inst:AddComponent("giantgrubspawner")
    inst:AddComponent("rocmanager")

    inst:AddComponent("worlddeciduoustreeupdater")
    inst:AddComponent("kramped")

    inst:AddComponent("hunter")
    inst:AddComponent("lureplantspawner")
    inst:AddComponent("shadowcreaturespawner")
    inst:AddComponent("shadowhandspawner")
    inst:AddComponent("brightmarespawner")
    inst:AddComponent("pl_worldwind")
    inst:AddComponent("shadowmanager")

    --inst:AddComponent("regrowthmanager")
    -- inst:AddComponent("desolationspawner")
    -- inst:AddComponent("forestpetrification")

    inst:AddComponent("specialeventsetup")
    inst:AddComponent("townportalregistry")
    inst:AddComponent("mermkingmanager")

    if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
        inst:AddComponent("gingerbreadhunter")
    end

    inst:AddComponent("feasts")

    inst:AddComponent("carnivalevent")

    inst:AddComponent("yotc_raceprizemanager")
    inst:AddComponent("yotb_stagemanager")

    if METRICS_ENABLED then
        inst:AddComponent("worldoverseer")
    end
    inst:AddComponent("interiorquaker")

    inst:AddComponent("economy")
    inst.components.economy:AddCity(1)
    inst.components.economy:AddCity(2)

    inst:AddComponent("periodicpoopmanager")

    inst:AddComponent("cityalarms")
    inst.components.cityalarms:AddCity(1)
    inst.components.cityalarms:AddCity(2)

    -- Not a component from Hamlet
    inst:AddComponent("pigtaxmanager")

    inst:ListenForEvent("ms_newplayerspawned", OnNewPlayerSpawned)
end

return MakeWorld("porkland", prefabs, assets, common_postinit, master_postinit, {"porkland"}, {common_preinit = common_preinit, tile_physics_init = tile_physics_init})
