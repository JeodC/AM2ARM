with (myobj1) instance_destroy();
with (oTorizoCam) instance_destroy();
// Replace the fallen first form with the flying form and begin its arena changes.
tor = instance_create(x, y, oTorizo2);
tor.facing = facing;
mus_play(musTorizoB);
oMusicV2.bossbgm = musTorizoB;
instance_create(0, 0, oTorizoCeiling);
instance_destroy();

