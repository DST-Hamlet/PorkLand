require "behaviours/doaction"

local WAKE_UP_DIST = 7.5

local function IsPlayerInVicinity(inst)
    return FindEntity(inst, WAKE_UP_DIST, nil, {"player"}, {"INLIMBO", "playerghost"}) ~= nil
end

local function IsFirstEncounter(inst)
    return inst.components.combat.target == nil
end

local function GoToState(inst, state)
    if inst.sg.currentstate.name ~= state then
        inst.sg:GoToState(state)
    end
end

local function InAvailableState(inst)
    return inst.sg.currentstate.name ~= "taunt" and inst.sg.currentstate.name ~= "wake" and
           inst.sg.currentstate.name ~= "sleeping" and inst.sg.currentstate.name ~= "sleep"
           and not inst.sg.tags["busy"]
end

local function CanAttack(inst)
    return inst.components.combat.canattack and InAvailableState(inst) and not inst.components.health:IsDead()
end

local function IsQuaking(inst)
    return TheWorld.components.interiorquaker:IsRoomQuaking(inst:GetCurrentInteriorID()) and not (inst.components.health:GetPercent() <= 0.3)
end

local function WakeUpFn(inst)
    GoToState(inst, "wake")
end

local function SetCoolDown(inst, min, max)
    inst.components.combat:BlankOutAttacks(math.random(min, max), function(inst)
        if math.random() < 0.3 and not inst.components.health:IsDead() then
            inst.sg:GoToState("taunt")
        end
    end)
end

local jump_attack_chance = { 0.9, 0.5, 0.25, }
local function TryJumpAttack(inst)
    if inst.jump_attack_count < inst.max_jump_attack_count and CanAttack(inst) and not IsQuaking(inst) then
        if (inst.components.health:GetPercent() > 0.75)
            or math.random() < (jump_attack_chance[inst.jump_attack_count + 1] or 0.1) then

            return true
        end
    end
    return false
end

local function JumpAttack(inst)
    if not TryJumpAttack(inst) then
        return false
    end

    inst.sanity_attack_count = 0
    inst.last_attack_time = GetTime()
    inst.jump_attack_count = inst.jump_attack_count + 1
    GoToState(inst, "jump_attack")
    SetCoolDown(inst, inst.min_combat_cooldown, inst.max_combat_cooldown)
end

local function TrySummonWarriors(inst)
    if InAvailableState(inst) and not inst.components.health:IsDead() then
        if (inst.warrior_count == 0 and not IsQuaking(inst)) or (inst.last_attack_time and GetTime() - inst.last_attack_time >= 60) then

            if inst.components.combat.blanktask then
                inst.components.combat.blanktask:Cancel()
            end
            inst.components.combat.blanktask = nil
            inst.components.combat.canattack = true

            return true
        end
    end

    return false
end

local function SummonWarriors(inst)
    inst.jump_attack_count = 0
    inst.sanity_attack_count = 0
    inst.last_attack_time = GetTime()

    GoToState(inst, "summon_warriors")
    SetCoolDown(inst, inst.min_combat_cooldown/2, inst.max_combat_cooldown/2)
end

local function TrySanityAttack(inst)
    return inst.components.health:GetPercent() <= 0.75
        and inst.sanity_attack_count < inst.max_sanity_attack_count
        and CanAttack(inst)
        and not TheWorld.components.interiorquaker:IsRoomQuaking(inst:GetCurrentInteriorID())
end

local function SanityAttack(inst)
    if not TrySanityAttack(inst) then
        return false
    end

    inst.jump_attack_count = 0
    inst.sanity_attack_count = inst.sanity_attack_count + 1
    inst.last_attack_time = GetTime()

    GoToState(inst, "music_attack")
    SetCoolDown(inst, inst.min_combat_cooldown, inst.max_combat_cooldown)
end

local AntQueenBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AntQueenBrain:OnStart()
    local root = PriorityNode({
        --TODO: check if we're already in combat in case the player put the queen to sleep
        IfNode(function() return IsPlayerInVicinity(self.inst) and IsFirstEncounter(self.inst)
            and (self.inst.sg.currentstate.name == "sleeping" or self.inst.sg.currentstate.name == "sleep") end, "PlayerInVicinity",
            DoAction(self.inst, function()
                if self.inst.components.combat.target == nil then
                    self.inst.components.combat:SetTarget(FindClosestPlayerToInst(self.inst, 50, true))
                    WakeUpFn(self.inst)
                end
            end, "WakingUp")),

        IfNode(function() return TrySummonWarriors(self.inst) end, "TrySummonWarriors", DoAction(self.inst, SummonWarriors, "SummonWarriors", false)),

        IfNode(function() return TryJumpAttack(self.inst) end, "TryJumpAttack", DoAction(self.inst, JumpAttack, "JumpAttack", false)),

        IfNode(function() return TrySanityAttack(self.inst) end, "TrySanityAttack", DoAction(self.inst, SanityAttack, "SanityAttack", false)),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return AntQueenBrain
