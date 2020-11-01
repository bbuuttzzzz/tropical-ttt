---- Dummy ent that just spawns a random TTT grenade item and kills itself

ENT.Type = "point"
ENT.Base = "base_point"


function ENT:Initialize()
   local nades = ents.TTT.GetSpawnableGrenades()

   if nades then
      local w = nades[math.random(#nades)]
      local ent = ents.Create(WEPS.GetClass(w))
      if IsValid(ent) then
         ent:SetPos(self:GetPos())
         ent:SetAngles(self:GetAngles())
         ent:Spawn()
         ent:PhysWake()
      end

      self:Remove()
   end
end
