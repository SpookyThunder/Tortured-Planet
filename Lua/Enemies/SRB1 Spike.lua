
	-- SRB1 Spike enemy --

freeslot("MT_SRB1SPIK", "S_SRBSPIK_IDLE", "SPR_SRBL")

mobjinfo[MT_SRB1SPIK] = {
	doomednum = 4012,
	spawnstate = S_SRBSPIK_IDLE,
	radius = 16*FRACUNIT,
	height = 48*FRACUNIT,
	flags = MF_PAIN|MF_NOGRAVITY
}

states[S_SRBSPIK_IDLE] = {
	sprite = SPR_SRBL,
	frame = A,
	tics = -1
}

// Move up and down on a sine wave
addHook("MobjThinker", function(spike)
	spike.extravalue2 = (spike.flags2 & MF2_AMBUSH) and 4 or 2
	if not spike.extravalue1 then spike.extravalue1 = spike.z end
	spike.z = spike.extravalue1 + 70 * sin( FixedAngle( (leveltime%360) * FRACUNIT) * spike.extravalue2 ) + 70*FRACUNIT
end, MT_SRB1SPIK)