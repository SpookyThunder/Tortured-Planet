
// 2.0 Sea Egg - Ported from 2.0.7

freeslot(
	// Sprites come from LUA_EOCM
	// Object(s)
	"MT_20EGGMOBILE3"
	// States come from LUA_EOCM
)

// A_BossDeath portion ported from 2.1.25
function A_21BossDeath(actor)
	// Stop exploding and prepare to run.
	actor.state = actor.info.xdeathstate
	if not actor.valid
		return
	end
	
	actor.target = nil
	
	// Flee! Flee! Find a point to escape to! If none, just shoot upward!
	// scan the thinkers to find the runaway point
	for th in mobjs.iterate()
		if th.type == MT_BOSSFLYPOINT
			// If this one's closer then the last one, go for it
			if not actor.target or
				FixedHypot(FixedHypot(actor.x - th.x, actor.y - th.y), actor.z - th.z) <
				FixedHypot(FixedHypot(actor.x - actor.target.x, actor.y - actor.target.y), actor.z - actor.target.z)
					actor.target = th
			end
			// Otherwise... Don't!
		end
	end
	
	actor.flags = $|MF_NOGRAVITY|MF_NOCLIP
	actor.flags = $|MF_NOCLIPHEIGHT
	
	if actor.target
		actor.angle = R_PointToAngle2(actor.x, actor.y, actor.target.x, actor.target.y)
		actor.flags2 = $|MF2_BOSSFLEE
		actor.momz = FixedMul(FixedDiv(actor.target.z - actor.z, FixedHypot(actor.x-actor.target.x,actor.y-actor.target.y)), FixedMul(2*FRACUNIT, actor.scale))
	else
		actor.momz = FixedMul(2*FRACUNIT, actor.scale)
	end
end

// Changes the Sea Egg's movefactor to that of the 2.0 default, allowing its 
// boss thinker to run properly
addHook("MobjSpawn", function(mobj)
	mobj.movefactor = 8*(2^8) // Replacement for ORIG_FRICTION_FACTOR;
end, MT_20EGGMOBILE3)

// Ported BossThinker behavior for 2.0 Sea Egg from 2.0.7
addHook("BossThinker", function(mobj)
	if mobj.state == mobj.info.spawnstate
		mobj.flags2 = $ & ~MF2_FRET
		//mobj.flags = $ & ~MF_TRANSLATION
	end
	
	if (mobj.flags2 & MF2_FRET)
		mobj.movedir = 1
		if mobj.health <= mobj.info.damage // This should be 2
			P_LinedefExecute(65534)
		end
	end
	
	if mobj.movefactor > 8*(2^8)
		mobj.movefactor = $-1
		return true
	end
	
	if mobj.health <= 0
		mobj.movecount = 0
		mobj.reactiontime = 0
		
		if mobj.state < mobj.info.xdeathstate
			return true
		end
		
		if mobj.threshold == -1
			mobj.momz = mobj.info.speed
			return true
		end
	end
	
	if mobj.reactiontime and mobj.health > mobj.info.damage // Shock mode
		if mobj.state != mobj.info.spawnstate
			mobj.state = mobj.info.spawnstate
		end
		
		if leveltime % 2*TICRATE == 0
			// Shock the water
			for player in players.iterate do
				if not player.valid or player.spectator
					continue
				end
				
				if not player.mo
					continue
				end
				
				if player.mo.health <= 0
					continue
				end
				
				if (player.mo.eflags & MFE_UNDERWATER)
					P_DamageMobj(player.mo, mobj, mobj, 1)
				end
			end
			
			// Make the water flash
			for sector in sectors.iterate do
				if not sector.ffloors()
					continue
				end
				
				for rover in sector.ffloors() do
					if not (rover.flags & FF_EXISTS)
						continue
					end
					
					if not (rover.flags & FF_SWIMMABLE)
						continue
					end
					
					P_SpawnLightningFlash(rover.master.frontsector)
					break
				end
			end
			
			if leveltime % 35 == 0
				S_StartSound(nil, sfx_buzz1)
			end
		end
		
		// If in the center, check to make sure
		// none of the players are in the water
		for player in players.iterate
			if not player.valid or player.spectator
				continue
			end
			
			if not player.mo or player.bot
				continue
			end
			
			if player.mo.health <= 0
				continue
			end
			
			if (player.mo.eflags & MFE_UNDERWATER)
				return true // Stay put
			end
		end
		
		mobj.reactiontime = 0
	elseif mobj.movecount // Firing mode
		// Look for a new target
		P_LookForPlayers(mobj, 0, true)
		
		if not mobj.target or not mobj.target.player
			return true
		end
		
		// Are there any players underwater? If so, shock them!
		for player in players.iterate
			if not player.valid or player.spectator
				continue
			end
			
			if not player.mo or player.bot
				continue
			end
			
			if player.mo.health <= 0
				continue
			end
			
			if (player.mo.eflags & MFE_UNDERWATER)
				mobj.movecount = 0
				mobj.state = mobj.info.spawnstate
				break
			end
		end
		
		// Always face your target.
		A_FaceTarget(mobj)
		
		// Check if the attack animation is running. If not, play it.
		if mobj.state < mobj.info.missilestate or mobj.state > mobj.info.raisestate
			mobj.state = mobj.info.missilestate
		end
	elseif mobj.threshold >= 0 // Traveling mode
		local dist, dist2
		local speed
		
		mobj.target = nil
		
		if mobj.state != mobj.info.spawnstate and mobj.health > 0
			and not (mobj.flags2 & MF2_FRET)
			mobj.state = mobj.info.spawnstate
		end
		
		// scan the thinkers
		// to find a point that matches
		// the number
		for mo2 in mobjs.iterate()
			if mo2.type == MT_BOSS3WAYPOINT and mo2.spawnpoint and mo2.spawnpoint.angle == mobj.threshold
				mobj.target = mo2
				break
			end
		end
		
		if not mobj.target // Should NEVER happen
			print("Error: Boss 3 was unable to find specified waypoint: %d", mobj.threshold)
			return true
		end
		
		dist = FixedHypot(FixedHypot(mobj.target.x - mobj.x, mobj.target.y - mobj.y), mobj.target.z - mobj.z)
		
		if dist < 1
			dist = 1
		end
		
		if mobj.movedir or mobj.health <= mobj.info.damage
			speed = mobj.info.speed * 2
		else
			speed = mobj.info.speed
		end
		
		mobj.momx = FixedMul(FixedDiv(mobj.target.x - mobj.x, dist), speed)
		mobj.momy = FixedMul(FixedDiv(mobj.target.y - mobj.y, dist), speed)
		mobj.momz = FixedMul(FixedDiv(mobj.target.z - mobj.z, dist), speed)
		
		// If this causes severe multiplayer issues, this might need to be replaced --MIDIMan
		mobj.angle = R_PointToAngle(mobj.momx, mobj.momy)
		
		dist2 = FixedHypot(FixedHypot(mobj.target.x - (mobj.x + mobj.momx), mobj.target.y - (mobj.y + mobj.momy)), mobj.target.z - (mobj.z + mobj.momz))
		
		if dist2 < 1
			dist2 = 1
		end
		
		if dist / (2^FRACBITS) <= dist2 / (2^FRACBITS)
			P_TeleportMove(mobj, mobj.target.x, mobj.target.y, mobj.target.z)
			mobj.momx = 0
			mobj.momy = 0
			mobj.momz = 0
			
			if mobj.threshold == 0
				mobj.reactiontime = 1 // Bzzt! Shock the water!
				mobj.movedir = 0
				
				if mobj.health <= 0
					mobj.flags = $|MF_NOGRAVITY|MF_NOCLIP
					mobj.flags = $|MF_NOCLIPHEIGHT
					mobj.threshold = -1
					return true
				end
			end
			
			// Set to next waypoint in sequence
			if mobj.target.spawnpoint
				if mobj.target.spawnpoint.angle == 0
					mobj.threshold = (P_RandomByte()%5) + 1
				else
					mobj.threshold = mobj.target.spawnpoint.extrainfo
				end
				
				// If the deaf flag is set, go into firing mode
				if (mobj.target.spawnpoint.options & MTF_AMBUSH)
					if mobj.health <= mobj.info.damage
						mobj.movefactor = (8*(2^8)) + 5*TICRATE
					else
						mobj.movecount = 1
					end
				end
			else // This should never happen, as well
				print("Error: Boss 3 waypoint has no spawnpoint associated with it.")
			end
		end
	end
	
	return true
end, MT_20EGGMOBILE3)

addHook("BossDeath", function(mo)
	A_21BossDeath(mo)
	return true
end, MT_20EGGMOBILE3)

mobjinfo[MT_20EGGMOBILE3] = {
	//$Name 2.0 Sea Egg
	//$Sprite EGGOA1
	//$Category Bosses
	doomednum = 230,
	spawnstate = S_21EGGMOBILE3_STND,
	spawnhealth = 8,
	seestate = S_21EGGMOBILE3_STND,
	painstate = S_21EGGMOBILE3_PAIN,
	painsound = sfx_dmpain,
	meleestate = S_21EGGMOBILE3_STND,
	missilestate = S_21EGGMOBILE3_ATK1,
	deathstate = S_21EGGMOBILE3_DIE1,
	xdeathstate = S_21EGGMOBILE3_FLEE1,
	deathsound = sfx_cybdth,
	speed = 8*FRACUNIT,
	radius = 32*FRACUNIT,
	height = 80*FRACUNIT,
	damage = 2,
	activesound = sfx_telept,
	flags = MF_SPECIAL|MF_SHOOTABLE|MF_NOGRAVITY|MF_BOSS,
	raisestate = S_21EGGMOBILE3_LAUGH20
}
