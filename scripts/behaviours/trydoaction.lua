-- 与DoAction不同的是, 该behavior在action失败后会重新进行一次获得action的尝试
TryDoAction = Class(BehaviourNode, function(self, inst, getactionfn, name, run, timeout)
    BehaviourNode._ctor(self, name or "TryDoAction")
    self.inst = inst
    self.shouldrun = run
    self.action = nil
    self.getactionfn = getactionfn
    self.time = nil
    self.timeout = timeout
end)

function TryDoAction:OnFail()
    self.pendingstatus = FAILED
end

function TryDoAction:OnSucceed()
    self.pendingstatus = SUCCESS
end

function TryDoAction:Visit()

    if self.status == READY then
        local action = self.getactionfn(self.inst)
		self.action = action
		self.pendingstatus = nil

        if action then
			action:AddFailAction(function()
				if action == self.action and self.pendingstatus == nil then
					self:OnFail()
				end
			end)
			action:AddSuccessAction(function()
				if action == self.action then
					self:OnSucceed()
				end
			end)
            self.inst.components.locomotor:PushAction(action, FunctionOrValue(self.shouldrun))
            self.time = GetTime()
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        if self.timeout and (GetTime() - self.time > self.timeout) then
            self.status = FAILED
            --print("Action timed out, failing")
        end

        if self.pendingstatus then
            self.status = self.pendingstatus
        elseif not self.action:IsValid() then
            self.status = FAILED
        end

        if self.status == FAILED then
            local action = self.getactionfn(self.inst)
		    self.action = action
		    self.pendingstatus = nil

            if action then
		    	action:AddFailAction(function()
		    		if action == self.action and self.pendingstatus == nil then
		    			self:OnFail()
		    		end
		    	end)
		    	action:AddSuccessAction(function()
		    		if action == self.action then
		    			self:OnSucceed()
		    		end
		    	end)
                self.inst.components.locomotor:PushAction(action, FunctionOrValue(self.shouldrun))
                self.time = GetTime()
                self.status = RUNNING
            else
                self.status = FAILED
            end
        end
    end

end

