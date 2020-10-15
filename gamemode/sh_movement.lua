-- CACHED GLOBALS
local M_Entity = FindMetaTable("Entity")
local M_CMoveData = FindMetaTable("CMoveData")

local E_GetTable = M_Entity.GetTable

local M_GetVelocity = M_CMoveData.GetVelocity
local M_SetVelocity = M_CMoveData.SetVelocity

local pt, vel, mul

local reduceFrac = 0.3
local targetSpeed, currentSpeed, mul
local airSpeedLimit = 300
function GM:FinishMove(pl, move)
	pt = E_GetTable(pl)

	-- ~Simple~ Complicated anti bunny hopping. Flag is set in OnPlayerHitGround
	-- if player lands with more speed than max movement speed, the player loses
	-- reduceFrac% of the amount over the normal max
	if pt.LandSlow then
		pt.LandSlow = false

		vel = M_GetVelocity(move)

		targetSpeed = airSpeedLimit
		currentSpeed = vel:Length()


		if targetSpeed < currentSpeed then
			mul = 1 - reduceFrac + reduceFrac * targetSpeed / currentSpeed
			vel.x = vel.x * mul
			vel.y = vel.y * mul
			M_SetVelocity(move, vel)
		end

	end
end
