local STATES = {
    IDLE = 1,
    MOVING = 2,
    DEAD = 3,
}

local function kill_body(body)
    local health = body and body:IsValid() and body.components.health
    if health and health.currenthealth > 0 then
        health:SetVal(0)
    end
end

local function OnStartMove(inst, data)
    inst.components.multibody:OnStartMove()
end

local function OnStopMove(inst, data)
    inst.components.multibody:OnStopMove()
end

local Multibody = Class(function(self, inst)
    self.inst = inst
    self.maxbodies = 1
    self.bodies = {}
    self.bodyprefab = "pugalisk_body"
    self.state = STATES.MOVING

    self.inst:ListenForEvent("startmove", OnStartMove)
    self.inst:ListenForEvent("stopmove", OnStopMove)
end)

function Multibody:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("startmove", OnStartMove)
    self.inst:RemoveEventCallback("stopmove", OnStopMove)
end

---@param angle number the direction of the travel
---@param percent number how far along the travel the body should spawn in at
---@param pos any where the body spawns
function Multibody:SpawnBody(angle, percent, pos)
    if not angle or not percent or not pos then
        print("WARNING: Calling Multibody:SpawnBody without all parameters")
        return
    end

    local newbody = SpawnPrefab(self.bodyprefab)
    newbody.Transform:SetPosition(pos.x, pos.y, pos.z)
    newbody.components.segmented:Start(angle, nil, percent)
    newbody.host = self.inst

    table.insert(self.bodies, newbody)

    for i, body in ipairs(self.bodies) do
        if i == #self.bodies - 2 then
            body.invulnerable = false
        else
            body.invulnerable = true
        end
    end

    if #self.bodies > self.maxbodies then
        self.bodies[1].components.segmented:SetToEnd()
    end
end

function Multibody:RemoveBody(body)
    for i, lbody in ipairs(self.bodies) do
        if lbody == body then
            table.remove(self.bodies, i)
            break
        end
    end
end

function Multibody:Setup(num, prefab)
    if prefab then
        self.bodyprefab = prefab
    end
    if num then
        self.maxbodies = num
    end
end

function Multibody:OnSave()
    local data =
    {
        bodies = {},
    }

    for i, body in ipairs(self.bodies)do
        if i ~= #self.bodies then
            local x, y, z = body.Transform:GetWorldPosition()

            local angle = body.angle
            table.insert(data.bodies, {angle = angle, x = x, y = y, z = z})
        end
    end

    return data
end

function Multibody:OnLoad(data)
    if data then
        for i, body in ipairs(data.bodies) do
            self:SpawnBody(body.angle, 1, Vector3(body.x, body.y, body.z))
        end
    end
end

function Multibody:IsMoveState()
    return self.state == STATES.MOVING
end

function Multibody:OnStartMove()
    if self.state ~= STATES.MOVING and self.state ~= STATES.DEAD then
        self.state = STATES.MOVING

        for i,body in ipairs(self.bodies)do
            body.components.segmented:StartMove()
        end

        if self.tail then
            self.tail:PushEvent("tail_should_exit")
        end
    end
end

function Multibody:OnStopMove()
    if self.state ~= STATES.IDLE and self.state ~= STATES.DEAD then
        self.state = STATES.IDLE

        for i,body in ipairs(self.bodies)do
            if i == 1 and #self.bodies == self.maxbodies then
                body.components.segmented:SetToEnd()
                body:AddTag("switchToTailProp")
            end
            body.components.segmented:StopMove()
        end

    end
end

function Multibody:Kill()
    self.state = STATES.DEAD
end

function Multibody:KillAllBodies()
    for _, body in ipairs(self.bodies)do
        kill_body(body)
    end

    kill_body(self.tail)

    self:Kill()
end

return Multibody
