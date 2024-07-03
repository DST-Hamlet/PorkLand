local WorldSoundManager = Class(function(self, inst) -- 此组件用于控制那些没有衰减的音效，使其只在限定的区域内播放
    self.inst = inst
    self.soundentities = {}
end)

--TheWorld.components.worldsoundmanager:PlayWorldSound("dontstarve_DLC003/music/dawn_stinger_1_temperate", "114514", nil, nil, ThePlayer:GetPosition(),nil,nil,1)

function WorldSoundManager:PlayWorldSound(path, soundname, paramname, paramval, pos, followentity, areamode, distance)
    local soundfx = SpawnPrefab("worldsound")

    soundfx.Transform:SetPosition(pos:Get())
    if followentity then
        soundfx.Transform:SetPosition(followentity:GetPosition():Get())
        soundfx.followentity = followentity
    end

    soundfx._soundpath:set(path or "")
    soundfx._sound:set(soundname or "")
    soundfx._param:set(paramname or "")
    soundfx._paramval:set(paramval or 0)
    soundfx._areamode:set(areamode or 0)
    soundfx._distance:set(distance or 10)

    if soundname ~= nil then
        if self.soundentities[followentity.GUID] == nil then
            self.soundentities[followentity.GUID] = {}
        end
        if self.soundentities[followentity.GUID][soundname] == nil then
            self.soundentities[followentity.GUID][soundname] = {}
        end
        table.insert(self.soundentities[followentity.GUID][soundname], soundfx)
    end
end

function WorldSoundManager:KillWorldSound(followentity, soundname)
    if self.soundentities[followentity.GUID] ~= nil then
        if self.soundentities[followentity.GUID][soundname] ~= nil then
            for i, v in ipairs(self.soundentities[followentity.GUID][soundname]) do
                table.remove(self.soundentities[followentity.GUID][soundname], i)
                v:Remove()
            end
        end
    end
end

return WorldSoundManager
