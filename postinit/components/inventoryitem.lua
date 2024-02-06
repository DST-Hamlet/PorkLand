local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("inventoryitem", function(self, inst)
    inst:AddTag("isinventoryitem")

    local OnDropped = self.OnDropped
    function self:OnDropped(randomdir, speedmult, skipfall)
        OnDropped(self, randomdir, speedmult)
        if not skipfall then
            self.inst:AddTag("falling")
        end
    end

    local SetLanded = self.SetLanded
    function self:SetLanded(is_landed, should_poll_for_landing)
        SetLanded(self, is_landed, should_poll_for_landing)
        if is_landed then
            self.inst:RemoveTag("falling")
        end
    end

    function self:OnHitCloud()
        self.inst:RemoveTag("falling")
        local x,y,z = self.inst.Transform:GetWorldPosition()
        if self.inst:HasTag("irreplaceable") then
            local sx, sy, sz = FindRandomPointOnShoreFromOcean(x, y, z)
            if sx ~= nil then
                inst.Transform:SetPosition(sx, sy, sz)
            else
                -- Our reasonable cases are out... so let's loop to find the portal and respawn there.
                for k, v in pairs(Ents) do
                    if v:IsValid() and v:HasTag("multiplayer_portal") then
                        inst.Transform:SetPosition(v.Transform:GetWorldPosition())
                    end
                end
            end
        else
            --local fx = SpawnPrefab("splash_clouds_drop")
            --fx.Transform:SetPosition(x, y, z)
            self.inst:Remove()
        end
    end

end)
