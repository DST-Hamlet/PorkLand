--------------------------------------------------------------------------
--[[ Waterfall Sound Controller class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local EMITTER_MAXDSQ = 2500

local NUM_EMITTERS = 8

local WATERFALL_LOOP_SOUNDNAME = "porkland_soundpackage/common/waterfall/waterfall"
local SOUND_EVENT_NAME = "waterfall"

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _player = ThePlayer
local _process_task = nil
local _waterfalls = {}
local _soundemitters = {}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function waterfall_sortfn(waterfall1, waterfall2)
    return waterfall1[2] < waterfall2[2]
end

local function get_waterfalls_close_to_player_dsqsorted()
    local px, py, pz = _player.Transform:GetWorldPosition()

    local waterfalls_with_dist = {}
    for waterfall, _ in pairs(_waterfalls) do
        local dsq_to_waterfall = waterfall:GetDistanceSqToPoint(px, py, pz) - 0
        if dsq_to_waterfall < 2500 then
            table.insert(waterfalls_with_dist, {waterfall, dsq_to_waterfall, true})
        end
    end

    table.sort(waterfalls_with_dist, waterfall_sortfn)

    return waterfalls_with_dist
end

local function ProcessPlayer()
    if _player == nil or not _player:IsValid() then
        _player = ThePlayer
    end
    if _player == nil or not _player:IsValid() then
        return
    end

    local waterfalls_with_distances = get_waterfalls_close_to_player_dsqsorted()

    local reuse_emitters = {}

    for k, emitter in pairs(_soundemitters) do -- 寻找那些排序靠后的音效源
        local is_closet = false
        if emitter.target_waterfall ~= nil then
            for i = 1, NUM_EMITTERS do
                if waterfalls_with_distances[i] and waterfalls_with_distances[i][1] == emitter.target_waterfall then
                    is_closet = true
                end
            end
        else
            is_closet = false
        end

        if not is_closet then
            table.insert(reuse_emitters, emitter)
        end
    end

    for i = 1, NUM_EMITTERS do
        if waterfalls_with_distances[i] then
            local hasemitter = false
            for k, emitter in pairs(_soundemitters) do
                if waterfalls_with_distances[i][1] == emitter.target_waterfall then
                    hasemitter = true
                end
            end
            if not hasemitter and reuse_emitters[1] then
                reuse_emitters[1].target_waterfall = waterfalls_with_distances[i][1]
                table.remove(reuse_emitters, 1)
            end
        end
    end
end

local function StopTrackingWaterfall(waterfall)
    self.inst:RemoveEventCallback("onremove", StopTrackingWaterfall, waterfall)

    if _waterfalls[waterfall] ~= nil then
        _waterfalls[waterfall] = nil
    end
end

local function TrackWaterfall(inst, data)
    local waterfall = data.waterfall
    if waterfall ~= nil then
        if not _waterfalls[waterfall] then
            _waterfalls[waterfall] = true
        end

        self.inst:ListenForEvent("onremove", StopTrackingWaterfall, waterfall)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("ms_registerwaterfall", TrackWaterfall)

--Initialize
local init_task = inst:DoTaskInTime(0, function(i)
    for _ = 1, NUM_EMITTERS do
        table.insert(_soundemitters, SpawnPrefab("waterfall_sfx"))
    end
end)
_process_task = inst:DoPeriodicTask(5*FRAMES, ProcessPlayer)

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local num_waterfalls = GetTableSize(_waterfalls)

    local emitters_playing = 0
    for _, emitter in ipairs(_soundemitters) do
        if emitter.SoundEmitter:PlayingSound(SOUND_EVENT_NAME) then
            emitters_playing = emitters_playing + 1
        end
    end

    return string.format("Large Waterfall Count: %d || Emitters Playing: %d",
        num_waterfalls, emitters_playing)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
