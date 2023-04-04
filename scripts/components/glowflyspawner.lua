--------------------------------------------------------------------------
--[[ GlowflySpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "GlowflySpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local SEG_TIME = TUNING.SEG_TIME

local GLOWFLYCOCOON_TIMERNAME = "glowfly_spawncocoons"

local BASEDELAY_DEFAULT = TUNING.GLOWFLY_BASEDELAY_DEFAULT
local BASEDELAY_MIN = TUNING.GLOWFLY_BASEDELAY_MIN
local BASEDELAY_MAX = TUNING.GLOWFLY_BASEDELAY_MAX

local DELAY_DEFAULT = TUNING.GLOWFLY_DELAY_DEFAULT
local DELAY_MIN = TUNING.GLOWFLY_DELAY_MIN
local DELAY_MAX = TUNING.GLOWFLY_DELAY_MAX

local GLOWFLY_AMOUNT_DEFAULT = TUNING.GLOWFLY_DEFAULT
local GLOWFLY_AMOUNT_MIN = TUNING.GLOWFLY_MIN
local GLOWFLY_AMOUNT_MAX = TUNING.GLOWFLY_MAX

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local _world = TheWorld
local _worldsettingstimer = _world.components.worldsettingstimer

local _updating = false
local _cycle = false

local _activeplayers = {}
local _scheduledtasks = {}
local _glowflys = {}

local _delay = DELAY_DEFAULT
local _basedelay = BASEDELAY_DEFAULT
local _glowfly_amount = GLOWFLY_AMOUNT_DEFAULT

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local MUST_TAGS = {"flower_rainforest"}
local function GetSpawnPoint(player)
    local rad = 25
    local mindistance = 36
    local x, y, z = player.Transform:GetWorldPosition()
    local flowers = TheSim:FindEntities(x, y, z, rad, MUST_TAGS)

    for i, flower in ipairs(flowers) do
        while flower ~= nil and player:GetDistanceSqToInst(flower) <= mindistance do
            table.remove(flowers, i)
            flower = flowers[i]
        end
    end

    return next(flowers) ~= nil and flowers[math.random(1, #flowers)] or nil
end

local function StartCocoonTimer()
    _glowfly_amount = GLOWFLY_AMOUNT_MIN
    _delay = DELAY_MAX
    _basedelay = BASEDELAY_MAX

    for glowfly in pairs(_glowflys) do
        glowfly:SetCocoonTask()
    end

    _world:PushEvent("spawncocoons")
end

local MUST_TAGS = {"glowfly"}
local function SpawnGlowflyForPlayer(player, reschedule)
    local x, y, z = player.Transform:GetWorldPosition()
    local glowflys = TheSim:FindEntities(x, y, z, 64, MUST_TAGS)

    if #glowflys < _glowfly_amount then
        local spawnflower = GetSpawnPoint(player)
        if spawnflower ~= nil then
            local glowfly = SpawnPrefab("glowfly")
            if glowfly.components.pollinator ~= nil then
                glowfly.components.pollinator:Pollinate(spawnflower)
            end
            glowfly.components.homeseeker:SetHome(spawnflower)
            glowfly.Physics:Teleport(spawnflower.Transform:GetWorldPosition())
            glowfly.OnBorn(glowfly)
        end
    end

    _scheduledtasks[player] = nil
    reschedule(player)
end

local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil then
        local basedelay = initialspawn and 0.3 or _basedelay
        _scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * _delay, SpawnGlowflyForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function ToggleUpdate(force)
    if _glowfly_amount > 0 then
        if not _updating then
            _updating = true
            for _, player in ipairs(_activeplayers) do
                ScheduleSpawn(player, true)
            end
        elseif force then
            for _, player in ipairs(_activeplayers) do
                CancelSpawn(player)
                ScheduleSpawn(player, true)
            end
        end
    elseif _updating then
        _updating = false
        for _, player in ipairs(_activeplayers) do
            CancelSpawn(player)
        end
    end
end

local function AutoRemoveTarget(inst, target)
    if _glowflys[target] ~= nil and target:IsAsleep() and not target:HasTag("cocoonspawn") then
        target:Remove()
    end
end

local function OnGlowflySleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnSetGlowflyCycle(src, enabled)
    _cycle = enabled
end

local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    if _updating then
        ScheduleSpawn(player, true)
    end
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            CancelSpawn(player)
            table.remove(_activeplayers, i)
            return
        end
    end
end

local function OnSeasonTick(src, data)
    if not _cycle then
        _glowfly_amount = GLOWFLY_AMOUNT_DEFAULT
        _delay = DELAY_DEFAULT
        _basedelay = BASEDELAY_DEFAULT

        return
    end

    if data.season == "temperate" then
        local seasonprogress = data.progress
        if seasonprogress > 0.3 and seasonprogress <= 0.8 then
            seasonprogress = seasonprogress + 0.2
            local diff_percent =  1 - math.sin(PI * seasonprogress)
            _glowfly_amount = math.floor(GLOWFLY_AMOUNT_DEFAULT + (diff_percent * (GLOWFLY_AMOUNT_MAX - GLOWFLY_AMOUNT_DEFAULT)))
            _delay = math.floor(DELAY_DEFAULT + (diff_percent * (DELAY_MIN - DELAY_DEFAULT)))
            _basedelay = math.floor(BASEDELAY_DEFAULT + (diff_percent * (BASEDELAY_MIN - BASEDELAY_DEFAULT)))
        elseif seasonprogress > 0.88 then
            if not _worldsettingstimer:ActiveTimerExists(GLOWFLYCOCOON_TIMERNAME) then
                _worldsettingstimer:StartTimer(GLOWFLYCOCOON_TIMERNAME, 2 * SEG_TIME + 2 * SEG_TIME * math.random())
            end
        end
    elseif data.season == "humid" then
        if _glowfly_amount ~= GLOWFLY_AMOUNT_MIN then
            _glowfly_amount = GLOWFLY_AMOUNT_MIN
            _delay = DELAY_MAX
            _basedelay = BASEDELAY_MAX
        end
    elseif _glowfly_amount ~= GLOWFLY_AMOUNT_DEFAULT then
        _glowfly_amount = GLOWFLY_AMOUNT_DEFAULT
        _delay = DELAY_DEFAULT
        _basedelay = BASEDELAY_DEFAULT
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

-- Initialize variables
for _, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

-- Register events
inst:ListenForEvent("ms_setglowflycycle", OnSetGlowflyCycle, _world)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)
inst:ListenForEvent("seasontick", OnSeasonTick, _world)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    _worldsettingstimer:AddTimer(GLOWFLYCOCOON_TIMERNAME, 4 * SEG_TIME, true, StartCocoonTimer)

    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

function self.StartTrackingFn(inst)
    if _glowflys[inst] == nil then
        local restore = inst.persists and 1 or 0
        inst.persists = false
        if inst.components.homeseeker == nil then
            inst:AddComponent("homeseeker")
        else
            restore = restore + 2
        end
        _glowflys[inst] = restore
        inst:ListenForEvent("entitysleep", OnGlowflySleep, inst)
    end
end

function self:StartTracking(glowfly)
    self.StartTrackingFn(glowfly)
end

function self.StopTrackingFn(inst)
    local restore = _glowflys[inst]
    if restore ~= nil then
        inst.persists = restore == 1 or restore == 3
        if restore < 2 then
            inst:RemoveComponent("homeseeker")
        end
        _glowflys[inst] = nil
        inst:RemoveEventCallback("entitysleep", OnGlowflySleep, inst)
    end
end

function self:StopTracking(glowfly)
    self.StopTrackingFn(glowfly)
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    return {
        glowfly_amount = _glowfly_amount,
        basedelay = _basedelay,
        delay = _delay
    }
end

function self:OnLoad(data)
    if data ~= nil then
        _glowfly_amount = data.glowfly_amount or GLOWFLY_AMOUNT_DEFAULT
        _basedelay = data.basedelay or BASEDELAY_DEFAULT
        _delay = data.delay or DELAY_DEFAULT
    end

    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local numglowflies = 0
    for k, v in pairs(_glowflys) do
        numglowflies = numglowflies + 1
    end
    return string.format("updating:%s numglowflys:%d/%d", tostring(_updating), numglowflies, _glowfly_amount, _basedelay, _delay)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
