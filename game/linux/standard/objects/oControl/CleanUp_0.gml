if (variable_instance_exists(id, "effect_cache")) effect_cache_clear(effect_cache);
if (variable_instance_exists(id, "tempscr_buffer") && buffer_exists(tempscr_buffer)) {
    buffer_delete(tempscr_buffer);
    tempscr_buffer = -1;
}
