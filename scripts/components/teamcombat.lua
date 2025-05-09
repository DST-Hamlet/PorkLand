local function UpdateTeam(inst)
    if not TheWorld.components.teammanager then
        return
    end

    if inst:IsAsleep() or inst.components.health:IsDead() then
        TheWorld.components.teammanager:DeleteAttacker(inst, inst.components.teamcombat.teamtype)
    else
        local target = inst.components.combat.target
        if target then
            TheWorld.components.teammanager:RegisterAttacker(inst, inst.components.teamcombat.teamtype, target)
        else
            TheWorld.components.teammanager:DeleteAttacker(inst, inst.components.teamcombat.teamtype)
        end
    end
end

local TeamCombat = Class(function(self, inst)
	self.inst = inst

    self.inst:ListenForEvent("death", UpdateTeam, self.inst)
end)

local STANDOFF_CIRCLE_DATA =
{
	["default"] =
	{
		radius = 5,
		addition = 6,
        angular_speed = 1.5,
	},

	["vampirebat"] =
	{
		radius = 5,
		addition = 6,
        angular_speed = 1.8,
	},
}

function TeamCombat:OnRemoveEntity()
    if not TheWorld.components.teammanager then
        return
    end

    TheWorld.components.teammanager:DeleteAttacker(self.inst, self.inst.components.teamcombat.teamtype)
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
    num = num - 1
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
    num = num - 1
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

    if circle < 1 then
        return
    end

    local current_circle_num = 0
    if circle == num_circle then
        current_circle_num = circle_data.addition * circle + num
    else
        current_circle_num = (circle_data.addition * circle)
    end

    local radius = circle * circle_data.radius
    -- 平均分配最外圈的环绕者
    angle = angle + PI2 * (- (index - 1) / current_circle_num + (GetTime() * circle_data.angular_speed) / (circle_data.addition * circle))
    if circle % 2 == 0 then
        angle = - angle
    end
    local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))

    return self.inst.components.combat.target:GetPosition() + offset
end

return TeamCombat
