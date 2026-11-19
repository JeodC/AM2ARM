image_alpha = 0.5;
if (global.screwattack == 0) image_alpha = 0.3;
alarm[0] = 1;
fadeout = 0;
// Save this pose on its own surface so the afterimage can fade without changing with Samus.
trail_cache = oControl.effect_cache;
trail_generation = trail_cache.generation;
mysurf = -1;
// A lost source cannot supply a pose; never expose an old cached image.
if (surface_exists(oCharacter.surf)) {
    mysurf = effect_trail_acquire(trail_cache);
    if (surface_exists(mysurf)) surface_copy(mysurf, 0, 0, oCharacter.surf);
}

