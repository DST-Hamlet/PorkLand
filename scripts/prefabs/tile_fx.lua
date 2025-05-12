local SHADER = "shaders/tile_particle.ksh"

-- ShaderCompiler.exe -little “tile_particle” “tile_particle.vs” “tile_particle.ps” “tile_particle.ksh” -oglsl

local COLOUR_ENVELOPE_NAME = "pl_tilecolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_tilescaleenvelope"

local MAX_LIFETIME = 1e10

local assets =
{
    Asset("IMAGE", "levels/merged_tex/lilypond_merged.tex"),
    Asset("SHADER", SHADER),
}

-- local OVERHANG_SIZE = 80.0 -- 可能的 tile 种类数量

local TileTexcoord = {
    [1]  = {0.201171875, 0.736328125},
    [2]  = {0.068359375, 0.935546875},
    [3]  = {0.333984375, 0.736328125},
    [4]  = {0.400390625, 0.736328125},
    [5]  = {0.267578125, 0.935546875},
    [6]  = {0.333984375, 0.935546875},
    [7]  = {0.599609375, 0.736328125},
    [8]  = {0.666015625, 0.736328125},
    [9]  = {0.732421875, 0.736328125},
    [10] = {0.599609375, 0.935546875},
    [11] = {0.865234375, 0.736328125},
    [12] = {0.732421875, 0.935546875},
    [13] = {0.001953125, 0.669921875},
    [14] = {0.865234375, 0.935546875},
    [15] = {0.931640625, 0.935546875},
    [16] = {0.001953125, 0.869140625},
    [17] = {0.068359375, 0.869140625},
    [18] = {0.134765625, 0.869140625},
    [19] = {0.201171875, 0.869140625},
    [20] = {0.267578125, 0.869140625},
    [21] = {0.333984375, 0.869140625},
    [22] = {0.400390625, 0.869140625},
    [23] = {0.466796875, 0.869140625},
    [24] = {0.533203125, 0.869140625},
    [25] = {0.599609375, 0.869140625},
    [26] = {0.666015625, 0.869140625},
    [27] = {0.732421875, 0.869140625},
    [28] = {0.798828125, 0.869140625},
    [29] = {0.865234375, 0.869140625},
    [30] = {0.931640625, 0.869140625},
    [31] = {0.001953125, 0.802734375},
    [32] = {0.068359375, 0.802734375},
    [33] = {0.134765625, 0.802734375},
    [34] = {0.201171875, 0.802734375},
    [35] = {0.267578125, 0.802734375},
    [36] = {0.333984375, 0.802734375},
    [37] = {0.400390625, 0.802734375},
    [38] = {0.466796875, 0.802734375},
    [39] = {0.533203125, 0.802734375},
    [40] = {0.599609375, 0.802734375},
    [41] = {0.666015625, 0.802734375},
    [42] = {0.732421875, 0.802734375},
    [43] = {0.798828125, 0.802734375},
    [44] = {0.865234375, 0.802734375},
    [45] = {0.931640625, 0.802734375},
    [46] = {0.001953125, 0.736328125},
    [47] = {0.068359375, 0.736328125},
    [48] = {0.134765625, 0.736328125},
    [49] = {0.001953125, 0.935546875},
    [50] = {0.267578125, 0.736328125},
    [51] = {0.134765625, 0.935546875},
    [52] = {0.201171875, 0.935546875},
    [53] = {0.466796875, 0.736328125},
    [54] = {0.533203125, 0.736328125},
    [55] = {0.400390625, 0.935546875},
    [56] = {0.466796875, 0.935546875},
    [57] = {0.533203125, 0.935546875},
    [58] = {0.798828125, 0.736328125},
    [59] = {0.666015625, 0.935546875},
    [60] = {0.931640625, 0.736328125},
    [61] = {0.798828125, 0.935546875},
    [62] = {0.068359375, 0.669921875},
    [63] = {0.134765625, 0.669921875},
    [64] = {0.201171875, 0.669921875},
    [65] = {0, 0},
    [66] = {0, 0},
    [67] = {0, 0},
    [68] = {0, 0},
    [69] = {0, 0},
    [70] = {0, 0},
    [71] = {0, 0},
    [72] = {0, 0},
    [73] = {0, 0},
    [74] = {0, 0},
    [75] = {0, 0},
    [76] = {0, 0},
    [77] = {0, 0},
    [78] = {0, 0},
    [79] = {0, 0},
    [80] = {0, 0},
}

--------------------------------------------------------------------------

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    { 1, 1, 1, 1 } },
            { 1,    { 1, 1, 1, 1 } },
        }
    )

    local width, height = 1.171875 * 4, 1.171875 * 4
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { width, height } },
            { 1,    { width, height } },
        }
    )

    InitEnvelope = nil
end

--------------------------------------------------------------------------


local function SpawnTile(inst, pos, overhang_type, index)
    inst.Transform:SetPosition(pos.x, pos.y, pos.z)

    inst.VFXEffect:AddParticleUV(
        index,
        MAX_LIFETIME,           -- lifetime
        0, 0, 0,         -- position
        0, 0, 0,          -- velocity
        TileTexcoord[overhang_type or 1][1], TileTexcoord[overhang_type or 1][2]
    )
end

local function ClearTile(inst, index)
    inst.VFXEffect:ClearAllParticles(index)
end

local function TestSpawn(inst)
    local pos = inst:GetPosition()
    for i = -6, 6, 1 do
        for j = -6, 6, 1 do
            inst:SpawnTile(pos + Vector3(i * 4, 0, j * 4), 0)
        end
    end
end

local tile_fx_datas = {}

function SpawnTileFxEntity(tile_datas)
    tile_fx_datas = tile_datas
    local tile_fx = SpawnPrefab("tile_fx")
    tile_fx_datas = {}
    return tile_fx
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(GetTableSize(tile_fx_datas))
    for name, data in pairs(tile_fx_datas) do
        local i = data.id
        effect:SetRenderResources(i, resolvefilepath(data.texture), resolvefilepath(SHADER))
        effect:SetMaxNumParticles(i, 10000)
        effect:SetMaxLifetime(i, MAX_LIFETIME)
        effect:SetColourEnvelope(i, COLOUR_ENVELOPE_NAME)
        effect:SetScaleEnvelope(i, SCALE_ENVELOPE_NAME)
        effect:SetUVFrameSize(i, 0.0625, 0.0625)
        effect:SetLayer(i, LAYER_BACKGROUND)
        effect:SetSortOrder(i, -3)
        effect:SetKillOnEntityDeath(i, true)
        effect:SetSpawnVectors(i,
            1, 0, 0,
            0, 0, 1
        )
    end

    inst.SpawnTile = SpawnTile
    inst.ClearTile = ClearTile
    inst.TestSpawn = TestSpawn

    return inst
end

return Prefab("tile_fx", fn, assets)
