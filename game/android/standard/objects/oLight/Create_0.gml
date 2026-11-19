fadeout = 0;


nano_dynamic_light = object_index == oFlashlight64
    || object_index == oFadeLight32 || object_index == oFadeLight64;
if (!nano_dynamic_light) nano_light_dirty();
