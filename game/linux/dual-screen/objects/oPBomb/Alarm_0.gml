// Create the four parts of a normal Power Bomb blast, or start the Queen's final explosion.
if (special == 0) {
    instance_create(x, y, oPBombExpl);
    expl = instance_create(x, y, oPBombExpl);
    expl.image_angle = 90;
    expl = instance_create(x, y, oPBombExpl);
    expl.image_angle = 180;
    expl = instance_create(x, y, oPBombExpl);
    expl.image_angle = 270;
    sfx_play(sndPBombExpl);
} else instance_create(x, y, oQueenFinalExplosion);
instance_destroy();

