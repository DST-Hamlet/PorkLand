-- Based off of bloomer, should be very useful for Wagstaff
local Eroder = Class(function(self, inst)
    self.inst = inst
    self.erodestack = {}
    self.children = {}
    self.invalid_sources = {}

    self._onremovesource = function(source) self:PopErode(source) end
end)

function Eroder:OnRemoveFromEntity()
    for i, v in ipairs(self.erodestack) do
		if EntityScript.is_instance(v.source) then
            self.inst:RemoveEventCallback("onremove", self._onremovesource, v.source)
        end
    end
    for k, v in pairs(self.children) do
        self.inst:RemoveEventCallback("onremove", v, k)
		if k.components.eroder ~= nil then
			k.components.eroder:PopErode(self.inst)
		end
    end
end

function Eroder:AttachChild(child)
    if self.children[child] == nil then
        self.children[child] = function(child)
            self.children[child] = nil
        end
        self.inst:ListenForEvent("onremove", self.children[child], child)
		local i, r, l, priority = self:GetCurrentParamsAndPriority()
		if i ~= nil and r ~= nil and l ~= nil then
			if child.components.eroder ~= nil then
				child.components.eroder:PushErode(self.inst, i, r, l, priority)
			else
				child.AnimState:SetErosionParams(i, r, l)
			end
		elseif child.components.eroder ~= nil then
			child.components.eroder:PopErode(self.inst)
		else
            child.AnimState:SetErosionParams(0, 0, 0)
        end
    end
end

function Eroder:DetachChild(child)
    if self.children[child] ~= nil then
        self.inst:RemoveEventCallback("onremove", self.children[child], child)
        self.children[child] = nil
		if child.components.eroder ~= nil then
			child.components.eroder:PopErode(self.inst)
		end
    end
end

function Eroder:GetCurrentParams()
    local erode = #self.erodestack > 0 and self.erodestack[#self.erodestack] or {}
    return erode.i, erode.r, erode.l
end

function Eroder:GetCurrentParamsAndPriority()
	if #self.erodestack > 0 then
		local erode = self.erodestack[#self.erodestack]
		return erode.i, erode.r, erode.l, erode.priority
	end
end

function Eroder:SetErosionParams(i, r, l, priority)
    self.inst.AnimState:SetErosionParams(i, r, l)
    for k, v in pairs(self.children) do
		if k.components.eroder ~= nil then
			k.components.eroder:PushErode(self.inst, i, r, l, priority)
		else
			k.AnimState:SetErosionParams(i, r, l)
		end
    end
end

function Eroder:OnClearErosionParams()
    self.inst.AnimState:SetErosionParams(0, 0, 0)
    for k, v in pairs(self.children) do
		if k.components.eroder ~= nil then
			k.components.eroder:PopErode(self.inst)
		else
			k.AnimState:SetErosionParams(0, 0, 0)
		end
    end
end

function Eroder:PushErode(source, i, r, l, priority)
    if source ~= nil and (self.valid_sources == nil or self.valid_sources[EntityScript.is_instance(source) and source.prefab or source] ~= nil) and i ~= nil and r ~= nil and l ~= nil then
		local oldi, oldr, oldl, oldpriority = self:GetCurrentParamsAndPriority()
        local erode = nil

        priority = priority or 0

        for i, v in ipairs(self.erodestack) do
            if v.source == source then
                erode = v
                erode.i = i
                erode.r = r
                erode.l = l
                erode.priority = priority
                table.remove(self.erodestack, i)
                break
            end
        end

        if erode == nil then
            erode = { source = source, i = i, r = r, l = l, priority = priority }
			if EntityScript.is_instance(source) then
                self.inst:ListenForEvent("onremove", self._onremovesource, source)
            end
        end

        for i, v in ipairs(self.erodestack) do
            if v.priority > priority then
                table.insert(self.erodestack, i, erode)
				local newi, newr, newl, newpriority = self:GetCurrentParamsAndPriority()
				if newi ~= oldi or newr ~= oldr or newl ~= oldl or newpriority ~= oldpriority then
					self:SetErosionParams(newi, newr, newl, newpriority)
                end
                return
            end
        end

        table.insert(self.erodestack, erode)
		if i ~= oldi or r ~= oldr or l ~= oldl or priority ~= oldpriority then
			self:SetErosionParams(i, r, l, priority)
        end
    end
end

function Eroder:PopErode(source)
    if source ~= nil then
        for i, v in ipairs(self.erodestack) do
            if v.source == source then
				if EntityScript.is_instance(source) then
                    self.inst:RemoveEventCallback("onremove", self._onremovesource, source)
                end
				local oldi, oldr, oldl, oldpriority = self:GetCurrentParamsAndPriority()
                table.remove(self.erodestack, i)
				local newi, newr, newl, newpriority = self:GetCurrentParamsAndPriority()
                if newi == nil or newr == nil or newl == nil then
                    self:OnClearErosionParams()
				elseif newi ~= oldi or newr ~= oldr or newl ~= oldl or newpriority ~= oldpriority then
					self:SetErosionParams(newi, newr, newl, newpriority)
                end
                return
            end
        end
    end
end

function Eroder:GetDebugString()
    local str = ""
    for i = #self.erodestack, 1, -1 do
        local erode = self.erodestack[i]
        str = str..string.format("\n\t[%d] %s: %s", erode.priority, tostring(erode.source), erode.i, erode.r, erode.l)
    end
    return str
end

return Eroder
