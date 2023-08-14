local assets =
{
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

    -- colourcube
    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/dusk03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snow_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snowdusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night04_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/lunacy_regular_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/purple_moon_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/moonstorm_cc.tex"),

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

    Asset("IMAGE", "images/wave.tex"),
    Asset("IMAGE", "images/wave_shadow.tex"),
    Asset("IMAGE", "images/could/fog_cloud.tex"),

    Asset("PKGREF", "levels/models/waterfalls.bin"),

    Asset("ANIM", "anim/lightning.zip"),

    Asset("ANIM", "anim/swimming_ripple.zip"), -- common water fx symbols

    Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
    Asset("SOUND", "sound/DLC003_sfx.fsb"),
}

local prefabs =
{
    "beefalo",
    "cave_entrance",
    "rain",
    "pollen",
    "porkland_network",
}

local function tile_physics_init(inst, ...)
    -- a slightly modified version of the forest map's primary collider.
    inst.Map:AddTileCollisionSet(
        COLLISION.LAND_OCEAN_LIMITS,
        TileGroups.TransparentOceanTiles, true,
        TileGroups.LandTiles, true,
        0.25, 64
    )
    -- PL's ocean collider
    inst.Map:AddTileCollisionSet(
        COLLISION.LAND_OCEAN_LIMITS,
        TileGroups.LandTiles, true,
        TileGroups.IAOceanTiles, true,
        0.25, 64
    )
    -- standard impassable collider
    inst.Map:AddTileCollisionSet(
        COLLISION.GROUND,
        TileGroups.ImpassableTiles, true,
        TileGroups.ImpassableTiles, false,
        0.25, 128
    )
end

local function common_postinit(inst)
    -- Add waves
    inst.entity:AddWaveComponent()
    inst.WaveComponent:SetWaveParams(13.5, 2.5, -1)  -- wave texture u repeat, forward distance between waves
    inst.WaveComponent:SetWaveSize(80, 3.5)  -- wave mesh width and height
    inst.WaveComponent:SetWaveMotion(3, 0.5, 0.25)
    inst.WaveComponent:SetWaveTexture(resolvefilepath("images/could/fog_cloud.tex"))
    -- See source\game\components\WaveRegion.h
    inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")

    -- Initialize lua components
    inst:AddComponent("ambientlighting")

    -- Dedicated server does not require these components
    -- NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        -- inst:AddComponent("dynamicmusic")
        -- inst:AddComponent("ambientsound")
        inst:AddComponent("dsp")
        inst:AddComponent("colourcube")
        inst:AddComponent("hallucinations")
        inst:AddComponent("wavemanager")
        inst.Map:SetUndergroundFadeHeight(0)
        inst.Map:AlwaysDrawWaves(true)
        inst.Map:DoOceanRender(true)
    end
end

local function master_postinit(inst)
    inst.has_ia_ocean = true

    -- Spawners
    inst:AddComponent("birdspawner")
    inst:AddComponent("butterflyspawner")
    inst:AddComponent("glowflyspawner")

    inst:AddComponent("worlddeciduoustreeupdater")
    inst:AddComponent("kramped")

    inst:AddComponent("hunter")
    inst:AddComponent("lureplantspawner")
    inst:AddComponent("shadowcreaturespawner")
    inst:AddComponent("shadowhandspawner")
    inst:AddComponent("brightmarespawner")
    inst:AddComponent("worldwind")

    inst:AddComponent("regrowthmanager")
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
end

return MakeWorld("porkland", prefabs, assets, common_postinit, master_postinit, {"porkland"}, {tile_physics_init = tile_physics_init})
