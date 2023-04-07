require("stategraphs/commonstates")

local events = {
    EventHandler("attacked", function(inst)
        if inst.components.health:GetPercent() > 0 then
            inst.sg:GoToState("cocoon_hit")
        end
    end),

    EventHandler("hatch", function(inst)
        inst.sg:GoToState("cocoon_pst")
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
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        }
    },

    State{
        name = "cocoon_pst",
        tags = {"cocoon", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("cocoon_idle_pst")
        end,

        timeline = {
            TimeEvent(28 * FRAMES, function(inst)
                if not inst.sg:HasStateTag("death") then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/mosquito/mosquito_explo")

                    local x, y, z = inst.Transform:GetWorldPosition()
                    local rotation = inst.Transform:GetRotation()
                    local rabid_beetle = SpawnPrefab("rabid_beetle")
                    rabid_beetle.Transform:GetRotation(rotation)
                    rabid_beetle.Transform:SetPosition(x, y, z)
                    rabid_beetle.sg:GoToState("hatch")
                end
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },

        onexit = function(inst)
            inst:Remove()
        end,
    },

    State{
        name = "cocoon_expire",
        tags = {"cocoon", "busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("cocoon_idle_pst")
        end,

        events = {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },

        onexit = function(inst)
            inst:Remove()
        end,
    },

    State{
        name = "cocoon_hit",
        tags = {"cocoon", "busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/hit")
            inst.AnimState:PlayAnimation("cocoon_hit")
            inst.Physics:Stop()
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "death",
        tags = {"cocoon", "busy", "death"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/glowfly/death")
            inst.AnimState:PlayAnimation("cocoon_death")

            RemovePhysicsColliders(inst)
            if inst.components.lootdropper ~= nil then
                inst.components.lootdropper:DropLoot(inst:GetPosition())
            end
        end,
    },
}

return StateGraph("glowfly_cocoon", states, events, "idle")
