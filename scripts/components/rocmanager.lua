--------------------------------------------------------------------------
--[[ RocManager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "RocManager should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local SPAWNDIST = 40
local ROC_TIMER_NAME = "ROC_RESPAWN_TIMER"

-- Public
self.inst = inst

-- Private
local _roc
local _world = TheWorld
local _worldsettingstimer = _world.components.worldsettingstimer
local _active_players = {}
local _enable = true

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerJoined(src, player)
    for _, v in ipairs(_active_players) do
        if v == player then
            return
        end
    end
    table.insert(_active_players, player)
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_active_players) do
        if v == player then
            table.remove(_active_players, i)
            return
        end
    end
end

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GetNextSpawnTime()
    return TUNING.TOTAL_DAY_TIME * 10 + math.random() * TUNING.TOTAL_DAY_TIME * 10
end

local function StopRespawnTimer()
    _worldsettingstimer:StopTimer(ROC_TIMER_NAME)
end

local function StartRespawnTimer(time)
    StopRespawnTimer()
    _worldsettingstimer:StartTimer(ROC_TIMER_NAME, time or GetNextSpawnTime(), false)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

---@return boolean spawned whether the roc actually spawned
function self:SpawnRoc()
    if _roc then
        return false
    end

    local players = {}
    for _, player in pairs(_active_players) do
        if not player:HasTag("inside_interior") then
            table.insert(players, player)
        end
    end

    local player = GetRandomItem(players)

    if not player then
        return false
    end

    self:SpawnRocToPlayer(player)

    return true
end


function self:SpawnRocToPlayer(player)
    if not _enable then
        return false
    end

    if TheWorld.state.isaporkalypse then
        return false
    end

    if _roc then
        return false
    end

    if not player or player:HasTag("inside_interior") then
        return false
    end

    local pt = player:GetPosition()
    local angle = math.random()* 2 * PI
    local offset = Vector3(math.cos(angle), 0, -math.sin(angle)) * SPAWNDIST

    local roc = SpawnPrefab("roc")
    roc.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
    roc.components.roccontroller.target_player = player

    _roc = roc
    return true
end

function self:Disable()
    _enable = false
end

function self:Enable()
    _enable = true
end

function self:RemoveRoc(roc)
    if roc == _roc then -- I don't get it, why bother checking if this is the roc spawned by this component? ds code is weird :/
        _roc = nil
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------
-- Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_active_players, v)
end

-- Register events
self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)

_worldsettingstimer:AddTimer(ROC_TIMER_NAME, GetNextSpawnTime(), TUNING.ROC_ENABLED, function()
    local spawned
    if TheWorld.state.time < 1/2 then -- will only spawn before the first half of daylight, and not wile player is indoors
        spawned = self:SpawnRoc()
    else
        spawned = false
    end

    if spawned then
        StartRespawnTimer() -- in ds it starts right after spawn, maybe we can move it to after roc leaves?
    else
        StartRespawnTimer(TUNING.SEG_TIME) -- try again later
    end
end)
StartRespawnTimer()

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local refs = {}
    local data = {}

    if _roc and _roc:IsValid() then
        data.roc = _roc.GUID
        table.insert(refs, _roc.GUID)
    end

    data.enable = _enable

    return data, refs
end

function self:OnLoad(data)
    if not data then
        return
    end

    if data.enable then
        _enable = data.enable
    end
end

function self:LoadPostPass(newents, savedata)
    if savedata.roc then
        local roc = newents[savedata.roc]
        if roc then
            _roc = roc.entity
        end
    end
end


function self:GetDebugString()
    local s = string.format("Spawns In: %2.2f", _worldsettingstimer:GetTimeLeft(ROC_TIMER_NAME) or -1)
    if _worldsettingstimer:IsPaused(ROC_TIMER_NAME) then
        s = s .. "(Paused)"
    end
    return s
end

end)
