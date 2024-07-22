local FULL_CONFIG = {
    CLAW = 2,
    HEAD = 1,
    LEG = 2,
    RIBS = 1,
}

local MechAssembly = Class(function(self, inst)
    self.inst = inst

    self.parts = {
        CLAW = 0,
        HEAD = 0,
        LEG = 0,
        RIBS = 0,
    }
end)

function MechAssembly:SetUp(configuration)
    for body_part, amount in pairs(configuration) do
        self.parts[body_part] = math.clamp(amount, 0, FULL_CONFIG[body_part] or 0)
    end
end

function MechAssembly:ShouldSpawnHulk()
    for body_part, amount in pairs(self.parts) do
        if amount < FULL_CONFIG[body_part] then
            return false
        end
    end

    return true
end

function MechAssembly:Assemble(other)
    if not other or not other:IsValid() then
        return
    end

    local hulk = other
    if not other:HasTag("ancient_robots_assembly") then
        hulk = SpawnPrefab("ancient_robots_assembly")
        local x, y, z = self.inst.Transform:GetWorldPosition()
        hulk.Transform:SetPosition(x, 0, z)
        for body_part, amount in pairs(other.components.mechassembly.parts) do
            hulk.components.mechassembly.parts[body_part] = hulk.components.mechassembly.parts[body_part] + amount
        end
        other:Remove()
    end

    for body_part, amount in pairs(self.parts) do
        hulk.components.mechassembly.parts[body_part] = hulk.components.mechassembly.parts[body_part] + amount
    end

    hulk:PushEvent("assemble")
    self.inst:Remove()
end

function MechAssembly:Dissemble()
    local function spawn_part(spawn_data)
        local part = SpawnPrefab(spawn_data.prefab)
        part.Transform:SetPosition(spawn_data.xpos, 0, spawn_data.zpos)
        part.Transform:SetRotation(spawn_data.rotation)
        part.sg:GoToState("separate")
        part.spawned = true

        part:DoTaskInTime(math.random() * 0.6,function()
            part:PushEvent("shock")
            part.components.timer:SetTimeLeft("discharge", 20 * (math.random() + 1))
            if not TheWorld.state.isaporkalypse then
                part.components.timer:ResumeTimer("discharge")
            end
        end)
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local down = TheCamera:GetDownVec()
    local angle = math.atan2(down.z, down.x) / DEGREES

    local spawn_data = {
        HEAD       = {prefab = "ancient_robot_head", xpos = x + down.x, zpos = z + down.z, rotation = math.random() * 360},
        RIBS       = {prefab = "ancient_robot_ribs", xpos = x - down.x, zpos = z - down.z, rotation = math.random() * 360},
        CLAW_LEFT  = {prefab = "ancient_robot_claw", xpos = x - down.x, zpos = z + down.z, rotation = angle + 90},
        CLAW_RIGHT = {prefab = "ancient_robot_claw", xpos = x + down.x, zpos = z - down.z, rotation = angle - 90},
        LEG_LEFT   = {prefab = "ancient_robot_leg",  xpos = x - 2 * down.x, zpos = z + down.z, rotation = angle + 90},
        LEG_RIGHT  = {prefab = "ancient_robot_leg",  xpos = x + down.x, zpos = z - 2 * down.z, rotation = angle - 90},
    }

    if self.parts.HEAD >= 1 then
        spawn_part(spawn_data.HEAD)
    end
    if self.parts.RIBS >= 1 then
        spawn_part(spawn_data.RIBS)
    end
    if self.parts.CLAW >= 1 then
        spawn_part(spawn_data.CLAW_LEFT)
    end
    if self.parts.CLAW >= 2 then
        spawn_part(spawn_data.CLAW_RIGHT)
    end
    if self.parts.LEG >= 1 then
        spawn_part(spawn_data.LEG_LEFT)
    end
    if self.parts.LEG >= 2 then
        spawn_part(spawn_data.LEG_RIGHT)
    end

    self.inst:Remove()
end

function MechAssembly:OnSave()
    local data = {}
    for body_part, amount in pairs(self.parts) do
        data[body_part] = amount
    end

    return data
end

function MechAssembly:OnLoad(data)
    for body_part, amount in pairs(data) do
        self.parts[body_part] = amount
    end
end

function MechAssembly:GetDebugString()
    local s = ""
    for body_part, amount in pairs(self.parts) do
        s = s .. string.format("%s: %d, ", body_part, amount)
    end

    return s
end

return MechAssembly
