for (i = 0; i < images; i++) {
    draw_character_from_surface(sx[i], sy[i], image_blend, (1 - i * 0.11) * 0.4 * image_alpha);
}

