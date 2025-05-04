GLOBAL.setfenv(1, GLOBAL)

-- require("behaviours/follow")
-- require("behaviours/wander")

local AbigailBrain = require("brains/abigailbrain")

local function InsertAction(parent_node, i, node)
    node.parent = parent_node
    table.insert(parent_node.children, i, node)
end

local on_start = AbigailBrain.OnStart
function AbigailBrain:OnStart(...)
    on_start(self, ...)

    local while_node = self.bt.root.children[1]
    if not (while_node and while_node.children) then
        return
    end
    local priority_node = while_node.children[2]
    if not (priority_node and priority_node.children) then
        return
    end

    local stand_still_behaviour = WhileNode(function() return self.inst:HasTag("movements_frozen") end, "Freeze Movements",
        StandStill(self.inst)
    )
    local goto_behaviour = PriorityNode({
        Leash(self.inst, function(inst) return inst._goto_position end, 1, 1, true),
        ActionNode(function() self.inst._goto_position = nil end),
    }, 0.25)

    for i, node in ipairs(priority_node.children) do
        if node.children and node.children[1] and node.children[1].name == "DefensiveMove" then
            InsertAction(priority_node, i, stand_still_behaviour)
            InsertAction(priority_node, i, goto_behaviour)
            break
        end
    end
end
