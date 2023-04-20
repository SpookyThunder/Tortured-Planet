
	-- Delete goop balls after a little while, even if they never change state. Not sure why this isn't set by default...

addHook("MobjSpawn", function(mo)
	mo.fuse = 10*TICRATE
end, MT_GOOP)