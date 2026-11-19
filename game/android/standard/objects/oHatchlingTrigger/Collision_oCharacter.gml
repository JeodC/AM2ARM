// Stop Samus for the hatching scene and schedule the egg to break open.
with (oCharacter) {
    state = STANDING;
    facing = LEFT;        
}
scr_disableplayercontrol();
with (oMonsterEgg) {
    image_speed = 0.25;
    alarm[0] = 120;
}
instance_create(0,0, hatchling_freeze);
sfx_play(sndMEggCrackle);
instance_destroy();

