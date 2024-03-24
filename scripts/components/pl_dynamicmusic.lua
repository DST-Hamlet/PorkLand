--------------------------------------------------------------------------
--[[ DynamicMusic class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SEASON_BUSY_MUSIC =
{
    temperate = "dontstarve_DLC003/music/working_1",
    humid = "dontstarve_DLC003/music/working_2",
    lush = "dontstarve_DLC003/music/working_3",
    aporkalypse = "dontstarve/music/music_work", -- Aporkalypse has no working because it's night only
}

local SEASON_EPICFIGHT_MUSIC =
{
    temperate = "dontstarve_DLC003/music/fight_epic_1",
    humid = "dontstarve_DLC003/music/fight_epic_1",
    lush = "dontstarve_DLC003/music/fight_epic_1",
    aporkalypse = "dontstarve_DLC003/music/fight_4",
}

local SEASON_DANGER_MUSIC =
{
    temperate = "dontstarve_DLC003/music/fight_1",
    humid = "dontstarve_DLC003/music/fight_2",
    lush = "dontstarve_DLC003/music/fight_3",
    aporkalypse = "dontstarve_DLC003/music/fight_4",
}

local SEASON_DAWN_STINGERS =
{
    temperate = "dontstarve_DLC003/music/dawn_stinger_1_temperate",
    humid = "dontstarve_DLC003/music/dawn_stinger_2_humid",
    lush = "dontstarve_DLC003/music/dawn_stinger_3_lush",
    aporkalypse = "dontstarve/music/music_dawn_stinger", -- same reason as busy
}

local SEASON_DUSK_STINGERS =
{
    temperate = "dontstarve_DLC003/music/dusk_stinger_1_temperate",
    humid = "dontstarve_DLC003/music/dusk_stinger_2_humid",
    lush = "dontstarve_DLC003/music/dusk_stinger_3_lush",
    aporkalypse = "dontstarve/music/music_dusk_stinger", -- same reason as busy
}

local TRIGGERED_DANGER_MUSIC =
{
    ancient_herald =
    {
        "dontstarve_DLC003/music/fight_epic_3",
    },

    ancient_hulk =
    {
        "dontstarve_DLC003/music/fight_epic_4",
    },

    pugalisk =
    {
        "dontstarve_DLC003/music/fight_epic_2"
    },

    default =
    {
        "dontstarve_DLC003/music/fight_epic_1",
    },
}

-- These numers do not matter as long as they are unique
local BUSYTHEMES = {
    PORKLAND = 1,
    JUNGLE = 2,
    PIGRUINS = 3,
    RIDEOFTHEVALKYRIE = 20,
}

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _isenabled = true
local _busytask = nil
local _dangertask = nil
local _triggeredlevel = nil
local _isday = nil
local _busytheme = nil
local _extendtime = nil
local _soundemitter = nil
local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use
local _hasinspirationbuff = nil
local _tone = nil
local _tone_task = nil

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function StopBusy(inst, istimeout)
    if _busytask ~= nil then
        if not istimeout then
            _busytask:Cancel()
        elseif _extendtime > 0 then
            local time = GetTime()
            if time < _extendtime then
                _busytask = inst:DoTaskInTime(_extendtime - time, StopBusy, true)
                _extendtime = 0
                return
            end
        end
        _busytask = nil
        _extendtime = 0
        _soundemitter:SetParameter("busy", "intensity", 0)
    end
end

local function StartBusy(player)
    if not _isday then
        return
    elseif _busytask ~= nil then
        _extendtime = GetTime() + 15
    elseif _dangertask == nil and (_extendtime == 0 or GetTime() >= _extendtime) and _isenabled then
        if _busytheme ~= BUSYTHEMES.PORKLAND then
            _soundemitter:KillSound("busy")
            _soundemitter:PlaySound(SEASON_BUSY_MUSIC[inst.state.season], "busy")
        end
        _busytheme = BUSYTHEMES.PORKLAND

        _soundemitter:SetParameter("busy", "intensity", 1)
        _busytask = inst:DoTaskInTime(15, StopBusy, true)
        _extendtime = 0
    end
end

local function StartBusyTheme(player, theme, sound, duration, extendtime)
    if _dangertask == nil and _tone_task == nil and (_busytheme ~= theme or _extendtime == 0 or GetTime() >= _extendtime) and _isenabled then
        if _busytask then
            _busytask:Cancel()
            _busytask = nil
        end
        if _busytheme ~= theme then
            _soundemitter:KillSound("busy")
            _soundemitter:PlaySound(sound, "busy")
            _busytheme = theme
        end

        _soundemitter:SetParameter("busy", "intensity", 1)
        _busytask = inst:DoTaskInTime(duration, StopBusy, true)
        _extendtime = extendtime or 0
    end
end

local function StartRideoftheValkyrieMusic(player)
    if _dangertask then
        return
    end

    StartBusyTheme(player, BUSYTHEMES.RIDEOFTHEVALKYRIE, "dontstarve/music/music_wigfrid_valkyrie", 2)
end

local function ExtendBusy()
    if _busytask ~= nil then
        _extendtime = math.max(_extendtime, GetTime() + 10)
    end
end

local function StopDanger(inst, istimeout)
    if _dangertask ~= nil then
        if not istimeout then
            _dangertask:Cancel()
        elseif _extendtime > 0 then
            local time = GetTime()
            if time < _extendtime then
                _dangertask = inst:DoTaskInTime(_extendtime - time, StopDanger, true)
                _extendtime = 0
                return
            end
        end
        _dangertask = nil
        _triggeredlevel = nil
        _extendtime = 0
        _soundemitter:KillSound("danger")
    end
end

local EPIC_TAGS = { "epic" }
local NO_EPIC_TAGS = { "noepicmusic" }
local function StartDanger(player)
    if _dangertask ~= nil then
        _extendtime = GetTime() + 10
    elseif _isenabled then
        local x, y, z = player.Transform:GetWorldPosition()
        local epics = TheSim:FindEntities(x, y, z, 30, EPIC_TAGS, NO_EPIC_TAGS)
        StopBusy()
        _soundemitter:PlaySound(#epics > 0 and SEASON_EPICFIGHT_MUSIC[inst.state.season] or SEASON_DANGER_MUSIC[inst.state.season], "danger")
        _dangertask = inst:DoTaskInTime(10, StopDanger, true)
        _triggeredlevel = nil
        _extendtime = 0

        if _hasinspirationbuff then
            _soundemitter:SetParameter("danger", "wathgrithr_intensity", _hasinspirationbuff)
        end
    end
end

local function StartTriggeredDanger(player, data)
    local level = math.max(1, math.floor(data ~= nil and data.level or 1))
    if _triggeredlevel == level then
        _extendtime = math.max(_extendtime, GetTime() + (data.duration or 10))
    elseif _isenabled then
        StopBusy()
        StopDanger()

        local music = data ~= nil and TRIGGERED_DANGER_MUSIC[data.name or "default"] or TRIGGERED_DANGER_MUSIC.default
        music = music[level] or music[1]
        if #music > 0 then
            _soundemitter:PlaySound(music, "danger")
            if _hasinspirationbuff then
                _soundemitter:SetParameter("danger", "wathgrithr_intensity", _hasinspirationbuff)
            end
        end

        _dangertask = inst:DoTaskInTime(data.duration or 10, StopDanger, true)
        _triggeredlevel = level
        _extendtime = 0
    end
end

local function CheckAction(player)
    if player:HasTag("attack") then
        local target = player.replica.combat:GetTarget()
        if target ~= nil and
            target:HasTag("_combat") and
            not ((target:HasTag("prey") and not target:HasTag("hostile")) or
                target:HasTag("bird") or
                target:HasTag("butterfly") or
                target:HasTag("shadow") or
                target:HasTag("shadowchesspiece") or
                target:HasTag("noepicmusic") or
                target:HasTag("thorny") or
                target:HasTag("smashable") or
                target:HasTag("wall") or
                target:HasTag("engineering") or
                target:HasTag("smoldering") or
                target:HasTag("veggie")) then
            if target:HasTag("shadowminion") or target:HasTag("abigail") then
                local follower = target.replica.follower
                if not (follower ~= nil and follower:GetLeader() == player) then
                    StartDanger(player)
                    return
                end
            else
                StartDanger(player)
                return
            end
        end
    end
    if player:HasTag("working") then
        StartBusy(player)
    end
end

local function OnAttacked(player, data)
    if data ~= nil and
        --For a valid client side check, shadowattacker must be
        --false and not nil, pushed from player_classified
        (data.isattackedbydanger == true or
        --For a valid server side check, attacker must be non-nil
        (data.attacker ~= nil and
        not (data.attacker:HasTag("shadow") or
            data.attacker:HasTag("shadowchesspiece") or
            data.attacker:HasTag("noepicmusic") or
            data.attacker:HasTag("thorny") or
            data.attacker:HasTag("smolder")))) then

        StartDanger(player)
    end
end

local function OnHasInspirationBuff(player, data)
    _hasinspirationbuff = (data ~= nil and data.on) and 1 or 0
    _soundemitter:SetParameter("danger", "wathgrithr_intensity", _hasinspirationbuff)
end

local function OnInsane()
    if _dangertask == nil and _isenabled and (_extendtime == 0 or GetTime() >= _extendtime) then
        _soundemitter:PlaySound("dontstarve/sanity/gonecrazy_stinger")
        StopBusy()
        --Repurpose this as a delay before stingers or busy can start again
        _extendtime = GetTime() + 15
    end
end

-- Porkland

local function ResumeTone()
    _soundemitter:SetParameter("tone", "intensity", 1)
end

local function StopPlayingTone(category)
    if not category or _tone == category then
        _tone = nil
        _soundemitter:KillSound("tone")
    end
end

local function SetTone(category)
    if not _isenabled then
        return
    end

    local CATEGORIES = {
        ruins = {path ="dontstarve_DLC003/music/ruins_enter", timeout = 75},
        ruins_humid = {path ="dontstarve_DLC003/music/ruins_enter_2", timeout = 75},
        ruins_lush = {path ="dontstarve_DLC003/music/ruins_enter_3", timeout = 75},
        jungle = {path ="dontstarve_DLC003/music/deeprainforest_enter_1", timeout = 75},
        jungle_humid = {path ="dontstarve_DLC003/music/deeprainforest_enter_2", timeout = 75},
        jungle_lush = {path ="dontstarve_DLC003/music/deeprainforest_enter_3", timeout = 75},
    }
    local tone = CATEGORIES[category]
    if not tone then
        return
    end

    if _soundemitter:PlayingSound("tone") and _tone ~= category then
        StopPlayingTone()
    end
    _soundemitter:PlaySound(tone.path, "tone")
    _soundemitter:SetParameter("tone", "intensity", 1)
    _tone = category
    _tone_task = inst:DoTaskInTime(tone.timeout, StopPlayingTone)

    if not _soundemitter:PlayingSound("danger") then
        StopBusy()
        ResumeTone()
    end
end

local function StartPigRuinsTone(player)
    if _dangertask then
        return
    end

    local tones = {humid = "_humid", lush = "_lush"}
    SetTone("ruins" .. (tones[TheWorld.state.season] or ""))
end

local function StartJungleTone(player)
    if _dangertask then
        return
    end

    local tones = {humid = "_humid", lush = "_lush"}
    SetTone("jungle" .. (tones[TheWorld.state.season] or ""))
end

local function StartPlayerListeners(player)
    inst:ListenForEvent("buildsuccess", StartBusy, player)
    inst:ListenForEvent("gotnewitem", ExtendBusy, player)
    inst:ListenForEvent("performaction", CheckAction, player)
    inst:ListenForEvent("attacked", OnAttacked, player)
    inst:ListenForEvent("goinsane", OnInsane, player)
    inst:ListenForEvent("triggeredevent", StartTriggeredDanger, player)
    inst:ListenForEvent("hasinspirationbuff", OnHasInspirationBuff, player)
    inst:ListenForEvent("playrideofthevalkyrie", StartRideoftheValkyrieMusic, player)

    inst:ListenForEvent("canopyin", StartJungleTone, player)
    inst:ListenForEvent("canopyout", function() StopPlayingTone("jungle") end, player)
    inst:ListenForEvent("enteredruins", StartPigRuinsTone, player)
    inst:ListenForEvent("exitedruins", function() StopPlayingTone("ruins") end, player)
end

local function StopPlayerListeners(player)
    inst:RemoveEventCallback("buildsuccess", StartBusy, player)
    inst:RemoveEventCallback("gotnewitem", ExtendBusy, player)
    inst:RemoveEventCallback("performaction", CheckAction, player)
    inst:RemoveEventCallback("attacked", OnAttacked, player)
    inst:RemoveEventCallback("goinsane", OnInsane, player)
    inst:RemoveEventCallback("triggeredevent", StartTriggeredDanger, player)
    inst:RemoveEventCallback("hasinspirationbuff", OnHasInspirationBuff, player)
    inst:RemoveEventCallback("playrideofthevalkyrie", StartRideoftheValkyrieMusic, player)

    inst:RemoveEventCallback("canopyin", StartJungleTone, player)
    inst:RemoveEventCallback("canopyout", function() StopPlayingTone("jungle") end, player)
    inst:RemoveEventCallback("enteredruins", StartPigRuinsTone, player)
    inst:RemoveEventCallback("exitedruins", function() StopPlayingTone("ruins") end, player)
end

local function OnPhase(inst, phase)
    _isday = phase == "day"
    if _dangertask ~= nil or not _isenabled then
        return
    end
    --Don't want to play overlapping stingers
    local time
    if _busytask == nil and _extendtime ~= 0 then
        time = GetTime()
        if time < _extendtime then
            return
        end
    end
    if _isday then
        _soundemitter:PlaySound(SEASON_DAWN_STINGERS[TheWorld.state.season] or "dontstarve/music/music_dawn_stinger")
    elseif phase == "dusk" then
        _soundemitter:PlaySound(SEASON_DUSK_STINGERS[TheWorld.state.season] or "dontstarve/music/music_dusk_stinger")
    else
        return
    end
    StopBusy()
    --Repurpose this as a delay before stingers or busy can start again
    _extendtime = (time or GetTime()) + 15
end

local function OnSeason()
    _busytheme = nil
end

local function StartSoundEmitter()
    if _soundemitter == nil then
        _soundemitter = TheFocalPoint.SoundEmitter
        _extendtime = 0
        _isday = inst.state.isday
        inst:WatchWorldState("phase", OnPhase)
        inst:WatchWorldState("season", OnSeason)
    end
end

local function StopSoundEmitter()
    if _soundemitter ~= nil then
        StopDanger()
        StopBusy()
        _soundemitter:KillSound("busy")
        inst:StopWatchingWorldState("phase", OnPhase)
        inst:StopWatchingWorldState("season", OnSeason)
        _isday = nil
        _busytheme = nil
        _extendtime = nil
        _soundemitter = nil
        _hasinspirationbuff = nil
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerActivated(inst, player)
    if _activatedplayer == player then
        return
    elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
        StopPlayerListeners(_activatedplayer)
    end
    _activatedplayer = player
    StopSoundEmitter()
    StartSoundEmitter()
    StartPlayerListeners(player)
end

local function OnPlayerDeactivated(inst, player)
    StopPlayerListeners(player)
    if player == _activatedplayer then
        _activatedplayer = nil
        StopSoundEmitter()
    end
end

local function OnEnableDynamicMusic(inst, enable)
    if _isenabled ~= enable then
        if not enable and _soundemitter ~= nil then
            StopDanger()
            StopBusy()
            _soundemitter:KillSound("busy")
        end
        _isenabled = enable
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("playeractivated", OnPlayerActivated)
inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
inst:ListenForEvent("enabledynamicmusic", OnEnableDynamicMusic)

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)