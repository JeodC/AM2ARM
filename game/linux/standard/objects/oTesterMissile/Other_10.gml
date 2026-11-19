// Contact with Samus or scenery creates the damaging blast; shooting the missile uses the other destruction event.
instance_create(x, y, oTesterMissileExpl);
instance_destroy();
sfx_stop(sndProjHit2);
sfx_play(sndProjHit2);

