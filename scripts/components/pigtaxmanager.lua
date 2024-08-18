return Class(function(self, inst)
    assert(TheWorld.ismastersim, "PigTaxManger should not exist on client")

    self.inst = inst
    self.city_halls = {}

    self.RegisterPlayerCityHall = function(self, city_hall)
        self.city_halls[city_hall] = true
        city_hall:ListenForEvent("onremove", function()
            self:OnPlayerCityHallRemoved(city_hall)
        end)
    end

    self.OnPlayerCityHallRemoved = function(self, city_hall)
        self.city_halls[city_hall] = nil
    end

    self.HasPlayerCityHall = function(self)
        return not IsTableEmpty(self.city_halls)
    end

    self.IsTaxDay = function(self)
        return TheWorld.state.cycles % 10 == 0
    end
end)
