/// @description  enemy_death()
function enemy_death() {
	// Create the death effects in the defeated enemy's context, using its position and death sound.
	spawn_rnd_pickup(100);
	expl = instance_create(x, y, oFXAnimSpark);
	expl.image_speed = 0.5;
	expl.additive = 0;
	expl.sprite_index = sExpl1;
	PlaySoundMono(deathsound);
	// Remove the frozen collision platform if present, count the kill and destroy this enemy.
	if (instance_exists(platform)) with (platform) instance_destroy();
	global.kills += 1;


	instance_destroy();



}
