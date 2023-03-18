
// Detonate on touch much sooner. Closer to 2.1 behavior.
addHook("TouchSpecial", function(special, toucher)
	P_DamageMobj(special, toucher, toucher)
end,  MT_BIGMINE)