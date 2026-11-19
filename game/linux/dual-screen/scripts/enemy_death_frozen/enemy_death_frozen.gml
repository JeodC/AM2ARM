/// @description  enemy_death_frozen()
function enemy_death_frozen() {
	// Shatter the frozen enemy and remove the collision platform that made it standable.
	spawn_rnd_pickup(100);
	PlaySoundMono(sndIceShatter);
	if (instance_exists(platform)) with (platform) instance_destroy();
	repeat (8) deb = instance_create(x, y - 8, oIceShard);
	// Add bubbles when the frozen body breaks beneath the liquid surface.
	if (global.waterlevel != 0 && y + 8 > global.waterlevel + global.wateroffset) {
	    repeat (8 + floor(random(4))) {
	        bubble = instance_create(x, y, oLBubble);
	        if (instance_exists(bubble)) {
	            bubble.hspeed = random_range(-1.5, 1.5);
	            bubble.vspeed = -random(0.4);
	        }
	    }
	}

	instance_destroy();



}
