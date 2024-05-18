local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Locomotor = require("components/locomotor")

local function onexternalspeedmultiplier_pl(self, externalspeedmultiplier_pl)
    if self.inst.player_classified ~= nil then
        self.inst.player_classified.externalspeedmultiplier_pl:set(externalspeedmultiplier_pl)
    end
end

local function onexternalspeedmultiplier_decelerate_pl(self, externalspeedmultiplier_decelerate_pl)
    if self.inst.player_classified ~= nil then
        self.inst.player_classified.externalspeedmultiplier_decelerate_pl:set(externalspeedmultiplier_decelerate_pl)
    end
end

local function ServerExternalSpeedMultiplier_PL(self)--复制联机版的同名函数,并且修改拼写错误
    return self.externalspeedmultiplier_pl,
    self.externalspeedmultiplier_decelerate_pl
end

local function ClientExternalSpeedMultiplier_PL(self)--复制联机版的同名函数
	return (self.inst.player_classified and self.inst.player_classified.externalspeedmultiplier_pl:value() or self.externalspeedmultiplier_pl) * self:GetPredictExternalSpeedMultipler(),
    (self.inst.player_classified and self.inst.player_classified.externalspeedmultiplier_decelerate_pl:value() or self.externalspeedmultiplier_decelerate_pl) * self:GetPredictExternalSpeedMultipler()
end

local function ServerGetSpeedMultiplier_PL(self)--复制联机版的同名函数
    local mult, m_decelerate = self:ExternalSpeedMultiplier_PL()
    if self.inst.components.inventory ~= nil then
        if self.inst.components.rider ~= nil and self.inst.components.rider:IsRiding() then
            mult, m_decelerate = self.inst.components.rider:GetMount().components.locomotor:ExternalSpeedMultiplier_PL()--骑牛时使用牛本身的额外加速
            local saddle = self.inst.components.rider:GetSaddle()
            if saddle ~= nil and saddle.components.saddler ~= nil then
                mult = mult + (saddle.components.saddler:GetBonusSpeedMult() - 1)--将加速部分的乘算改成加算
            end
        elseif self.inst.components.inventory.isopen then
            --NOTE: Check if inventory is open because client GetEquips returns
            --      nothing if inventory is closed.
            --      Don't check visibility though.
			local is_mighty = self.inst.components.mightiness ~= nil and self.inst.components.mightiness:GetState() == "mighty"
            for k, v in pairs(self.inst.components.inventory.equipslots) do
                if v.components.equippable ~= nil then
					local item_speed_mult = v.components.equippable:GetWalkSpeedMult()
                    if is_mighty and item_speed_mult < 1 then
						item_speed_mult = 1
					end

                    if item_speed_mult < 1 then
                        m_decelerate = m_decelerate * item_speed_mult
                    else
                        mult = mult + (item_speed_mult - 1)--将加速部分的乘算改成加算
                    end
                end
            end
        end
    end

    mult = mult + ((self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) - 1)--将道路地皮的加速改为加算
    mult = mult * m_decelerate--将减速以乘算的方式结算

    return mult
        * self.throttle--目前没有关于这个参数的使用案例，因此不作改动
end

local function ClientGetSpeedMultiplier_PL(self)--复制联机版的同名函数
    local mult, m_decelerate = self:ExternalSpeedMultiplier_PL()
    local inventory = self.inst.replica.inventory
    if inventory ~= nil then
        local rider = self.inst.replica.rider
        if rider ~= nil and rider:IsRiding() then
            mult, m_decelerate = rider:GetMount().components.locomotor:ExternalSpeedMultiplier_PL()--骑牛时使用牛本身的额外加速
            local saddle = rider:GetSaddle()
            local inventoryitem = saddle ~= nil and saddle.replica.inventoryitem or nil
            if inventoryitem ~= nil then
                local saddle_speed_mult = inventoryitem:GetWalkSpeedMult()
                mult = mult + (saddle_speed_mult - 1)--将鞍具的速度效果改为加算
            end
        else
            --NOTE: GetEquips returns empty if inventory is closed! (Hidden still returns items.)
			local is_mighty = self.inst:HasTag("mightiness_mighty")
            for k, v in pairs(inventory:GetEquips()) do
                local inventoryitem = v.replica.inventoryitem
                if inventoryitem ~= nil then
					local item_speed_mult = inventoryitem:GetWalkSpeedMult()
                    if is_mighty and item_speed_mult < 1 then
						item_speed_mult = 1
					end

                    if item_speed_mult < 1 then
                        m_decelerate = m_decelerate * item_speed_mult
                    else
                        mult = mult + (item_speed_mult - 1)--将加速部分的乘算改成加算
                    end
                end
            end
        end
    end

    mult = mult + ((self:TempGroundSpeedMultiplier() or self.groundspeedmultiplier) - 1)--将道路地皮的加速改为加算
    mult = mult * m_decelerate--将减速以乘算的方式结算

    return mult
        * self.throttle--目前没有关于这个参数的使用案例，因此不作改动
end

function Locomotor:RecalculateExternalSpeedMultiplier_PL(sources)--复制联机版的同名函数
    local m = 1
    local m_decelerate = 1
    for source, src_params in pairs(sources) do
        for k, v in pairs(src_params.multipliers) do
            if v < 1 then
                m_decelerate = m_decelerate * v
            else
                m = m + (v - 1)--将加速部分的乘算改成加算
            end
        end
    end
    return m, m_decelerate--返回加速部分加成和减速部分加成
end

function SetExternalSpeedMultiplier_PL(self, source, key, m)--复制联机版的同名函数
    if key == nil then
        return
    elseif m == nil or m == 1 then
        self:RemoveExternalSpeedMultiplier_PL(source, key)
        return
    end
    local src_params = self._externalspeedmultipliers_pl[source]
    if src_params == nil then
        self._externalspeedmultipliers_pl[source] = {
            multipliers = { [key] = m },
            onremove = function(source)
                self._externalspeedmultipliers_pl[source] = nil
                self.externalspeedmultiplier_pl, self.externalspeedmultiplier_decelerate_pl = self:RecalculateExternalSpeedMultiplier_PL(self._externalspeedmultipliers_pl)
            end,
        }
        self.inst:ListenForEvent("onremove", self._externalspeedmultipliers_pl[source].onremove, source)
        self.externalspeedmultiplier_pl, self.externalspeedmultiplier_decelerate_pl = self:RecalculateExternalSpeedMultiplier_PL(self._externalspeedmultipliers_pl)
    elseif src_params.multipliers[key] ~= m then
        src_params.multipliers[key] = m
        self.externalspeedmultiplier_pl, self.externalspeedmultiplier_decelerate_pl = self:RecalculateExternalSpeedMultiplier_PL(self._externalspeedmultipliers_pl)
    end
end

local _SetExternalSpeedMultiplier = Locomotor.SetExternalSpeedMultiplier
function Locomotor:SetExternalSpeedMultiplier(source, key, m)
    SetExternalSpeedMultiplier_PL(self, source, key, m)
    _SetExternalSpeedMultiplier(self, source, key, m)
end

function Locomotor:RemoveExternalSpeedMultiplier_PL(source, key)--复制联机版的同名函数
    local src_params = self._externalspeedmultipliers_pl[source]
    if src_params == nil then
        return
    elseif key ~= nil then
        src_params.multipliers[key] = nil
        if next(src_params.multipliers) ~= nil then
            --this source still has other keys
            self.externalspeedmultiplier_pl, self.externalspeedmultiplier_decelerate_pl = self:RecalculateExternalSpeedMultiplier_PL(self._externalspeedmultipliers_pl)
            return
        end
    end
    --remove the entire source
    self.inst:RemoveEventCallback("onremove", src_params.onremove, source)
    self._externalspeedmultipliers_pl[source] = nil
    self.externalspeedmultiplier_pl, self.externalspeedmultiplier_decelerate_pl = self:RecalculateExternalSpeedMultiplier_PL(self._externalspeedmultipliers_pl)
end

function Locomotor:GetWalkSpeed()
    if self.inst.replica.sailor and self.inst.replica.sailor:GetBoat() then
        return self.inst.replica.sailor._currentspeed:value()
    else
        return self.walkspeed * self:GetSpeedMultiplier_PL()
    end
end

function Locomotor:GetRunSpeed()
    if self.inst.replica.sailor and self.inst.replica.sailor:GetBoat() then
        return self.inst.replica.sailor._currentspeed:value()
    else
        return self:RunSpeed() * self:GetSpeedMultiplier_PL()
    end
end

AddComponentPostInit("locomotor", function(self, inst)
    self.externalspeedmultiplier_pl = 1           --此变量用于记录加速效果（加算）
    self.externalspeedmultiplier_decelerate_pl = 1--此变量用于记录减速倍率（乘算）
    self._externalspeedmultipliers_pl = {}

    if self.ismastersim then
        self.GetSpeedMultiplier_PL = ServerGetSpeedMultiplier_PL
        self.ExternalSpeedMultiplier_PL = ServerExternalSpeedMultiplier_PL
    else
        self.GetSpeedMultiplier_PL = ClientGetSpeedMultiplier_PL
        self.ExternalSpeedMultiplier_PL = ClientExternalSpeedMultiplier_PL
    end

    addsetter(self, "externalspeedmultiplier_pl", onexternalspeedmultiplier_pl)
    addsetter(self, "externalspeedmultiplier_decelerate_pl", onexternalspeedmultiplier_decelerate_pl)
end)
