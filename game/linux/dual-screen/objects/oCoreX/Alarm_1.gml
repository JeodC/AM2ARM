/// @description  Create shell.

// Wait one step so the defeated boss can supply the pose used for the shell transformation.
shell = instance_create(x, y, oCoreXShell);
shell.lastBossX = lastBossX;
shell.lastBossY = lastBossY;
shell.sprite_index = lastBossSprite;
shell.image_index = lastBossFrame;
shell.lastBossAngle = lastBossAngle;
shell.lastBossFacing = lastBossFacing;
shell.lastYscale = lastYscale;
shell.depth = lastBossDepth;

