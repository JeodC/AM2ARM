if(sprite_index == sLogFadeMarker){
    instance_destroy();
}

// Completing the loading animation records the log, then the marker fades away.
if(sprite_index == sLogLoadMarker){
    sprite_index = sLogFadeMarker;
    image_index  = 0;
    image_speed  = 0.5;
    if(lognum != -1 and trooperlognum == -1)      add_log(lognum);
    else if(lognum == -1 and trooperlognum != -1) add_trooper_log(trooperlognum);
}

