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
            trinket_17 = 1,
            oinc = 5,
            sewing_kit = 1,
            telescope = 1,
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

local UPDATE_PERIOD = 10
local BANDIT_RESPAWN_TIME = 30 * 16 * 1.5 -- 9 minutes

local CITY1_TAG = "City1"
local CITY2_TAG = "City2"

-- Public
self.inst = inst

-- Private
local _world = TheWorld
local _map = _world.Map
local _worldsettingstimer = _world.components.worldsettingstimer

local _active_players = {}
local _bandit
local _stored_bandit
local _deathtime = 0
local _stolen_oincs = {oinc = 0, oinc10 = 0, oinc100 = 0}
local _disabled = false
local _diffmod = 1

local function OnUpdate(world, dt)
    if _disabled then
        return
    end

    if _deathtime > 0 then
        local time = dt or UPDATE_PERIOD
        _deathtime = _deathtime - time
        return
    end

    if self:GetIsBanditActive() then
        return
    end

    local choices = {}
    for _, player in pairs(_active_players) do
        local x, y, z = player.Transform:GetWorldPosition()
        local tag = _map:GetIslandTagAtPoint(x, y, z)
        if not IsEntityDeadOrGhost(player) and (tag == CITY1_TAG or tag == CITY2_TAG) then
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
        value = value + oinc.oincvalue * oinc.components.stackable:GetStackSize()
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
    chance = chance * _diffmod
    if roll < chance then
        self:SpawnBanditOnPlayer(player)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnBanditDeath(src, data)
    _deathtime = BANDIT_RESPAWN_TIME
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

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function GenerateTreasure(player)
    local pos = player:GetPosition()
    local angle = math.random() * 2 * PI
    local radius = math.random(120, 200)
    local offset = FindWalkableOffset(pos, angle, radius, 18)

    if offset then
        local spawn_pos = pos + offset

        local treasure = SpawnPrefab("bandittreasure")
        treasure.Transform:SetPosition(spawn_pos:Get())

        local map = SpawnPrefab("banditmap")
        map.treasure = treasure

        _bandit.components.inventory:GiveItem(map)
    end
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SpawnBanditOnPlayer(player)
    if _bandit and _bandit:IsValid() then
        return
    else
        _bandit = nil
    end

    local x, y, z = player.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 40, {"bandit_cover"})

    local cover = GetRandomItem(ents)

    if cover then
        if _stored_bandit then
            _bandit = SpawnSaveRecord(_stored_bandit)
        else
            _bandit = SpawnPrefab("pigbandit")
            GenerateTreasure(player)
        end

        local cx, cy, cz = cover.Transform:GetWorldPosition()
        local angle = TheCamera.headingtarget
        cx = cx - 1 * math.cos(angle)
        cz = cz - 1 * math.sin(angle)

        _bandit.Transform:SetPosition(cx, 0, cz)
    end
end

function self:SetDiffMod(diff)
    _diffmod = diff
end

function self:SetDisabled(disabled)
    _disabled = disabled == true
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

self.inst:DoPeriodicTask(UPDATE_PERIOD, OnUpdate)

-- Register events
self.inst:ListenForEvent("bandit_death", OnBanditDeath)
self.inst:ListenForEvent("bandit_escaped", OnBanditEscaped)
self.inst:ListenForEvent("bandittreasure_dug", OnBanditTreasureDug)
self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)


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

    data.deathtime = _deathtime

    if _bandit then
        data.bandit = _bandit.GUID
        table.insert(refs, _bandit.GUID)
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

    _deathtime = data.deathtime
end

function self:LoadPostPass(ents, data)
    if data.bandit and ents[data.bandit] then
        _bandit = ents[data.bandit].entity
    end
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:LongUpdate(dt)
    local cycles = math.floor(dt / UPDATE_PERIOD)
    local remainder = dt % UPDATE_PERIOD

    if cycles > 0 then
        for i = 1, cycles do
            OnUpdate(UPDATE_PERIOD)
        end
    end

    if remainder > 0 then
        OnUpdate(remainder)
    end
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------


--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
