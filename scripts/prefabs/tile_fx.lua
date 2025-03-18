local TEXTURE =  "levels/merged_tex/lilypond_merged.tex"
local SHADER = "shaders/tile_particle.ksh"

local COLOUR_ENVELOPE_NAME = "pl_tilecolourenvelope"
local SCALE_ENVELOPE_NAME = "pl_tilescaleenvelope"

local MAX_LIFETIME = 1e10

local assets =
{
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}

local INDEX_SIZE = 80.0; -- 可能的tile种类数量

local TileTexcoord = {}

TileTexcoord[1]  = {0.201171875, 0.736328125};
TileTexcoord[2]  = {0.068359375, 0.935546875};
TileTexcoord[3]  = {0.333984375, 0.736328125};
TileTexcoord[4]  = {0.400390625, 0.736328125};
TileTexcoord[5]  = {0.267578125, 0.935546875};
TileTexcoord[6]  = {0.333984375, 0.935546875};
TileTexcoord[7]  = {0.599609375, 0.736328125};
TileTexcoord[8]  = {0.666015625, 0.736328125};
TileTexcoord[9]  = {0.732421875, 0.736328125};
TileTexcoord[10] = {0.599609375, 0.935546875};
TileTexcoord[11] = {0.865234375, 0.736328125};
TileTexcoord[12] = {0.732421875, 0.935546875};
TileTexcoord[13] = {0.001953125, 0.669921875};
TileTexcoord[14] = {0.865234375, 0.935546875};
TileTexcoord[15] = {0.931640625, 0.935546875};
TileTexcoord[16] = {0.001953125, 0.869140625};
TileTexcoord[17] = {0.068359375, 0.869140625};
TileTexcoord[18] = {0.134765625, 0.869140625};
TileTexcoord[19] = {0.201171875, 0.869140625};
TileTexcoord[20] = {0.267578125, 0.869140625};
TileTexcoord[21] = {0.333984375, 0.869140625};
TileTexcoord[22] = {0.400390625, 0.869140625};
TileTexcoord[23] = {0.466796875, 0.869140625};
TileTexcoord[24] = {0.533203125, 0.869140625};
TileTexcoord[25] = {0.599609375, 0.869140625};
TileTexcoord[26] = {0.666015625, 0.869140625};
TileTexcoord[27] = {0.732421875, 0.869140625};
TileTexcoord[28] = {0.798828125, 0.869140625};
TileTexcoord[29] = {0.865234375, 0.869140625};
TileTexcoord[30] = {0.931640625, 0.869140625};
TileTexcoord[31] = {0.001953125, 0.802734375};
TileTexcoord[32] = {0.068359375, 0.802734375};
TileTexcoord[33] = {0.134765625, 0.802734375};
TileTexcoord[34] = {0.201171875, 0.802734375};
TileTexcoord[35] = {0.267578125, 0.802734375};
TileTexcoord[36] = {0.333984375, 0.802734375};
TileTexcoord[37] = {0.400390625, 0.802734375};
TileTexcoord[38] = {0.466796875, 0.802734375};
TileTexcoord[39] = {0.533203125, 0.802734375};
TileTexcoord[40] = {0.599609375, 0.802734375};
TileTexcoord[41] = {0.666015625, 0.802734375};
TileTexcoord[42] = {0.732421875, 0.802734375};
TileTexcoord[43] = {0.798828125, 0.802734375};
TileTexcoord[44] = {0.865234375, 0.802734375};
TileTexcoord[45] = {0.931640625, 0.802734375};
TileTexcoord[46] = {0.001953125, 0.736328125};
TileTexcoord[47] = {0.068359375, 0.736328125};
TileTexcoord[48] = {0.134765625, 0.736328125};
TileTexcoord[49] = {0.001953125, 0.935546875};
TileTexcoord[50] = {0.267578125, 0.736328125};
TileTexcoord[51] = {0.134765625, 0.935546875};
TileTexcoord[52] = {0.201171875, 0.935546875};
TileTexcoord[53] = {0.466796875, 0.736328125};
TileTexcoord[54] = {0.533203125, 0.736328125};
TileTexcoord[55] = {0.400390625, 0.935546875};
TileTexcoord[56] = {0.466796875, 0.935546875};
TileTexcoord[57] = {0.533203125, 0.935546875};
TileTexcoord[58] = {0.798828125, 0.736328125};
TileTexcoord[59] = {0.666015625, 0.935546875};
TileTexcoord[60] = {0.931640625, 0.736328125};
TileTexcoord[61] = {0.798828125, 0.935546875};
TileTexcoord[62] = {0.068359375, 0.669921875};
TileTexcoord[63] = {0.134765625, 0.669921875};
TileTexcoord[64] = {0.201171875, 0.669921875};
TileTexcoord[65] = {0, 0};
TileTexcoord[66] = {0, 0};
TileTexcoord[67] = {0, 0};
TileTexcoord[68] = {0, 0};
TileTexcoord[69] = {0, 0};
TileTexcoord[70] = {0, 0};
TileTexcoord[71] = {0, 0};
TileTexcoord[72] = {0, 0};
TileTexcoord[73] = {0, 0};
TileTexcoord[74] = {0, 0};
TileTexcoord[75] = {0, 0};
TileTexcoord[76] = {0, 0};
TileTexcoord[77] = {0, 0};
TileTexcoord[78] = {0, 0};
TileTexcoord[79] = {0, 0};
TileTexcoord[80] = {0, 0};

--------------------------------------------------------------------------

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    { 1, 1, 1, 1 } },
            { 1,    { 1, 1, 1, 1 } },
        }
    )

    local width, height = 1, 1
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


local function SpawnTile(inst, pos, tile_index)
    inst.Transform:SetPosition(pos.x, pos.y, pos.z)

    inst.VFXEffect:AddParticleUV(
        0,
        MAX_LIFETIME,           -- lifetime
        0, 0, 0,         -- position
        0, 0, 0,          -- velocity
        TileTexcoord[tile_index or 1][1], TileTexcoord[tile_index or 1][2]
    )
end

local function TestSpawn(inst)
    local pos = inst:GetPosition()
    for i = -6, 6, 1 do
        for j = -6, 6, 1 do
            inst:SpawnTile(pos + Vector3(i * 4, 0, j * 4))
        end
    end
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
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetMaxNumParticles(0, 10000)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetUVFrameSize(0, 0.0625, 0.0625)
    effect:SetLayer(0, LAYER_GROUND)
    effect:SetSortOrder(0, 1)
    effect:SetKillOnEntityDeath(0, true)
    effect:SetSpawnVectors(0,
        1, 0, 0,
        0, 0, 1
    )
    inst.SpawnTile = SpawnTile
    inst.TestSpawn = TestSpawn

    return inst
end


return Prefab("tile_fx", fn, assets)