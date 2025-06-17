local TheMixer = GLOBAL.TheMixer

local amb = "set_ambience/ambience"
local cloud = "set_ambience/cloud"
local music = "set_music/soundtrack"
local voice = "set_sfx/voice"
local movement ="set_sfx/movement"
local creature ="set_sfx/creature"
local player ="set_sfx/player"
local HUD ="set_sfx/HUD"
local sfx ="set_sfx/sfx"
local slurp ="set_sfx/everything_else_muted"
local mute ="set_sfx/everything_else_muted"
local shadow ="set_sfx/shadow"

--function Mixer:AddNewMix(name, fadetime, priority, levels, reverb)
TheMixer:AddNewMix("mute", 0, 4,
{
    [amb] = .1,
    [cloud] = .1,
    [music] = 0,
    [voice] = 0,
    [movement] = 0,
    [creature] = 0,
    [player] = 0,
    [HUD] = 1,
    [sfx] = 0,
    [slurp] = 0,
    [mute] = 1,
    [shadow] = 0,
})

TheMixer:AddNewMix("shadow", 1, 3,
{
    [amb] = .2,
    [cloud] = 0,
    [music] = 1,
    [voice] = 1,
    [movement] = 1,
    [creature] = 1,
    [player] = 1,
    [HUD] = 1,
    [sfx] = 1,
    [slurp] = 1,
    [shadow] = .3,
})

TheMixer:AddNewMix("boom", 0, 4,
{
    [amb] = .1,
    [cloud] = .1,
    [music] = .5,
    [voice] = 0,
    [movement] = 0,
    [creature] = 1,
    [player] = 0,
    [HUD] = 1,
    [sfx] = 1,
    [slurp] = 0,
    [shadow] = 0,
})