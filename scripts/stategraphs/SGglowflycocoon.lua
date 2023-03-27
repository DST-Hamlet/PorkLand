require("stategraphs/commonstates")

local events = {
    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 then
            inst.sg:GoToState("cocoon_hit")
        end
    end),

    EventHandler("hatch", function(inst)
        if inst:HasTag("cocoon") then
            inst.sg:GoToState("cocoon_pst")
        end
    end),

    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("cocoon_idle_loop", true)
        end,

        events = {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "cocoon_pst",
        tags = {"cocoon","busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.SpawnRabidBeetle(inst)
            inst.AnimState:PlayAnimation("cocoon_idle_pst")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "cocoon_expire",
        tags = {"cocoon","busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("cocoon_idle_pst")
        end,

        events= {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "cocoon_hit",
        tags = {"cocoon","busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("pl/creatures/glowfly/hit")
            inst.AnimState:PlayAnimation("cocoon_hit")
            inst.Physics:Stop()
        end,

        events= {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "death",
        tags = {"cocoon","busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("cocoon_death")

            RemovePhysicsColliders(inst)
            if inst.components.lootdropper ~= nil then
                inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            end
        end,
    },
}

return StateGraph("glowflycocoon", states, events, "idle")
