include("shared.lua")

function ENT:Initialize()
	self.BaseClass.Initialize(self)
    self.StaggerDir = VectorRand():GetNormalized()
    hook.Add("CreateMove", self, self.CreateMove)
end

function ENT:CreateMove(cmd)
    if (self:GetOwner():Health() <= self:GetOwner().PalsyThreshold) then
        -- when framereate drops below tick rate it speeds up CBA to think of a solution
        local ft = FrameTime()

        self.StaggerDir = (self.StaggerDir + ft * 8 * VectorRand()):GetNormalized()

        local ang = cmd:GetViewAngles()
        local rate = ft * math.min(1,(self:GetOwner().PalsyThreshold - self:GetOwner():Health()) * self:GetOwner().PalsyStrengthMultiplier)

        ang.pitch = math.NormalizeAngle(ang.pitch + self.StaggerDir.z * rate)
        ang.yaw = math.NormalizeAngle(ang.yaw + self.StaggerDir.x * rate)
        cmd:SetViewAngles(ang)
    end
end
