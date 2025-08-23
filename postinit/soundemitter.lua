GLOBAL.setfenv(1, GLOBAL)

local SoundEmitter = SoundEmitter

local soundemitters = {}

local _PlaySound = SoundEmitter.PlaySound
function SoundEmitter:PlaySound(soundname, ...)
    _PlaySound(self ,soundemitters[self] and soundemitters[self][soundname] or soundname, ...)
end

local _PlaySoundWithParams = SoundEmitter.PlaySoundWithParams
function SoundEmitter:PlaySoundWithParams(soundname, ...)
    _PlaySoundWithParams(self ,soundemitters[self] and soundemitters[self][soundname] or soundname, ...)
end

function SoundEmitter:OverrideSound(oldsound, override)
    if soundemitters[self] == nil then
        soundemitters[self] = {}
    end
    soundemitters[self][oldsound] = override
end

function SoundEmitter:CleanOverrideSound()
    soundemitters[self] = nil
end
