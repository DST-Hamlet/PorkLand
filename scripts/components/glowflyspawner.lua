--------------------------------------------------------------------------
--[[ GlowflySpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "GlowflySpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _world = TheWorld
local _worldstate = _world.state

local _updating = false

local _activeplayers = {}
local _scheduledtasks = {}

local glowflys = {}

local glowflycocoontask
local glowflycocoontaskinfo
local glowflyhatchtask
local glowflyhatchtaskinfo

local glowflydata = {
    glowfly_amount = TUNING.GLOWFLYFLIES,
    glowfly_amount_default = TUNING.DEFAULT_GLOWFLY,
    glowfly_amount_max = TUNING.MAX_GLOWFLY,
    glowfly_amount_min = TUNING.MIN_GLOWFLY
}

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

-- 获取生成点
local function GetSpawnPoint(player)
	local rad = 25
    local mindistance = 36
	local x,y,z = player.Transform:GetWorldPosition()
    local MUST_TAGS = {"flower_rainforest"}
	local flowers = TheSim:FindEntities(x,y,z, rad, MUST_TAGS)

    for i, v in ipairs(flowers) do
        while v ~= nil and player:GetDistanceSqToInst(v) <= mindistance do
            table.remove(flowers, i)
            v = flowers[i]
        end
    end

    return next(flowers) ~= nil and flowers[math.random(1, #flowers)] or nil
end

-- 设置茧化倒计时
local function SetBugCocoonTimer(inst)
	inst.SetCocoonTask(inst)
end

-- 开始茧化倒计时,推送spawncocoons
local function StartCocoonTimer()
	glowflydata.glowfly_amount = glowflydata.glowfly_amount_min

	for glowfly, _ in pairs(glowflys) do
        if glowfly then
            SetBugCocoonTimer(glowfly)
        end
	end

    _world:PushEvent("spawncocoons")
end

local function SetGlowflyCocoontask(inst, time)
	glowflycocoontask, glowflycocoontaskinfo = inst:ResumeTask(time, function()
        StartCocoonTimer()
    end)
end

-- 设置萤火虫孵化
local function SetGlowflyhatchtask(inst, time)
	glowflyhatchtask, glowflyhatchtaskinfo = inst:ResumeTask(time, function()
        _world:PushEvent("glowflyhatch")
    end)
end

-- 在玩家周围生成萤火虫
local function SpawnGlowflyForPlayer(player, reschedule)
    local pt = player:GetPosition()
    local radius = 64
    local MUST_TAGS = {"glowfly"}
    local glowflys = TheSim:FindEntities(pt.x, pt.y, pt.z, radius, MUST_TAGS)

    if #glowflys < glowflydata.glowfly_amount then
        local glowfly = SpawnPrefab("glowfly")
        local spawnflower = GetSpawnPoint(player)
        if spawnflower ~= nil then
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
        local basedelay = initialspawn and 0.3 or 10
        _scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * 10, SpawnGlowflyForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function ToggleUpdate(force)
    if glowflydata.glowfly_amount > 0 and not TheWorld.state.ishumid then
        if not _updating then
            _updating = true
            for k, v in ipairs(_activeplayers) do
                ScheduleSpawn(v, true)
            end
        elseif force then
            for k, v in ipairs(_activeplayers) do
                CancelSpawn(v)
                ScheduleSpawn(v, true)
            end
        end
    elseif _updating then
        _updating = true
        for k, v in ipairs(_activeplayers) do
            CancelSpawn(v)
        end
    end
end

local function AutoRemoveTarget(inst, target)
    if glowflys[target] ~= nil and target:IsAsleep() and not target:HasTag("cocoonspawn") then
        target:Remove()
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnGlowflySleep(target)
    inst:DoTaskInTime(0, AutoRemoveTarget, target)
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

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for _, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

--Register events
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, _world)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, _world)

-- 每一帧调用OnUpdate函数
inst:StartUpdatingComponent(self)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Public getters and setters ]]
--------------------------------------------------------------------------

function self:StartTrackingFn(inst)
    if glowflys[inst] == nil then
        local restore = inst.persists and 1 or 0
        inst.persists = false
        if inst.components.homeseeker == nil then
            inst:AddComponent("homeseeker")
        else
            restore = restore + 2
        end
        glowflys[inst] = restore
        inst:ListenForEvent("entitysleep", OnGlowflySleep, inst)
    end
end

function self:StartTracking(glowfly)
    self:StartTrackingFn(glowfly)
end

function self:StopTrackingFn(inst)
    local restore = glowflys[inst]
    if restore ~= nil then
        inst.persists = restore == 1 or restore == 3
        if restore < 2 then
            inst:RemoveComponent("homeseeker")
        end
        glowflys[inst] = nil
        inst:RemoveEventCallback("entitysleep", OnGlowflySleep, inst)
    end
end

function self:StopTracking(glowfly)
    self:StopTrackingFn(glowfly)
end

function self:OnUpdate()
    if _worldstate.istemperate then
        local pct = _worldstate.seasonprogress
        if pct > 0.3 and pct <= 0.8 then
            local seasonprogress = pct + 0.2
            local diff_percent =  1 - math.sin(PI * seasonprogress)
            glowflydata.glowfly_amount = math.floor(glowflydata.glowfly_amount_default + (diff_percent * (glowflydata.glowfly_amount_max - glowflydata.glowfly_amount_default)))
        elseif pct > 0.88 then
            if not glowflycocoontask then
                SetGlowflyCocoontask(self.inst, 2 * TUNING.SEG_TIME + (math.random() * TUNING.SEG_TIME * 2))
            end
        end
    elseif _worldstate.ishumid then
        if glowflydata.glowfly_amount ~= glowflydata.glowfly_amount_min then
            glowflydata.glowfly_amount = glowflydata.glowfly_amount_min
        end

        if not glowflyhatchtask then
            SetGlowflyhatchtask(self.inst, 5)
        end
    elseif glowflydata.glowfly_amount ~= glowflydata.glowfly_amount_default then
        glowflydata.glowfly_amount = glowflydata.glowfly_amount_default
    end
end

-- self.LongUpdate = self.OnUpdate

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	local data ={
    	glowfly_amount = glowflydata.glowfly_amount,
	}

	if glowflycocoontask then
		data.glowflycocoontask = self.inst:TimeRemainingInTask(glowflycocoontaskinfo)
	end

	if glowflyhatchtask then
		data.glowflyhatchtask = self.inst:TimeRemainingInTask(glowflyhatchtaskinfo)
	end

	return data
end

function self:OnLoad(data)
    if data ~= nil then
        glowflydata.glowfly_amount = data.glowfly_amount or TUNING.DEFAULT_GLOWFLY

        if data.glowflycocoontask then
            SetGlowflyCocoontask(self.inst, data.glowflycocoontask)
        end

        if data.glowflyhatchtask then
            SetGlowflyhatchtask(self.inst, data.glowflyhatchtask)
        end
    end

    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local numglowflies = 0
    for k, v in pairs(glowflys) do
        numglowflies = numglowflies + 1
    end
    return string.format("updating:%s numglowflys:%d/%d", tostring(_updating), numglowflies, glowflydata.glowfly_amount)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
