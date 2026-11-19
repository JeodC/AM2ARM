writelog("UnLoading Room " + string(room));
global.roomtime = 0;
fadedone = 0;


// Drop spare images at room boundaries; live trails keep their snapshots.
effect_cache_clear(effect_cache);
