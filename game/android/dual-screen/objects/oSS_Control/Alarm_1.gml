// Discard the fallback pause-map surface after a backgrounding check so the Step event can recreate it.
if (surface_exists(s_map)) surface_free(s_map);

