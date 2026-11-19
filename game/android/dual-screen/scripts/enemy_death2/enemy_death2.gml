/// @description  enemy_death2()
function enemy_death2() {
	// Create the death effects in the defeated enemy's context, using its position and death sound.
	expl = instance_create(x, y, oFXAnimSpark);
	expl.image_speed = 0.5;
	expl.additive = 0;
	expl.sprite_index = sExpl1;
	repeat (5) {
	    expl = instance_create(x - 20 + random(40), y - 20 + random(40), oFXAnimSpark);
	    expl.image_speed = 0.4 + random(0.4);
	    expl.additive = 0;
	    expl.sprite_index = sExpl1;
	}
	// Roll a resource drop, remove any frozen platform and count the kill before destroying this enemy.
	spawn_rnd_pickup(100);
	PlaySoundMono(deathsound);
	if (instance_exists(platform)) with (platform) instance_destroy();
	global.kills += 1;

	instance_destroy();



}
