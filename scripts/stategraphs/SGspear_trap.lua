require("stategraphs/commonstates")

local events =
{
    EventHandler("spring", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("extended") then
            inst.sg:GoToState("extending")
        end
    end),

    EventHandler("reset", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("retracted") and not inst.components.burnable:IsBurning() then
            inst.sg:GoToState("retract")
        end
    end),

    EventHandler("hit", function(inst)
        if inst.sg:HasStateTag("extended") then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("dead", function(inst)
        inst.sg:GoToState("destroyed")
    end),
}

local radius = 1.3
local DAMAGE_NO_TAGS = {"playerghost", "FX", "NOCLICK", "DECOR", "spear_trap", "INLIMBO"}

local function DoDamage(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, radius, nil, DAMAGE_NO_TAGS)
    for _, ent in pairs(ents) do
        if ent.components.health then
            inst.components.combat:DoAttack(ent)
        elseif ent.components.workable and ent.components.workable.workleft > 0 then
            ent.components.workable:Destroy(inst)
        end
    end
end

local function SetExtended(inst, extended)
    if extended then
        inst.Physics:SetActive(true)

        if inst.MiniMapEntity then
            inst.MiniMapEntity:SetIcon("spear_trap.tex")
        end

        inst:AddTag("hostile")
        inst:RemoveTag("fireimmune")
        inst:RemoveTag("NOCLICK")

        inst.name = STRINGS.NAMES.PIG_RUINS_SPEAR_TRAP_TRIGGERED

        inst.extended = true

        if inst.components.burnable then
            inst.components.burnable.disabled = nil
        end

        inst.components.health.vulnerabletoheatdamage = true
    else
        inst.Physics:SetActive(false)

        if inst.MiniMapEntity then
            inst.MiniMapEntity:SetIcon("")
        end

        inst:AddTag("NOCLICK")
        inst:RemoveTag("hostile")
        inst:AddTag("fireimmune")

        inst.name = STRINGS.NAMES.PIG_RUINS_SPEAR_TRAP

        inst.extended = nil

        if inst.components.burnable then
            inst.components.burnable.disabled = true
        end

        inst.components.health.vulnerabletoheatdamage = false
    end
end

local states =
{
    State{
        name = "idle",
        tags = {"idle", "retracted", "invisible"},

        onenter = function(inst)
            SetExtended(inst, false)
            inst.AnimState:PlayAnimation("idle_retract", true)
        end,
    },

    State{
        name = "extending",
        tags = {"busy", "damage"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/traps/spear")
            inst.AnimState:PlayAnimation("extending")

            SetExtended(inst, true)
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst) DoDamage(inst) end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("extended") end),
        },
    },

    State{
        name = "extended",
        tags = {"extended"},

        onenter = function(inst)
            SetExtended(inst, true)
            if inst.wantstoretract then
                inst.sg:GoToState("retract")
            else
                inst.AnimState:PlayAnimation("idle_extend")
            end
        end,
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.components.health:IsDead() then
                    inst.sg:GoToState("destroyed")
                else
                    inst.sg:GoToState("extended")
                end
            end),
        },
    },

    State{
        name = "breaking",
        tags = {"busy"},

        onenter = function(inst)
            inst:RemoveTag("hostile")
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("breaking")
        end,
    },

    State{
        name = "destroyed",
        tags = {"busy"},

        onenter = function(inst)
            inst:RemoveTag("hostile")
            inst.Physics:SetActive(false)
            inst.AnimState:PlayAnimation("broken", true)
        end,
    },

    State {
        name = "retract",
        tags = {"busy"},

        onenter = function(inst)
            SetExtended(inst, false)
            inst.AnimState:PlayAnimation("retracting")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

return StateGraph("spear_trap", states, events, "idle")
