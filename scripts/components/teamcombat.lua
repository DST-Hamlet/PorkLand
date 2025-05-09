local TeamCombat = Class(function(self, inst)
	self.inst = inst
end)

local STANDOFF_CIRCLE_DATA =
{
	["default"] = 
	{
		radius = 5,
		addition = 6,
		speed = 6,
	},

	["vampirebat"] = 
	{
		radius = 5,
		addition = 6,
		speed = 8,
	},
}

function TeamCombat:OnRemoveEntity()
    if not TheWorld.components.teammanager then
        return
    end

    TheWorld.components.teammanager:DeleteAttacker(self.inst, self.teamtype)
end

local function UpdateTeam(inst)
    if not TheWorld.components.teammanager then
        return
    end

    if inst:IsAsleep() then
        TheWorld.components.teammanager:DeleteAttacker(inst, inst.components.teamcombat.teamtype)
    else
        local target = inst.components.combat.target
        if target then
            TheWorld.components.teammanager:RegisterAttacker(inst, inst.components.teamcombat.teamtype, target)
        end
    end
end

function TeamCombat:OnEntityWake()
    self.inst:ListenForEvent("newcombattarget", UpdateTeam, self.inst)
    UpdateTeam(self.inst)
end

function TeamCombat:OnEntitySleep()
    self.inst:RemoveEventCallback("newcombattarget", UpdateTeam, self.inst)
    UpdateTeam(self.inst)
end

function TeamCombat:CanAttack()
    if not TheWorld.components.teammanager then
        return true
    end

    local data = TheWorld.components.teammanager:GetMemberData(self.inst, self.teamtype)
    if data == nil then
        return
    end

    local index, num = data.index, data.num
    local num_circle = 0
    local circle_data = STANDOFF_CIRCLE_DATA[self.teamtype] or STANDOFF_CIRCLE_DATA["default"]
    while num >= 1 do
        num_circle = num_circle + 1
        num = num - circle_data.addition * num_circle - 1
    end
    local max_active_attackers = num_circle + 1

    return index and (index <= max_active_attackers)
end

function TeamCombat:GetStandOffPoint()
    if not TheWorld.components.teammanager then
        return
    end

    if not (self.inst.components.combat.target and self.inst.components.combat.target:IsValid()) then
        return
    end

    local data = TheWorld.components.teammanager:GetMemberData(self.inst, self.teamtype)
    if data == nil then
        return
    end

    local index, num, angle = data.index, data.num, data.angle
    local circle_data = STANDOFF_CIRCLE_DATA[self.teamtype] or STANDOFF_CIRCLE_DATA["default"]
    
    local num_circle = 0
    while num >= 1 do
        num_circle = num_circle + 1
        num = num - circle_data.addition * num_circle - 1
    end
    local max_active_attackers = num_circle + 1

    index = index - max_active_attackers

    local circle = 0
    while index >= 1 do
        circle = circle + 1
        index = index - circle_data.addition * circle
    end

    local radius = circle * circle_data.radius
    angle = angle + PI2 * (index + GetTime()) / (circle_data.addition * circle)
    local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))

    return self.inst.components.combat.target:GetPosition() + offset
end

return TeamCombat
