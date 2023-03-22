
	-- Sonic 2 gator badnik

// Variables for ease of tweaking

local GATORRANGE = 700		-- How far the gator will look for players
local GATORAGGRO = 300		-- Range at which the gator starts preparing their dash
local GATORCHARG = 2		-- How many times the gator can charge before getting tired

// SOC stuff
freeslot("MT_S2GATOR",
		 "S_GATOR_IDLE", "S_GATOR_IDLE2", "S_GATOR_LEER", "S_GATOR_PREPCHARGE",
		 "S_GATOR_CHARGE", "S_GATOR_RECHARGE", "S_GATOR_TIRED",
		 "SPR_GATO")

mobjinfo[MT_S2GATOR] = {
	doomednum = 4014,
	spawnstate = S_GATOR_IDLE,
	seestate = S_GATOR_LEER,
	deathstate = S_XPLD_FLICKY,
	deathsound = sfx_pop,
	radius = 28*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_ENEMY|MF_SPECIAL|MF_SHOOTABLE,
	--$Name Gator
	--$Sprite GATOA1
}

// Idle
states[S_GATOR_IDLE] = {
	sprite = SPR_GATO,
	frame = A,
	tics = 5,
	action = A_Look,
	var1 = 700 << 16,
	nextstate = S_GATOR_IDLE
}

// Staring
states[S_GATOR_LEER] = {
	sprite = SPR_GATO,
	frame = A,
	tics = 5,
	action = A_FaceTarget,
	nextstate = S_GATOR_LEER
}

// Winding up
states[S_GATOR_PREPCHARGE] = {
	sprite = SPR_GATO,
	frame = FF_ANIMATE|A,
	var1 = 5,
    var2 = 1,
	tics = 45,
	nextstate = S_GATOR_CHARGE,
}

// Charge dash
states[S_GATOR_CHARGE] = {
	sprite = SPR_GATO,
	frame = A,
	tics = 1,
	nextstate = S_GATOR_RECHARGE,
}

// Actual state maintained throughout the dash
states[S_GATOR_RECHARGE] = {
	sprite = SPR_GATO,
	frame = FF_ANIMATE|A,
	var1 = 5,
    var2 = 1,
	tics = 25,
	nextstate = S_GATOR_CHARGE
}

// Recovering from dash
states[S_GATOR_TIRED] = {
	sprite = SPR_GATO,
	frame = A,
	tics = 105,
	nextstate = S_GATOR_IDLE
}

// Our target is gone. Reset.
local function GatorReset(mo)
	mo.state = S_GATOR_IDLE
	mo.target = nil
	mo.charges = 2
end

addHook("MobjThinker", function(mo)
	if not mo.valid return end

	// The gator hasn't seen anyone yet, so surprise him when he does
	if mo.state ~= S_GATOR_LEER then mo.aha = false end

	// Gator is staring at a player. If the player gets closer, charge 'em. Otherwise go back to idling.
	if mo.state == S_GATOR_LEER
		mo.charges = 2 --Recharge our max number of charges in the staring phase

		if not mo.aha then
			local excla = P_SpawnMobjFromMobj(mo, 0, 0, mo.height+mo.height/3, MT_UNKNOWN)
			excla.frame = 3
			excla.sprite = SPR_WHAT
			excla.scale = 1
			excla.scalespeed = FRACUNIT/8
			excla.destscale = FRACUNIT
			excla.fuse = 20
			mo.aha = true
			S_StartSound(mo, sfx_s249)
		end
		// Must have been the wind...
		if not mo.target or not mo.target.valid 
        or R_PointToDist2(mo.x, mo.y, mo.target.x, mo.target.y) > (GATORRANGE + 50)*FRACUNIT
			mo.state = S_GATOR_IDLE
			mo.target = nil
			return
		end
		// Oh? You're approaching me?
		if R_PointToDist2(mo.x, mo.y, mo.target.x, mo.target.y) < GATORAGGRO * FRACUNIT then mo.state = S_GATOR_PREPCHARGE end
	end

	// A player got too close! Prepare the charge!
	if mo.state == S_GATOR_PREPCHARGE
		if not mo.target or not mo.target.valid then GatorReset(mo) return end

		// Keep facing our target and slowly back away for a windup effect
		mo.angle = R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y)
		P_TryMove(mo,
				  mo.x - 1 * cos(mo.angle), 
				  mo.y - 1 * sin(mo.angle),
				  false)
		// Spawn dust every other frame
		if not (leveltime%2)
			local dust = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SPINDUST)
			P_InstaThrust(dust, 
						  mo.angle + P_RandomRange(165, 195) * ANG1,
						  P_RandomRange(30, 45) * FRACUNIT)
			P_SetObjectMomZ(dust, P_RandomRange(1, 4) * FRACUNIT)
			S_StopSoundByID(mo, sfx_s3k47)
			S_StartSoundAtVolume(mo, sfx_s3k47, 150)
		end
	end

	// CHAAAARGE!
	if mo.state == S_GATOR_CHARGE
		if not mo.target or not mo.target.valid then GatorReset(mo) return end
		mo.charges = $-1
		local lookAt = R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y)
		mo.angle = lookAt
		P_InstaThrust(mo, lookAt, 50*FRACUNIT)
		S_StartSound(mo, sfx_cdfm35)

		if not mo.charges then mo.state = S_GATOR_TIRED end
	end

	// Visual effects for charging
	if mo.state == S_GATOR_RECHARGE and not (leveltime%4)
		P_SpawnGhostMobj(mo)
	end

end, MT_S2GATOR)