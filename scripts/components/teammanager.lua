local TeamManager = Class(function(self, inst)
    self.inst = inst

    self.teams = {}

    self.inst:ListenForEvent("newcombattarget", function()
        self:Update()
    end, self.inst)

    inst:StartUpdatingComponent(self)
end)

function TeamManager:RegisterAttacker(attacker, teamtype, target)
    self:DeleteAttacker(attacker, teamtype)

    if self.teams[teamtype] == nil then
        self.teams[teamtype] = {}
    end

    if self.teams[teamtype][target] == nil then
        self.teams[teamtype][target] = {
            members = {},
            angle = math.random() * TWOPI,
        }
    end

    table.insert(self.teams[teamtype][target].members, attacker)
end

function TeamManager:DeleteAttacker(attacker, teamtype)
    if self.teams[teamtype] == nil then
        return
    end

    for target, team in pairs(self.teams[teamtype]) do
        local attackers = team.members
        for i, v in ipairs(attackers) do
            if v == attacker then
                table.remove(attackers, i)
                if #attackers == 0 then
                    self.teams[teamtype][target] = nil
                end
                break
            end
        end
    end
end

function TeamManager:GetMemberData(attacker, teamtype)
    if self.teams[teamtype] == nil then
        return
    end

    for target, team in pairs(self.teams[teamtype]) do
        local attackers = team.members
        local num_attackers = #attackers
        for i, v in ipairs(attackers) do
            if v == attacker then
                return {index = i,
                    num = num_attackers,
                    angle = team.angle}
            end
        end
    end

    return
end

function TeamManager:Update(dt)

end

return TeamManager
