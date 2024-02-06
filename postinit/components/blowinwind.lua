local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local SPEED_VAR_PERIOD = 5
local SPEED_VAR_PERIOD_VARIANCE = 2

AddComponentPostInit("blowinwind", function(self)
	self.spawnPeriod = 1.0
	self.timeSinceSpawn = self.spawnPeriod

	self.inst:ListenForEvent("on_landed", function(it, data)
		self:Start()
	end)
	self.inst:ListenForEvent("ondropped", function(it, data)
		self:Start()
	end)
	self.inst:ListenForEvent("onpickup", function(it, data)
		self:Stop()
	end)

    local Start = self.Start
    function self:Start(ang, vel)
        if self.inst:HasTag("falling") or (self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner) then
            return
        end

        Start(self, ang, vel)

        self.checkLandTime = math.random()
    end

    local Stop = self.Stop
    function self:Stop()
        self.velocity = Vector3(0,0,0)
        self.speed = 0.0
        self.inst.Physics:Stop()
        Stop(self)
    end

    function self:OnRemoveEntity()
        self:Stop()
    end

    function self:SpawnWindTrail(dt)
        self.timeSinceSpawn = self.timeSinceSpawn + dt
        if self.timeSinceSpawn > self.spawnPeriod and math.random() < 0.8 then
            local wake = SpawnPrefab( "windtrail")
            local x, y, z = self.inst.Transform:GetWorldPosition()
            wake.Transform:SetPosition( x, y, z )
            wake.Transform:SetRotation(self.inst.Transform:GetRotation())
            self.timeSinceSpawn = 0
        end
    end

    function self:OnUpdate(dt)

        if not self.inst then 
            self:Stop()
            return
        end

        if self.inst:HasTag("falling") or (self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner) then
            return
        end

        self.checkLandTime = self.checkLandTime - dt
        if self.checkLandTime < 0 then
            self.checkLandTime = 1 -- don't care about time accumulation
            if self.inst.components.inventoryitem then
                self.inst.components.inventoryitem:SetLanded(true, false)
            end
        end

        if TheWorld:HasTag("porkland") then
            if TheWorld.net.components.plateauwind and TheWorld.net.components.plateauwind:GetIsWindy() then
                local windspeed = TheWorld.net.components.plateauwind:GetWindSpeed() -- from 0 to 1
                local windangle = TheWorld.net.components.worldwind:GetWindAngle() * DEGREES
                self.velocity = Vector3(windspeed * math.cos(windangle), 0.0, windspeed * math.sin(windangle))
            else
                self.velocity = self.velocity + (self.windVector * dt)
            end
        else
            self:Stop()
            return
        end

        -- unbait from traps
        if self.inst.components.bait and self.inst.components.bait.trap then
            self.inst.components.bait.trap:RemoveBait()
        end

        if self.velocity:Length() > 1 then
            self.velocity = self.velocity:GetNormalized()
        end

        -- Map velocity magnitudes to a useful range of walkspeeds
        self.speed = self.velocity:Length() * self.averageSpeed

        -- Do some variation on the speed if velocity is a reasonable amount
        if self.velocity:Length() >= .5 then
            self.speedVarTime = self.speedVarTime + dt
            if self.speedVarTime > SPEED_VAR_PERIOD then
                self.speedVarTime = 0
                self.speedVarPeriod = GetRandomWithVariance(SPEED_VAR_PERIOD, SPEED_VAR_PERIOD_VARIANCE)
            end
            local speedvar = math.sin(2 * PI * (self.speedVarTime / self.speedVarPeriod))
            local mult = Remap(speedvar, -1, 1, self.minSpeedMult, self.maxSpeedMult)
            self.speed = self.speed * mult
        end

        -- Change the sound parameter if there is one
        if self.soundName and self.soundParameter and self.inst.SoundEmitter then
            self.soundspeed = self.speed / self.averageSpeed * self.maxSpeedMult
            self.inst.SoundEmitter:SetParameter(self.soundName, self.soundParameter, self.soundspeed)
        end

        -- Walk!	
        self.currentAngle = math.atan2(self.velocity.z, self.velocity.x) / DEGREES
        self.inst.Transform:SetRotation(self.currentAngle)
        self.inst.Physics:SetMotorVel(self.speed, 0, 0)


        if self.speed > 3.0 then
            self:SpawnWindTrail(dt)
        end

        local x,y,z = self.inst.Transform:GetWorldPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
        if TileGroupManager:IsOceanTile(tile) then
            if self.inst.components.burnable and self.inst.components.burnable:IsBurning() then
                self.inst.components.burnable:Extinguish() --Do this before anything that required the inventory item component, it gets removed when something is lit on fire and re-added when it's extinguished 
            end
            if self.inst.components.inventoryitem then
                self.inst.components.inventoryitem:SetLanded(true, true)
            end
            if self.inst.components.floater then
                local vx, vy, vz = self.inst.Physics:GetMotorVel()
                self.inst.Physics:SetMotorVel(0.5 * vx, 0, 0)
                self.inst:DoTaskInTime(1.0, function(inst)
                    self.inst.Physics:SetMotorVel(0, 0, 0)
                    if self.inst.components.inventoryitem then
                        self.inst.components.inventoryitem:SetLanded(true, true)
                    end
                end)
                self.inst:StopUpdatingComponent(self)
            end 
        end
    end
end)





