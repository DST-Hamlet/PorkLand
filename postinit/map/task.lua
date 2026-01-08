GLOBAL.setfenv(1, GLOBAL)

---@class task
---@field set_pieces { name: string }[]
---@field gen_method string

local task_ctor = Task._ctor
function Task:_ctor(id, data, ...)
    task_ctor(self, id, data, ...)
    self.set_pieces = data.set_pieces
    self.gen_method = data.gen_method or "default"
    self.room_choices_sorted = data.room_choices_sorted
end
