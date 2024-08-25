require("stategraphs/commonstates")

local actionhandlers =
{
}

local events =
{
}

local function SpawnAnt(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ant = SpawnPrefab("antman")
    ant.Transform:SetPosition(x, y, z)
end


local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.AnimState:PlayAnimation("spin", true)
        end,
    },

    State{
        name = "land",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_impact")
            inst.AnimState:PlayAnimation("land", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("spawn")
            end),
        }
    },

    State{
        name = "spawn",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("spawn", false)
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst) SpawnAnt(inst) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        }
    },
}

return StateGraph("antlarva", states, events, "idle", actionhandlers)
