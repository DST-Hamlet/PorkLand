GLOBAL.setfenv(1, GLOBAL)

local Stackable = require("components/stackable")

local _Get = Stackable.Get
function Stackable:Get(num, ...)
    local instance = _Get(self, num, ...)

	if instance.components.visualvariant then
		instance.components.visualvariant:CopyOf(self.inst)
	end

    return instance
end
