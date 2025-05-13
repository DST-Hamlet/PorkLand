-- This is basically what a tag should do,
-- able to be found easily without having to iterate through all the entities

local GlobalEntityRegistry = Class(function(self, inst)
    self.inst = inst
    self.entities = {}
end)

function GlobalEntityRegistry:Register(tag, entity)
    if not self.entities[tag] then
        self.entities[tag] = {}
    end
    entity:ListenForEvent("onremove", function(inst)
        if self.entities[tag] then
            table.removearrayvalue(self.entities[tag], inst)
        end
    end)
    table.insert(self.entities[tag], entity)
end

function GlobalEntityRegistry:Get(tag)
    return self.entities[tag] or {}
end

return GlobalEntityRegistry
