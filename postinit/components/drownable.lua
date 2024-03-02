local Drownable = require("components/drownable")

local _ShouldDrown = Drownable.ShouldDrown
function Drownable:ShouldDrown(...)
	return (self.inst.components.sailor == nil or not self.inst.components.sailor:IsSailing()) and _ShouldDrown(self, ...)
end
