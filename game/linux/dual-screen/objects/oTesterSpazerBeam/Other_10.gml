expl = instance_create(x, y, oFXAnimSpark);
expl.sprite_index = sBeamExpl2;
expl.image_speed = 0.5;
expl.depth = -1000;
nano_impact_spark(expl);
instance_destroy();

