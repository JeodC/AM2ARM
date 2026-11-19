/// @description  create_gamma(x, y, id, facing)
function create_gamma(argument0, argument1, argument2, argument3) {
	// Create the Gamma with this encounter's ID, facing and combat parameters.
	met = instance_create(argument0, argument1, oMGamma);
	met.facing = argument3;
	met.myid = argument2;
	with (met) {
	    set_monster_vars(argument2);
	    // Attach its shell and finish the Gamma's setup through its user event.
	    shell = instance_create(x, y, oMAlphaShell);
	    shell.sprite_index = sMGammaShell;
	    shell.damage = damage;
	    shell.hpush = 5;
	    shell.vpush = -3;
	    event_user(3);
	}
	// Start the encounter music only for the first living Metroid, then count this one.
	if (global.monstersalive == 0) {
	    sfx_stop(sndMGammaIntro);
	    sfx_play(sndMGammaIntro);
	    mus_gamma_monster();
	}
	global.monstersalive += 1;



}
