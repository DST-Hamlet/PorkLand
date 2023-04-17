local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("ambientlighting", function(self, inst)
    local _realcolour = Pl_Util.GetUpvalue(self.LongUpdate, "_realcolour")

    function self:GetRealColour()
        return _realcolour.currentcolour.x, _realcolour.currentcolour.y, _realcolour.currentcolour.z
    end
end)
