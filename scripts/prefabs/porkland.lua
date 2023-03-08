local assets =
{
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

    Asset("IMAGE", "levels/textures/snow.tex"),
    Asset("IMAGE", "levels/textures/mud.tex"),

    Asset("IMAGE", "images/wave.tex"),
    Asset("IMAGE", "images/wave_shadow.tex"),
    Asset("IMAGE", "images/could/fog_cloud.tex"),

    Asset("PKGREF", "levels/models/waterfalls.bin"),

    Asset("ANIM", "anim/snow.zip"),
    Asset("ANIM", "anim/lightning.zip"),

    Asset("ANIM", "anim/swimming_ripple.zip"), -- common water fx symbols
}

local prefabs =
{
    "cave_entrance",
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
        TileGroups.PLOceanTiles, true,
        0.25, 64
    )
    -- standard impassable collider
    inst.Map:AddTileCollisionSet(
        COLLISION.PERMEABLE_GROUND, -- maybe split permable into its own sub group in the future?
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
        inst:AddComponent("dynamicmusic")
        inst:AddComponent("ambientsound")
        inst:AddComponent("dsp")
        -- inst:AddComponent("colourcube")
        inst:AddComponent("hallucinations")
        inst:AddComponent("wavemanager")
        inst.Map:SetUndergroundFadeHeight(0)
        inst.Map:AlwaysDrawWaves(true)
        inst.Map:DoOceanRender(true)
    end
end

local function master_postinit(inst)
    -- Spawners
    inst:AddComponent("birdspawner")
    inst:AddComponent("butterflyspawner")

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
