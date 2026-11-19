// Set world-map placement, liquid state, and the default footstep material.
global.mapoffsetx = 16;
global.mapoffsety = 3;
global.waterlevel = 0;
global.watertype = 0;
// Set the save-location key that set_start_location maps to a room and spawn position.
global.save_room = initroom;
global.floormaterial = 2;
// Choose the outdoor backgrounds and ship appearance for the saved time of day.
load_timeofday_bgs(global.timeofday);
// Before the hatchling event, select the main theme and remove its alternate scenery layer.
if (global.event[304] == 0) {
    oMusicV2.currentbgm = mus_get_main_song();
    tile_layer_delete(-119);
}
// After the hatchling event, schedule the translation notice through the log-state gate.
else { scan_log(44, get_text("Misc", "Translation"), 180, 1); }

//instance_create(2672, 368, oElderSeptogg);
instance_create(2176, 376, oElderSeptogg);

// Populate the additional outdoor Septoggs for the nighttime return.
if (global.timeofday == 2) {
    instance_create(3808, 1096, oElderSeptogg);
    instance_create(4354, 862, oElderSeptogg);
    instance_create(1776, 816, oElderSeptogg);
    instance_create(3056, 1040, oElderSeptogg);
    
    // instance_create(1740, 650, oElderSeptogg);
    instance_create(1700, 450, oElderSeptogg);
    instance_create(218, 168, oElderSeptogg);
    instance_create(192, 1075, oElderSeptogg);
    instance_create(736, 1046, oElderSeptogg);
    // instance_create(1088, 1077, oElderSeptogg);
    instance_create(1500, 1100, oElderSeptogg);
    instance_create(3001, 500, oElderSeptogg);
    // instance_create(3075, 650, oElderSeptogg);
    // instance_create(3020, 830, oElderSeptogg);
    // instance_create(3536, 1078, oElderSeptogg);
    instance_create(4280, 1050, oElderSeptogg);
}


//global.event[304] = 1; // for testing purposes