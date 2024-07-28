--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ SpiderMonkeyHerd class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "SpiderMonkeyHerd should not exist on client")

local ADD_TO_HERD_MAX_DISTSQ = 200 * 200
local REMOVE_FROM_HERD_DISTSQ = 220 * 220
local CREATE_HERD_MIN_DISTSQ = 400 * 400
local MAX_MONKEY_PER_HERD = 6
local FIND_NEW_TREE_DIST = 200 -- absurd...

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

self.updatetime = 0

local _herds = {}
local _monkeys = {}

function self:AddToHerd(monkey)
    if monkey.inherd then
        return
    end

    _monkeys[monkey] = monkey

    local target_herd
    local nearby_herd
    local x, y, z = monkey.Transform:GetWorldPosition()
    local island_tag = TheWorld.Map:GetIslandTagAtPoint(x, y, z) -- this can be nil
    for _, herd in pairs(_herds) do
        if herd.leader and herd.leader:IsValid() and herd.tag == island_tag then
            if monkey:GetDistanceSqToInst(herd.leader) <= ADD_TO_HERD_MAX_DISTSQ then
                target_herd = herd
                break
            elseif nearby_herd == nil and monkey:GetDistanceSqToInst(herd.leader) <= CREATE_HERD_MIN_DISTSQ then
                nearby_herd = true
            end
        end
    end

    if not target_herd and island_tag and not nearby_herd then
        target_herd = {
            tag = island_tag,
            leader = monkey,
            monkeys = {},
            next_regen = GetRandomWithVariance(TUNING.SPIDER_MONKEY_MATING_SEASON_BABYDELAY, TUNING.SPIDER_MONKEY_MATING_SEASON_BABYDELAY_VARIANCE),
        }
        table.insert(_herds, target_herd)
    end

    if target_herd then
        table.insert(target_herd.monkeys, monkey)
        monkey.inherd = true
        monkey.herd = target_herd
    end
end

function self:RemoveFromHerd(monkey)
    if monkey.herd then
        RemoveByValue(monkey.herd.monkeys, monkey)
        monkey.herd = nil
    end
end

function self:SpawnNewMonkey(herd)
    if GetTableSize(herd.monkeys) >= MAX_MONKEY_PER_HERD then
        return
    end

    local tree = FindEntity(herd.leader, FIND_NEW_TREE_DIST, function(ent)
        local other_monkey_tree = FindEntity(ent, 7, nil, {"has_spider"}, {"burnt", "stump", "rotten"})
        return other_monkey_tree == nil
    end, nil, {"burnt", "stump", "rotten", "has_spider"}, {"rainforesttree", "spider_monkey_tree"})

    if tree then
        local new_monkey = SpawnPrefab("spider_monkey")
        new_monkey.targettree = tree
        new_monkey.Transform:SetPosition(tree:GetPosition():Get())
        print("SPAWNED NEW MONKEY: ", new_monkey)
    end
end

local function OnUpdate(self, dt)
    -- Check for empty monkey herds
    local mark_for_remove = {}
    for k, herd in pairs(_herds) do
        if not next(herd.monkeys) then
            mark_for_remove[k] = herd
        end
    end

    -- Remove the herds
    for k, herd in pairs(mark_for_remove) do
        _herds[k] = nil
    end
    mark_for_remove = nil

    for _, herd in pairs(_herds) do
        -- Elect new leader
        if not herd.leader or not herd.leader:IsValid() then
            local new_leader = GetRandomItem(herd.monkeys)
            herd.leader = new_leader
        end

        -- Regen monkey
        herd.next_regen = herd.next_regen - dt
        if herd.next_regen <= 0 then
            self:SpawnNewMonkey(herd)
            herd.next_regen = GetRandomWithVariance(TUNING.SPIDER_MONKEY_MATING_SEASON_BABYDELAY, TUNING.SPIDER_MONKEY_MATING_SEASON_BABYDELAY_VARIANCE)
        end
    end

    -- Remove for monkeys away from herd
    for _, monkey in pairs(_monkeys) do
        if monkey and monkey:IsValid() then
            if monkey.herd and monkey.herd.leader and monkey:GetDistanceSqToInst(monkey.herd.leader) > REMOVE_FROM_HERD_DISTSQ then
                self:RemoveFromHerd(monkey)
            else
                self:AddToHerd(monkey)
            end
        else
            self:RemoveFromHerd(monkey)
        end
    end
end

function self:OnSave()
    local data = {}
    local refs = {}

    if next(_monkeys) then
        data.monkeys = {}
        for _, monkey in pairs(_monkeys) do
            table.insert(data.monkeys, monkey.GUID)
            table.insert(refs, monkey.GUID)
        end
    end

    if next(_herds) then
        data.herds = {}
        for _, herd in pairs(_herds) do
            local herd_data = {
                tag = herd.tag,
                leader = herd.leader.GUID,
                monkeys = {},
                next_regen = herd.next_regen,
            }
            for _, monkey in pairs(herd.monkeys) do
                table.insert(herd_data.monkeys, monkey.GUID)
            end
            table.insert(data.herds, herd_data)
        end
    end

    return data, refs
end

function self:LoadPostPass(ents, data)
    if not data then
        return
    end

    if data.herds and next(data.herds) then
        for _, herd in pairs(data.herds) do
            local herd_data = {
                tag = herd.tag,
                monkeys = {},
                next_regen = herd.next_regen,
            }
            if ents[herd.leader].entity then
                herd_data.leader = ents[herd.leader].entity
            end
            for _, monkey_GUID in pairs(herd.monkeys) do
                if ents[monkey_GUID] then
                    table.insert(herd_data.monkeys, ents[monkey_GUID].entity)
                end
            end
            table.insert(_herds, herd_data)
        end
    end

    if data.monkeys and next(data.monkeys) then
        for _, monkey_GUID in pairs(data.monkeys) do
            if ents[monkey_GUID] then
                _monkeys[ents[monkey_GUID].entity] = ents[monkey_GUID].entity
            end
        end
    end
end

function self:GetDebugString(ents, data)
    for k, herd in pairs(_herds) do
        if herd.leader and herd.leader:IsValid() then
            print("herd:", k, "    leader:", herd.leader, "    members:", #herd.monkeys, "    next_regen:", herd.next_regen)
        end
    end
end

function self:OnUpdate(dt)
    self.updatetime = self.updatetime -dt
    if self.updatetime < 0 then
        OnUpdate(self, 1 - self.updatetime)
        self.updatetime = 1
    end
end

function self:LongUpdate(dt)
    self:OnUpdate(dt)
end

end)
