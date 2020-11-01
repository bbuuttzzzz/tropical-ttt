ENT.Type = "anim"
ENT.Base = "tstatus_base"
ENT.Ephemeral = true

TAccessorFuncDT(ENT, "Duration", "Float", 0)
TAccessorFuncDT(ENT, "StartTime", "Float", 4)

function ENT:PlayerSet()
	self:SetStartTime(CurTime())
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	hook.Add("Move", self, self.Move)
end

function ENT:Move(pl, move)
	if pl ~= self:GetOwner() then return end

	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(move:GetMaxSpeed())
end
