GLOBAL.setfenv(1, GLOBAL)

local TeamLeader = require("components/teamleader")

local _OnUpdate = TeamLeader.OnUpdate
function TeamLeader:OnUpdate(dt, ...)  -- 修复了群体战斗生物不会因为仇恨从睡觉中醒来的bug，如果未来游戏本体修复了这个bug，请移除此函数中的代码
	if not self.threat:IsValid() or
		self.threat:IsInLimbo() or
		(self.threat and self.threat.components.health and self.threat.components.health:IsDead()) or
		self.threat:HasTag("playerghost") or
        self.threat:HasTag("noattack") or
        self.threat:HasTag("flight") or
        self.threat:HasTag("invisible") then  -- 复制自combat组件的keeptarget检测和CanBeAttacked函数
			self.threat = nil
	end
    return _OnUpdate(self, dt, ...)
end

