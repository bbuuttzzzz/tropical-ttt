ENT.Type = "anim"
ENT.Base = "tstatus_base"
ENT.Ephemeral = true

TAccessorFuncDT(ENT, "Duration", "Float", 0)
TAccessorFuncDT(ENT, "StartTime", "Float", 4)

function ENT:PlayerSet()
	self:SetStartTime(CurTime())
end