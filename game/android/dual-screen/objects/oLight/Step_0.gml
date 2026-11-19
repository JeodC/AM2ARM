if (fadeout) {
    if (!nano_dynamic_light) nano_light_dirty();
    if (image_alpha > 0) {
        image_alpha -= 0.01;
    } else instance_destroy();
}

