--------------------------------------------------------------------------
--[[ Banditmanager class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Banditmanager should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local TREASURE_LIST = {
    {
        weight = 5,
        loot = {
            tunacan = 4,
            oinc10 = 1,
            meat_dried = 2,
        },
    },

    {
        weight = 3,
        loot = {
            goldnugget = 4,
            alloy = 1,
            meat_dried = 2,
            oinc = 5,
        },
    },

    {
        weight = 3,
        loot = {
            trinket_18 = 1, -- trinket_17 = 1,
            oinc = 5,
            sewing_kit = 1,
            -- telescope = 1,
            meat_dried = 1,
        },
    },

    {
        weight = 2,
        loot = {
            meat_dried = 2,
            oinc = 15,
            drumstick = 2,
            oinc10 = 1,
        },
    },

    {
        weight = 2,
        loot = {
            armor_metalplate = 1,
            halberd = 1,
            metalplatehat = 1,
            oinc = 15,
        },
    },

    {
        weight = 1,
        loot = {
            drumstick = 2,
            oinc = 15,
            oinc10 = 2,
            tunacan = 1,
            monstermeat = 1,
        },
    },
}

local CITY1_TAG = "City1"
local CITY2_TAG = "City2"
local BANDIT_TIMER_NAME = "pig_bandit_respawn_time_" -- one bandit for each city... one day

-- Public
self.inst = inst

-- Private
local _world = TheWorld
local _map = _world.Map
local _worldsettingstimer = _world.components.worldsettingstimer

local _active_players = {}
local _bandit
local _stored_bandit
local _stolen_oincs = {oinc = 0, oinc10 = 0, oinc100 = 0}

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function StartRespawnTimer(time)
    _worldsettingstimer:StopTimer(BANDIT_TIMER_NAME)
    _worldsettingstimer:StartTimer(BANDIT_TIMER_NAME, time or TUNING.PIG_BANDIT_RESPAWN_TIME, false)
end

local function OnBanditDeath(src, data)
    StartRespawnTimer(TUNING.PIG_BANDIT_DEATH_RESPAWN_TIME)
    _bandit = nil
end

local function OnBanditEscaped(src, data)
    local oincs = _bandit.components.inventory:GetItemsWithTag("oinc")
    for _, oinc in pairs(oincs) do
        if _stolen_oincs[oinc.prefab] then
            _stolen_oincs[oinc.prefab] = _stolen_oincs[oinc.prefab] + oinc.components.stackable:StackSize()
        end
    end
    for _, oinc in pairs(oincs) do
        _bandit.components.inventory:RemoveItem(oinc)
        oinc:Remove()
    end

    _bandit.components.health:SetPercent(1)
    _bandit.attacked = nil
    _stored_bandit = _bandit:GetSaveRecord()
    _bandit:Remove()
    _bandit = nil

    StartRespawnTimer()
end

local function OnBanditTreasureDug(src, data)
    _stolen_oincs.oinc = 0
    _stolen_oincs.oinc10 = 0
    _stolen_oincs.oinc100 = 0
end

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

local function IsPlayerInCity(player)
    local x, y, z = player.Transform:GetWorldPosition()
    local node_index = _map:GetNodeIdAtPoint(x, y, z)
    local node = _world.topology.nodes[node_index]
    if node == nil or node.tags == nil then
        return false
    end

    for _, tag in pairs(node.tags) do
        if tag == CITY1_TAG or tag == CITY2_TAG then
            return true
        end
    end
    return false
end

local function TrySpawnBanit()
    if self:GetIsBanditActive() then
        return
    end

    local choices = {}
    for _, player in pairs(_active_players) do
        if not IsEntityDeadOrGhost(player) and IsPlayerInCity(player) then
            choices[#choices+1] = player
        end
    end
    local player = GetRandomItem(choices)

    if not player then
        return
    end

    local value = 0

    local oincs = player.components.inventory:GetItemsWithTag("oinc")
    for _, oinc in pairs(oincs) do
        value = value + oinc.oincvalue * oinc.components.stackable:StackSize()
    end

    if _world.state.isdusk then
        value = value * 1.5
    end
    if _world.state.isnight then
        value = value * 3
    end

    local chance = 1/100
    if value >= 150 then
        chance = 1/5
    elseif value >= 100 then
        chance = 1/10
    elseif value >= 50 then
        chance = 1/20
    elseif value >= 10 then
        chance = 1/40
    elseif value == 0 then
        chance = 0
    end

    local roll = math.random()
    if roll < chance then
        self:SpawnBanditOnPlayer(player)
    end
end

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GenerateTreasure(player)
    local pos = player:GetPosition()
    local angle = math.random() * 2 * PI
    local radius = math.random(120, 200)
    local offset = FindWalkableOffset(pos, angle, radius, 18, nil, nil, function(spawn_pos)
        local current_island = _map:GetIslandTagAtPoint(pos.x, 0, pos.z)
        local target_island = _map:GetIslandTagAtPoint(spawn_pos.x, 0, spawn_pos.z)
        local isposclear = _map:IsDeployPointClear(spawn_pos, nil, DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT])
        return isposclear and (current_island == target_island)
    end)

    if offset then
        local spawn_pos = pos + offset

        local bandit_unique_id = _bandit.components.uniqueidentity:GetID()

        local treasure = SpawnPrefab("bandittreasure")
        treasure.Transform:SetPosition(spawn_pos:Get())
        treasure.unique_id = bandit_unique_id

        local map = SpawnPrefab("banditmap")
        map.treasure = treasure
        map.unique_id = bandit_unique_id

        _bandit.components.inventory:ConsumeByName("banditmap", 15) -- delete previous map
        _bandit.components.inventory:GiveItem(map)
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnBanditOnPlayer(player)
    local x, y, z = player.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 40, {"bandit_cover"})

    local cover = GetRandomItem(ents)

    if cover then
        if _stored_bandit then
            _bandit = SpawnSaveRecord(_stored_bandit)
            _stored_bandit = nil
        else
            _bandit = SpawnPrefab("pigbandit")
        end
        GenerateTreasure(player)

        local cx, _, cz = cover.Transform:GetWorldPosition()
        local angle = TheCamera:GetHeadingTarget() * DEGREES
        cx = cx - 1 * math.cos(angle)
        cz = cz - 1 * math.sin(angle)

        _bandit.Transform:SetPosition(cx, 0, cz)
    end
end

function self:GetLoot()
    local temploot = {}

    local range = 0

    for i, set in ipairs(TREASURE_LIST) do
        range = range + set.weight
    end

    local final = math.random(1,range)
    range = 0
    for i, set in ipairs(TREASURE_LIST) do
        range = range + set.weight
        if range >= final then
            for p,n in pairs(set.loot) do
                if not temploot[p] then
                    temploot[p] = n
                else
                    temploot[p] = temploot[p] +n
                end
            end
            break
        end
    end

    for oinc_prefab, amount_stolen in pairs(_stolen_oincs) do
        if not temploot[oinc_prefab] then
            temploot[oinc_prefab] = amount_stolen
        else
            temploot[oinc_prefab] = temploot[oinc_prefab] + amount_stolen
        end
    end

    return temploot
end

function self:GetIsBanditActive()
    if _bandit and _bandit:IsValid() then
        return true
    else
        _bandit = nil
        return false
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
self.inst:ListenForEvent("bandit_death", OnBanditDeath)
self.inst:ListenForEvent("bandit_escaped", OnBanditEscaped)
self.inst:ListenForEvent("bandittreasure_dug", OnBanditTreasureDug)
self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)

_worldsettingstimer:AddTimer(BANDIT_TIMER_NAME, TUNING.PIG_BANDIT_RESPAWN_TIME, TUNING.PIG_BANDIT_ENABLED, function()
    TrySpawnBanit()
    if _bandit then
        _worldsettingstimer:StopTimer(BANDIT_TIMER_NAME)
    else
        StartRespawnTimer()
    end
end)
StartRespawnTimer()

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local refs = {}
    local data = {}

    data.stolen_oincs = {
        oinc = _stolen_oincs.oinc,
        oinc10 = _stolen_oincs.oinc10,
        oinc100 = _stolen_oincs.oinc100,
    }

    if _bandit then
        data.bandit = _bandit.GUID
        table.insert(refs, _bandit.GUID)
    end

    if _stored_bandit then
        data.stored_bandit = _stored_bandit
    end

    return data, refs
end

function self:OnLoad(data)
    if not data then
        return
    end

    _stolen_oincs.oinc = data.stolen_oincs.oinc or 0
    _stolen_oincs.oinc10 = data.stolen_oincs.oinc10 or 0
    _stolen_oincs.oinc100 = data.stolen_oincs.oinc100 or 0

    _stored_bandit = data.stored_bandit or nil
end

function self:LoadPostPass(ents, data)
    if data.bandit and ents[data.bandit] then
        _bandit = ents[data.bandit].entity
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local s = string.format("Stolen Oincs: %d Active Bandit: %s Respawns In: %2.2f",
        (_stolen_oincs.oinc + 10 * _stolen_oincs.oinc10 + 100 * _stolen_oincs.oinc100), tostring(self:GetIsBanditActive()),
        _worldsettingstimer:GetTimeLeft(BANDIT_TIMER_NAME) or -1)

    return s
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
