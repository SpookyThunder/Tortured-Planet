
	-- Remove emblems from 2.2 NiGHTS stages

addHook("MapLoad", function()
	if not (maptol & TOL_NIGHTS) return end
	for mo in mobjs.iterate()
		if mo.type == MT_EMBLEM then P_RemoveMobj(mo) end
	end
end)